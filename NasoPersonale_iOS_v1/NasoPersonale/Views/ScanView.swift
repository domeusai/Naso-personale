import SwiftUI
import UIKit

struct ScanView: View {
    @EnvironmentObject private var store: PerfumeStore
    @State private var showCamera = false
    @State private var image: UIImage?
    @State private var recognizedLines: [String] = []
    @State private var proposedBrand = ""
    @State private var proposedName = ""
    @State private var scanning = false
    @State private var scanMessage: String?
    @State private var showingEditor = false

    private var canUseCamera: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 7) {
                        Text("Dall’etichetta alla collezione")
                            .font(.system(size: 27, weight: .medium, design: .serif))
                            .foregroundStyle(NasoPalette.ink)
                        Text("Fotografa il flacone: il testo viene letto sul dispositivo.")
                            .font(.system(size: 14))
                            .foregroundStyle(NasoPalette.muted)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(NasoPalette.sand)
                            .frame(maxWidth: .infinity)
                            .frame(height: 330)
                        if let image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: 330)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 54, weight: .light))
                                .foregroundStyle(NasoPalette.forest)
                        }
                    }

                    Button {
                        showCamera = true
                    } label: {
                        Label(canUseCamera ? "Scatta etichetta" : "Scegli una foto", systemImage: canUseCamera ? "camera" : "photo")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 15)
                            .background(NasoPalette.forest)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }

                    if scanning {
                        HStack(spacing: 10) {
                            ProgressView().tint(NasoPalette.forest)
                            Text("Lettura dell’etichetta…")
                        }
                        .foregroundStyle(NasoPalette.muted)
                    }

                    if !recognizedLines.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("PROPOSTA OCR")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .tracking(1.2)
                                .foregroundStyle(NasoPalette.gold)
                            TextField("Marca", text: $proposedBrand)
                                .textFieldStyle(.roundedBorder)
                            TextField("Nome del profumo", text: $proposedName)
                                .textFieldStyle(.roundedBorder)
                            Button {
                                showingEditor = true
                            } label: {
                                Label("Completa la scheda", systemImage: "square.and.pencil")
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .background(NasoPalette.gold)
                                    .foregroundStyle(.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            Text("Testo rilevato: \(recognizedLines.joined(separator: " · "))")
                                .font(.system(size: 12))
                                .foregroundStyle(NasoPalette.muted)
                        }
                    }

                    if image != nil && recognizedLines.isEmpty && !scanning {
                        Button("Inserisci i dati manualmente") {
                            showingEditor = true
                        }
                        .font(.system(size: 14, weight: .medium))
                    }

                    if let scanMessage {
                        Text(scanMessage)
                            .font(.system(size: 13))
                            .foregroundStyle(NasoPalette.muted)
                    }
                }
                .padding(20)
            }
            .background(NasoPalette.paper)
            .navigationTitle("Scansiona")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCamera) {
                CameraPicker(image: $image)
            }
            .sheet(isPresented: $showingEditor) {
                PerfumeEditorView(
                    perfume: nil,
                    brand: proposedBrand,
                    name: proposedName,
                    image: image?.jpegData(compressionQuality: 0.85)
                ) { store.add($0) }
            }
            .onChange(of: image) { _, newImage in
                guard let newImage else { return }
                recognizedLines = []
                scanMessage = nil
                scanning = true
                Task {
                    let lines = await Task.detached(priority: .userInitiated) {
                        (try? VisionOCR.recognizeText(in: newImage)) ?? []
                    }.value
                    recognizedLines = lines
                    proposedBrand = lines.first ?? ""
                    proposedName = lines.dropFirst().joined(separator: " ")
                    scanMessage = lines.isEmpty ? "Non è stato trovato testo leggibile." : nil
                    scanning = false
                }
            }
        }
        .tint(NasoPalette.forest)
    }
}

struct CameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraPicker

        init(parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
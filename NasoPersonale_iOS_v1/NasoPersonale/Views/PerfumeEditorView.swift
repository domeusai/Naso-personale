import PhotosUI
import SwiftUI

struct PerfumeEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: Perfume
    @State private var selectedPhoto: PhotosPickerItem?
    private let onSave: (Perfume) -> Void
    private let isNew: Bool

    private let families = ["Agrumata", "Aromatica", "Chypre", "Floreale", "Fougère", "Legnosa", "Orientale", "Oud", "Cuoiata", "Acquatica", "Gourmand"]
    private let seasons = ["Primavera", "Estate", "Autunno", "Inverno"]
    private let occasions = ["Lavoro", "Tempo libero", "Serata", "Cerimonia", "Sport", "Viaggio"]

    init(perfume: Perfume?, brand: String = "", name: String = "", image: Data? = nil, onSave: @escaping (Perfume) -> Void) {
        var value = perfume ?? Perfume(brand: brand, name: name)
        if let image, value.imageData == nil { value.imageData = image }
        _draft = State(initialValue: value)
        self.onSave = onSave
        isNew = perfume == nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        PerfumeArtwork(imageData: draft.imageData, size: 92)
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            Label("Scegli una foto", systemImage: "photo")
                        }
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(NasoPalette.paper)
                }

                Section("Identità") {
                    TextField("Marca", text: $draft.brand)
                        .textInputAutocapitalization(.words)
                    TextField("Nome del profumo", text: $draft.name)
                        .textInputAutocapitalization(.words)
                    Picker("Famiglia olfattiva", selection: $draft.family) {
                        Text("Non specificata").tag("")
                        ForEach(families, id: \.self) { Text($0).tag($0) }
                    }
                    TextField("Accordi, separati da virgole", text: stringListBinding(\.accords))
                }

                Section("Piramide olfattiva") {
                    TextField("Note di testa", text: $draft.topNotes, axis: .vertical)
                    TextField("Note di cuore", text: $draft.heartNotes, axis: .vertical)
                    TextField("Note di fondo", text: $draft.baseNotes, axis: .vertical)
                }

                Section("Carattere") {
                    RatingScale(title: "Durata", value: $draft.longevity)
                    RatingScale(title: "Scia", value: $draft.sillage)
                    selectionRow("Stagioni", options: seasons, selection: $draft.seasons)
                    selectionRow("Occasioni", options: occasions, selection: $draft.occasions)
                    Toggle("Da giorno", isOn: $draft.dayUse).tint(NasoPalette.forest)
                    Toggle("Da sera", isOn: $draft.eveningUse).tint(NasoPalette.forest)
                }

                Section("Personale") {
                    TextField("Le tue note", text: $draft.personalNotes, axis: .vertical)
                        .lineLimit(3...8)
                    Toggle("Da ricomprare", isOn: $draft.repurchase).tint(NasoPalette.forest)
                    Toggle("Preferito", isOn: $draft.isFavorite).tint(NasoPalette.forest)
                }
            }
            .scrollContentBackground(.hidden)
            .background(NasoPalette.paper)
            .navigationTitle(isNew ? "Nuovo profumo" : "Modifica profumo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annulla") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") {
                        draft.brand = draft.brand.trimmingCharacters(in: .whitespacesAndNewlines)
                        draft.name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(draft.brand.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .task(id: selectedPhoto) {
                guard let selectedPhoto,
                      let data = try? await selectedPhoto.loadTransferable(type: Data.self),
                      UIImage(data: data) != nil else { return }
                draft.imageData = data
            }
        }
        .tint(NasoPalette.forest)
    }

    private func stringListBinding(_ keyPath: WritableKeyPath<Perfume, [String]>) -> Binding<String> {
        Binding(
            get: { draft[keyPath: keyPath].joined(separator: ", ") },
            set: { draft[keyPath: keyPath] = $0.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty } }
        )
    }

    private func selectionRow(_ title: String, options: [String], selection: Binding<[String]>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
            FlowSelection(options: options, selection: selection)
        }
        .padding(.vertical, 4)
    }
}

private struct FlowSelection: View {
    let options: [String]
    @Binding var selection: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), alignment: .leading)], alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let selected = selection.contains(option)
                Button {
                    if selected { selection.removeAll { $0 == option } }
                    else { selection.append(option) }
                } label: {
                    Label(option, systemImage: selected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 13))
                        .foregroundStyle(selected ? NasoPalette.forest : NasoPalette.muted)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
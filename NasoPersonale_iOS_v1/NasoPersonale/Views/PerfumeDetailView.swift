import SwiftUI

struct PerfumeDetailView: View {
    @EnvironmentObject private var store: PerfumeStore
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditor = false
    @State private var confirmingDelete = false

    let perfume: Perfume

    private var current: Perfume {
        store.perfumes.first(where: { $0.id == perfume.id }) ?? perfume
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .top, spacing: 18) {
                    PerfumeArtwork(imageData: current.imageData, size: 118)
                    VStack(alignment: .leading, spacing: 7) {
                        Text(current.brand.uppercased())
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(NasoPalette.gold)
                        Text(current.name)
                            .font(.system(size: 28, weight: .medium, design: .serif))
                            .foregroundStyle(NasoPalette.ink)
                        if !current.family.isEmpty {
                            Text(current.family).foregroundStyle(NasoPalette.muted)
                        }
                    }
                    Spacer(minLength: 0)
                }

                if !current.accords.isEmpty { tagSection("Accordi", values: current.accords) }
                VStack(alignment: .leading, spacing: 14) {
                    Text("PIRAMIDE OLFATTIVA").sectionEyebrow()
                    noteRow("Testa", current.topNotes)
                    noteRow("Cuore", current.heartNotes)
                    noteRow("Fondo", current.baseNotes)
                }
                VStack(alignment: .leading, spacing: 12) {
                    Text("CARATTERE").sectionEyebrow()
                    ratingRow("Durata", value: current.longevity)
                    ratingRow("Scia", value: current.sillage)
                }
                if !current.seasons.isEmpty { tagSection("Stagioni", values: current.seasons) }
                if !current.occasions.isEmpty { tagSection("Occasioni", values: current.occasions) }
                HStack(spacing: 16) {
                    Label("Giorno", systemImage: "sun.max")
                        .opacity(current.dayUse ? 1 : 0.35)
                    Label("Sera", systemImage: "moon")
                        .opacity(current.eveningUse ? 1 : 0.35)
                }
                .font(.system(size: 14, weight: .medium))
                if !current.personalNotes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NOTE PERSONALI").sectionEyebrow()
                        Text(current.personalNotes).foregroundStyle(NasoPalette.ink)
                    }
                }
                if current.repurchase {
                    Label("Da ricomprare", systemImage: "cart")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(NasoPalette.forest)
                }
            }
            .padding(22)
        }
        .background(NasoPalette.paper)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    var updated = current
                    updated.isFavorite.toggle()
                    store.update(updated)
                } label: {
                    Image(systemName: current.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(current.isFavorite ? NasoPalette.gold : NasoPalette.forest)
                }
                .accessibilityLabel(current.isFavorite ? "Rimuovi dai preferiti" : "Aggiungi ai preferiti")
                Menu {
                    Button("Modifica", systemImage: "pencil") { showingEditor = true }
                    Button("Elimina", systemImage: "trash", role: .destructive) { confirmingDelete = true }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            PerfumeEditorView(perfume: current) { store.update($0) }
        }
        .confirmationDialog("Eliminare \(current.name)?", isPresented: $confirmingDelete, titleVisibility: .visible) {
            Button("Elimina profumo", role: .destructive) {
                store.delete(current)
                dismiss()
            }
        } message: {
            Text("Questa operazione non può essere annullata.")
        }
    }

    private func tagSection(_ title: String, values: [String]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(title.uppercased()).sectionEyebrow()
            FlowLayoutTags(values: values)
        }
    }

    private func noteRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(title).font(.system(size: 13, weight: .semibold)).frame(width: 56, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(.system(size: 14))
                .foregroundStyle(value.isEmpty ? NasoPalette.muted : NasoPalette.ink)
        }
    }

    private func ratingRow(_ title: String, value: Int) -> some View {
        HStack {
            Text(title).font(.system(size: 14))
            Spacer()
            HStack(spacing: 3) {
                ForEach(1...10, id: \.self) { index in
                    Capsule().fill(index <= value ? NasoPalette.gold : NasoPalette.sand)
                        .frame(width: 11, height: 5)
                }
            }
            Text("\(value)/10").font(.system(size: 12, design: .rounded)).foregroundStyle(NasoPalette.muted)
        }
    }
}

private struct FlowLayoutTags: View {
    let values: [String]

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 84), alignment: .leading)], alignment: .leading, spacing: 7) {
            ForEach(values, id: \.self) { value in
                Text(value)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(NasoPalette.sand)
                    .clipShape(Capsule())
            }
        }
    }
}

private extension View {
    func sectionEyebrow() -> some View {
        font(.system(size: 10, weight: .bold, design: .rounded))
            .tracking(1.2)
            .foregroundStyle(NasoPalette.gold)
    }
}
import SwiftUI

struct CollectionView: View {
    @EnvironmentObject var store: PerfumeStore
    @State private var searchText = ""
    @State private var brandFilter = ""
    @State private var showingEditor = false

    private var brands: [String] {
        Array(Set(store.perfumes.map { $0.brand }))
            .filter { !$0.isEmpty }
            .sorted()
    }

    private var filteredPerfumes: [Perfume] {
        store.perfumes.filter { perfume in
            let matchesSearch =
                searchText.isEmpty ||
                perfume.name.localizedCaseInsensitiveContains(searchText) ||
                perfume.brand.localizedCaseInsensitiveContains(searchText)

            let matchesBrand =
                brandFilter.isEmpty ||
                perfume.brand.localizedCaseInsensitiveContains(brandFilter)

            return matchesSearch && matchesBrand
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredPerfumes.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty && brandFilter.isEmpty ? "La collezione è vuota" : "Nessun risultato",
                        systemImage: "drop",
                        description: Text(searchText.isEmpty && brandFilter.isEmpty
                                          ? "Aggiungi il tuo primo profumo con il pulsante +."
                                          : "Prova a modificare la ricerca o il filtro marca.")
                    )
                } else {
                    List(filteredPerfumes) { perfume in
                        NavigationLink(value: perfume) {
                            PerfumeRow(perfume: perfume)
                        }
                        .listRowBackground(NasoPalette.paper)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(NasoPalette.paper)
                }
            }
            .background(NasoPalette.paper)
            .navigationTitle("Naso Personale")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Cerca nome o marca")
            .navigationDestination(for: Perfume.self) { perfume in
                PerfumeDetailView(perfume: perfume)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Aggiungi profumo")
                }
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                if !brands.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            BrandFilterButton(title: "Tutte", selected: brandFilter.isEmpty) {
                                brandFilter = ""
                            }
                            ForEach(brands, id: \.self) { brand in
                                BrandFilterButton(title: brand, selected: brandFilter == brand) {
                                    brandFilter = brand
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                    }
                    .background(NasoPalette.paper)
                }
            }
            .sheet(isPresented: $showingEditor) {
                PerfumeEditorView(perfume: nil) { store.add($0) }
            }
        }
        .tint(NasoPalette.forest)
    }
}

struct PerfumeRow: View {
    let perfume: Perfume

    var body: some View {
        HStack(spacing: 14) {
            PerfumeArtwork(imageData: perfume.imageData, size: 66)
            VStack(alignment: .leading, spacing: 4) {
                Text(perfume.brand.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(NasoPalette.forest.opacity(0.75))
                Text(perfume.name)
                    .font(.system(size: 18, weight: .semibold, design: .serif))
                    .foregroundStyle(NasoPalette.ink)
                if !perfume.family.isEmpty {
                    Text(perfume.family)
                        .font(.system(size: 13))
                        .foregroundStyle(NasoPalette.muted)
                }
            }
            Spacer(minLength: 0)
            if perfume.isFavorite {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(NasoPalette.gold)
            }
        }
        .padding(.vertical, 5)
        .contentShape(Rectangle())
    }
}

private struct BrandFilterButton: View {
    let title: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(title, action: action)
            .font(.system(size: 13, weight: .medium))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(selected ? NasoPalette.forest : NasoPalette.sand)
            .foregroundStyle(selected ? .white : NasoPalette.ink)
            .clipShape(Capsule())
    }
}

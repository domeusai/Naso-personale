import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var store: PerfumeStore

    private var favorites: [Perfume] {
        store.perfumes.filter(\.isFavorite)
    }

    var body: some View {
        NavigationStack {
            Group {
                if favorites.isEmpty {
                    ContentUnavailableView(
                        "Ancora nessun preferito",
                        systemImage: "heart",
                        description: Text("Segna con il cuore i profumi che vuoi ritrovare qui.")
                    )
                } else {
                    List(favorites) { perfume in
                        NavigationLink(value: perfume) {
                            PerfumeRow(perfume: perfume)
                        }
                        .listRowBackground(NasoPalette.paper)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(NasoPalette.paper)
            .navigationTitle("Preferiti")
            .navigationDestination(for: Perfume.self) { perfume in
                PerfumeDetailView(perfume: perfume)
            }
        }
        .tint(NasoPalette.forest)
    }
}
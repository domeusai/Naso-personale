import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            CollectionView()
                .tabItem {
                    Label("Collezione", systemImage: "square.grid.2x2.fill")
                }

            ScanView()
                .tabItem {
                    Label("Scansiona", systemImage: "camera.fill")
                }

            FavoritesView()
                .tabItem {
                    Label("Preferiti", systemImage: "heart.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Impostazioni", systemImage: "gearshape.fill")
                }
        }
        .tint(NasoPalette.forest)
        .background(NasoPalette.paper)
    }
}

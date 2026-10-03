import SwiftUI

@main
struct NasoPersonaleApp: App {
    @StateObject private var store = PerfumeStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
        }
    }
}

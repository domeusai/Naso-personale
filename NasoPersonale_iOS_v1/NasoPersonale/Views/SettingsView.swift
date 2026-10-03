import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Privacy") {
                    Label(
                        "Dati salvati solo sul dispositivo",
                        systemImage: "lock.fill"
                    )

                    Label(
                        "Funziona senza connessione",
                        systemImage: "wifi.slash"
                    )
                }

                Section("Naso Personale") {
                    Label(
                        "La tua collezione privata",
                        systemImage: "person.crop.circle.badge.checkmark"
                    )

                    Label(
                        "OCR eseguito con Apple Vision",
                        systemImage: "magnifyingglass"
                    )
                }
            }
            .navigationTitle("Impostazioni")
        }
    }
}

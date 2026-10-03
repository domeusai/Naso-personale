import Foundation
import SwiftUI

final class PerfumeStore: ObservableObject {
    @Published var perfumes: [Perfume] = [] {
        didSet {
            save()
        }
    }

    private let saveURL: URL

    init() {
        let folder = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        saveURL = folder.appendingPathComponent(
            "naso_personale_collection.json"
        )

        load()
    }

    func add(_ perfume: Perfume) {
        perfumes.append(perfume)
    }

    func update(_ perfume: Perfume) {
        guard let index = perfumes.firstIndex(
            where: { $0.id == perfume.id }
        ) else {
            return
        }

        perfumes[index] = perfume
    }

    func delete(_ perfume: Perfume) {
        perfumes.removeAll {
            $0.id == perfume.id
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(perfumes)
            try data.write(
                to: saveURL,
                options: .atomic
            )
        } catch {
            print("Errore salvataggio:", error.localizedDescription)
        }
    }

    private func load() {
        guard let data = try? Data(
            contentsOf: saveURL
        ) else {
            return
        }

        perfumes =
            (try? JSONDecoder().decode(
                [Perfume].self,
                from: data
            )) ?? []
    }
}

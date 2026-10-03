import Foundation

struct Perfume: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var brand: String
    var name: String
    var family: String = ""
    var accords: [String] = []
    var topNotes: String = ""
    var heartNotes: String = ""
    var baseNotes: String = ""
    var longevity: Int = 5
    var sillage: Int = 5
    var seasons: [String] = []
    var occasions: [String] = []
    var dayUse: Bool = true
    var eveningUse: Bool = false
    var personalNotes: String = ""
    var isFavorite: Bool = false
    var repurchase: Bool = false
    var imageData: Data? = nil
}

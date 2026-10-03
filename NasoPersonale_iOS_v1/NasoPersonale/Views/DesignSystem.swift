import SwiftUI

enum NasoPalette {
    static let paper = Color(red: 0.97, green: 0.95, blue: 0.89)
    static let sand = Color(red: 0.91, green: 0.88, blue: 0.80)
    static let forest = Color(red: 0.10, green: 0.27, blue: 0.21)
    static let gold = Color(red: 0.68, green: 0.51, blue: 0.24)
    static let ink = Color(red: 0.16, green: 0.18, blue: 0.15)
    static let muted = Color(red: 0.43, green: 0.44, blue: 0.39)
}

struct PerfumeArtwork: View {
    let imageData: Data?
    var size: CGFloat = 90

    var body: some View {
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    NasoPalette.sand
                    Image(systemName: "drop.fill")
                        .font(.system(size: size * 0.32))
                        .foregroundStyle(NasoPalette.gold)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct RatingScale: View {
    let title: String
    @Binding var value: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value)/10")
                    .foregroundStyle(NasoPalette.muted)
            }
            Slider(value: Binding(
                get: { Double(value) },
                set: { value = Int($0.rounded()) }
            ), in: 1...10, step: 1)
            .tint(NasoPalette.forest)
        }
    }
}
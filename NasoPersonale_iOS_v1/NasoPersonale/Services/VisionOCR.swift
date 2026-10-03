import UIKit
import Vision

enum VisionOCR {
    static func recognizeText(in image: UIImage) throws -> [String] {
        guard let cgImage = image.cgImage else { return [] }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true

        try VNImageRequestHandler(cgImage: cgImage).perform([request])
        return (request.results ?? []).compactMap { observation in
            observation.topCandidates(1).first?.string
        }
    }
}
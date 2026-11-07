import Foundation
import UIKit
import Vision

enum OCRFailure: Error {
    case invalidImage
}

struct ImageTextReader {
    func recognize(data: Data) async throws -> String {
        guard let image = UIImage(data: data), let cgImage = image.cgImage else {
            throw OCRFailure.invalidImage
        }
        return try await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try handler.perform([request])
            return (request.results ?? []).compactMap {
                $0.topCandidates(1).first?.string
            }.joined(separator: "\n")
        }.value
    }
}

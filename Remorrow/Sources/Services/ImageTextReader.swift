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
            // Vision's observation order can vary. Use a stable top-to-bottom,
            // then left-to-right reading order for chat screenshots.
            let observations = (request.results ?? []).sorted {
                let delta = $0.boundingBox.midY - $1.boundingBox.midY
                return abs(delta) > 0.025
                    ? delta > 0
                    : $0.boundingBox.minX < $1.boundingBox.minX
            }
            var lines: [String] = []
            var previousY: CGFloat?
            for item in observations {
                guard let text = item.topCandidates(1).first?.string,
                      !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
                if let previousY, previousY - item.boundingBox.midY > 0.07 {
                    lines.append("") // Distinct visual bubble/paragraph separation.
                }
                lines.append(text)
                previousY = item.boundingBox.midY
            }
            return lines.joined(separator: "\n")
        }.value
    }
}

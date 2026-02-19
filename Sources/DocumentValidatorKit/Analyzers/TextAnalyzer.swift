// TextAnalyzer.swift — DocumentValidatorKit
// OCR-based text recognition and density measurement.

import Vision
import UIKit

enum TextAnalyzer {

    struct OCRResult: Sendable {
        let lines: [String]
        let density: Double      // 0–1 normalized
        let joinedText: String   // uppercased, for keyword matching
    }

    /// Runs OCR and returns recognized lines + density score.
    static func analyze(
        image: UIImage,
        level: ValidationOptions.OCRLevel = .accurate
    ) async throws -> OCRResult {
        try await VisionRequestRunner.run(
            on: image,
            configure: { request in
                guard let req = request as? VNRecognizeTextRequest else { return }
                req.recognitionLevel = level.vnLevel
                req.usesLanguageCorrection = true
            },
            makeRequest: { handler in
                VNRecognizeTextRequest(completionHandler: handler)
            },
            transform: { results in
                let obs = results as? [VNRecognizedTextObservation] ?? []
                let lines = obs.compactMap { $0.topCandidates(1).first?.string }
                let density = min(Double(obs.count) / 40.0, 1.0)
                let joined = lines.joined(separator: " ").uppercased()
                return OCRResult(lines: lines, density: density, joinedText: joined)
            },
            fallback: OCRResult(lines: [], density: 0, joinedText: "")
        )
    }
}

// MARK: - Helper

extension ValidationOptions.OCRLevel {
    var vnLevel: VNRequestTextRecognitionLevel {
        switch self {
        case .fast:     return .fast
        case .accurate: return .accurate
        }
    }
}

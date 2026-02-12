import Vision
import UIKit

enum TextAnalyzer {
    
    static func textDensity(in image: UIImage) async throws -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let request = VNRecognizeTextRequest { req, err in
                let observations = req.results as? [VNRecognizedTextObservation] ?? []
                let density = min(Double(observations.count) / 40.0, 1.0)
                continuation.resume(returning: density)
            }
            
            request.recognitionLevel = .fast
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}

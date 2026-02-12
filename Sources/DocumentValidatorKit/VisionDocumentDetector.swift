import Vision
import UIKit

enum VisionDocumentDetector {
    
    static func containsDocument(_ image: UIImage) async throws -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let request = VNDetectRectanglesRequest { req, err in
                if let rects = req.results as? [VNRectangleObservation],
                   let best = rects.first {
                    continuation.resume(returning: Double(best.confidence))
                } else {
                    continuation.resume(returning: 0)
                }
            }
            
            request.minimumAspectRatio = 0.5
            request.maximumAspectRatio = 1.8
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}

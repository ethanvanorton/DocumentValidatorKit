import Vision
import UIKit

enum FaceDetector {
    
    static func facePresence(in image: UIImage) async throws -> Double {
        guard let cgImage = image.cgImage else { return 0 }
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let request = VNDetectFaceRectanglesRequest { req, err in
                let faces = req.results as? [VNFaceObservation] ?? []
                continuation.resume(returning: faces.isEmpty ? 0 : 1)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}

import UIKit
import CoreML
import Vision

@MainActor
enum MLDocumentClassifier {
    
    private static let model: VNCoreMLModel = {
        let config = MLModelConfiguration()
        config.computeUnits = .all
        
        let coreMLModel = try! DocumentClassifier(configuration: config).model
        return try! VNCoreMLModel(for: coreMLModel)
    }()
    
    static func predict(_ image: UIImage) async throws -> (DocumentType, Double) {
        guard let cgImage = image.cgImage else {
            return (.unknown, 0)
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            
            let request = VNCoreMLRequest(model: model) { request, error in
                
                guard let results = request.results as? [VNClassificationObservation],
                      let best = results.first else {
                    continuation.resume(returning: (.unknown, 0))
                    return
                }
                
                let label = DocumentType(rawValue: best.identifier) ?? .unknown
                continuation.resume(returning: (label, Double(best.confidence)))
            }
            
            request.imageCropAndScaleOption = .centerCrop
            
            let handler = VNImageRequestHandler(cgImage: cgImage)
            try? handler.perform([request])
        }
    }
}

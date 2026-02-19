// EdgeDetector.swift — DocumentValidatorKit
// Detects rectangular document-shaped edges in an image.

import Vision
import UIKit

enum EdgeDetector {

    /// Returns 0–1 confidence that the image contains a document-shaped rectangle.
    static func detectEdges(in image: UIImage) async throws -> Double {
        try await VisionRequestRunner.run(
            on: image,
            configure: { request in
                guard let req = request as? VNDetectRectanglesRequest else { return }
                req.minimumAspectRatio = 0.4
                req.maximumAspectRatio = 2.0
                req.minimumConfidence = 0.2
                req.maximumObservations = 1
            },
            makeRequest: { handler in
                VNDetectRectanglesRequest(completionHandler: handler)
            },
            transform: { results in
                guard let rects = results as? [VNRectangleObservation],
                      let best = rects.first else { return 0.0 }
                return Double(best.confidence)
            },
            fallback: 0.0
        )
    }
}

// FaceDetector.swift — DocumentValidatorKit
// Detects whether at least one face is present.

import Vision
import UIKit

enum FaceDetector {

    /// Returns `true` if one or more faces are found.
    static func detectFace(in image: UIImage) async throws -> Bool {
        try await VisionRequestRunner.run(
            on: image,
            makeRequest: { handler in
                VNDetectFaceRectanglesRequest(completionHandler: handler)
            },
            transform: { results in
                let faces = results as? [VNFaceObservation] ?? []
                return !faces.isEmpty
            },
            fallback: false
        )
    }
}

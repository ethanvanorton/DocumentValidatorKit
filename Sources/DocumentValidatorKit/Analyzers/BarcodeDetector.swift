// BarcodeDetector.swift — DocumentValidatorKit
// Detects barcodes using Vision.

import Vision
import UIKit

enum BarcodeDetector {

    static func detect(in image: UIImage) async throws -> [BarcodePayload] {
        try await VisionRequestRunner.run(
            on: image,
            configure: { request in
                guard let req = request as? VNDetectBarcodesRequest else { return }
                req.symbologies = [.pdf417, .qr, .aztec, .dataMatrix]
            },
            makeRequest: { handler in
                VNDetectBarcodesRequest(completionHandler: handler)
            },
            transform: { results in
                guard let obs = results as? [VNBarcodeObservation] else { return [] }
                return obs.compactMap { o -> BarcodePayload? in
                    guard let raw = o.payloadStringValue else { return nil }
                    let kind: BarcodePayload.BarcodeKind = switch o.symbology {
                    case .pdf417:     .pdf417
                    case .qr:         .qr
                    case .aztec:      .aztec
                    case .dataMatrix: .dataMatrix
                    default:          .other
                    }
                    return BarcodePayload(kind: kind, rawString: raw)
                }
            },
            fallback: []
        )
    }
}

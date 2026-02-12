import UIKit

public final class DocumentValidator {
    
    public static func validate(
        _ image: UIImage,
        expected: DocumentType
    ) async throws -> ValidationResult {
        
        // Sensors (kept for safety analysis & debugging)
        async let docScore = VisionDocumentDetector.containsDocument(image)
        async let textScore = TextAnalyzer.textDensity(in: image)
        async let faceScore = FaceDetector.facePresence(in: image)
        
        let scores = try await (docScore, textScore, faceScore)
        
        // ML decides document type
        var (detected, confidence) = try await MLDocumentClassifier.predict(image)

        (detected, confidence) = applySafetyGate(
            detected: detected,
            confidence: confidence,
            docScore: scores.0,
            textScore: scores.1,
            faceScore: scores.2
        )

        return ValidationResult(
            isValid: detected == expected,
            confidence: confidence,
            detectedType: detected,
            reason: explanation(expected: expected, detected: detected),
            documentScore: scores.0,
            textScore: scores.1,
            faceScore: scores.2
        )
    }
}

// MARK: - Helper
private extension DocumentValidator {
    
    static func explanation(expected: DocumentType,
                            detected: DocumentType) -> String {
        if detected == expected {
            return "Document matches expected type."
        } else {
            return "Uploaded image appears to be \(detected.rawValue)."
        }
    }
    static func applySafetyGate(
        detected: DocumentType,
        confidence: Double,
        docScore: Double,
        textScore: Double,
        faceScore: Double
    ) -> (DocumentType, Double) {
        
        // Reject digital screenshots pretending to be documents
        if detected == .businessDocument &&
            confidence > 0.90 &&
            docScore < 0.05 &&        // no real-world edges
            faceScore == 0 &&
            textScore > 0.4 {         // lots of UI text
            
            return (.unknown, 0.6)
        }
        
        // Reject selfies incorrectly predicted as ID
        if detected == .driversLicense &&
            faceScore > 0.8 &&
            docScore < 0.2 {
            
            return (.unknown, 0.7)
        }
        
        return (detected, confidence)
    }
}


// DocumentValidator.swift — DocumentValidatorKit
// Primary public API for document validation.
//
// Usage:
//   let result = try await DocumentValidator.validate(image, expected: .driversLicense)
//   let result = try await DocumentValidator.validate(image, expected: .articlesOfIncorporation)
//   let result = try await DocumentValidator.validate(image, expected: myCustomCategory)

import UIKit

public final class DocumentValidator {

    /// Validates that `image` is likely a document matching the `expected` category.
    ///
    /// - Parameters:
    ///   - image: The photo or scan to validate.
    ///   - expected: The document category the user claims this is.
    ///   - options: OCR level and confidence threshold.
    /// - Returns: A `ValidationResult` with the decision, confidence, and signal breakdown.
    public static func validate(
        _ image: UIImage,
        expected: DocumentCategory,
        options: ValidationOptions = ValidationOptions()
    ) async throws -> ValidationResult {

        // ── Run all analyzers concurrently ────────────────────

        async let edgeScore  = safe { try await EdgeDetector.detectEdges(in: image) }
        async let faceResult = safe { try await FaceDetector.detectFace(in: image) }
        async let ocrResult  = TextAnalyzer.analyze(image: image, level: options.ocrLevel)
        async let barcodes   = safe { try await BarcodeDetector.detect(in: image) }

        // Await all results
        let edges = await edgeScore
        let face = await faceResult
        let ocr = try await ocrResult
        let detectedBarcodes = await barcodes

        // ── Legibility analysis (uses OCR confidences + sharpness) ──

        let legibility = await LegibilityAnalyzer.analyze(
            image: image,
            ocrConfidences: ocr.confidences
        )

        // ── Content matching ──────────────────────────────────

        let barcodeText = detectedBarcodes.map(\.rawString).joined(separator: " ")
        let contentMatch = ContentMatcher.match(
            ocrText: ocr.joinedText,
            barcodeText: barcodeText,
            category: expected
        )

        // ── Scoring ───────────────────────────────────────────

        let scoring = ScoringEngine.score(
            category: expected,
            edgeScore: edges,
            textDensity: ocr.density,
            faceDetected: face,
            contentMatch: contentMatch,
            hasBarcodes: !detectedBarcodes.isEmpty,
            legibilityScore: legibility.score,
            threshold: options.confidenceThreshold
        )

        // ── Build result ──────────────────────────────────────

        let signals = ValidationSignals(
            documentEdgeScore: edges,
            textDensityScore: ocr.density,
            faceDetected: face,
            keywordMatch: contentMatch.keywordMatch,
            matchedKeywords: contentMatch.matchedKeywordGroups,
            patternMatch: contentMatch.patternMatch,
            matchedPatterns: contentMatch.matchedPatterns,
            ocrLines: ocr.lines,
            barcodePayloads: detectedBarcodes,
            legibilityScore: legibility.score,
            sharpnessScore: legibility.sharpnessScore,
            ocrConfidence: legibility.ocrConfidence
        )

        return ValidationResult(
            isValid: scoring.isValid,
            confidence: scoring.confidence,
            reason: scoring.reason,
            expectedCategory: expected,
            signals: signals,
            qualityFeedback: legibility.feedback
        )
    }

    /// Validates the image against multiple categories and returns the best match.
    /// Useful when you want to auto-detect which document type was uploaded.
    ///
    /// - Returns: Array of results sorted by confidence (highest first).
    public static func classify(
        _ image: UIImage,
        candidates: [DocumentCategory],
        options: ValidationOptions = ValidationOptions()
    ) async throws -> [ValidationResult] {

        var results: [ValidationResult] = []

        // Run validation against each candidate
        // We share the heavy Vision work by running them sequentially
        // (OCR/edge/face detection is the expensive part and its results
        //  are the same for each category — future optimization: cache them)
        for category in candidates {
            let result = try await validate(image, expected: category, options: options)
            results.append(result)
        }

        return results.sorted { $0.confidence > $1.confidence }
    }
}

// MARK: - Safe Wrapper

private extension DocumentValidator {

    /// Wraps an async throwing call so sensor failures return a default value
    /// instead of crashing the pipeline.
    static func safe<T: Sendable>(
        _ work: @escaping () async throws -> T
    ) async -> T where T: ExpressibleByBooleanLiteral {
        do {
            return try await work()
        } catch {
            print("[DocumentValidatorKit] ⚠️ Analyzer failed: \(error.localizedDescription)")
            return false
        }
    }

    static func safe(
        _ work: @escaping () async throws -> Double
    ) async -> Double {
        do {
            return try await work()
        } catch {
            print("[DocumentValidatorKit] ⚠️ Analyzer failed: \(error.localizedDescription)")
            return 0.0
        }
    }

    static func safe(
        _ work: @escaping () async throws -> [BarcodePayload]
    ) async -> [BarcodePayload] {
        do {
            return try await work()
        } catch {
            print("[DocumentValidatorKit] ⚠️ Barcode detection failed: \(error.localizedDescription)")
            return []
        }
    }
}

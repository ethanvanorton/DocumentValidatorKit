// ScoringEngine.swift — DocumentValidatorKit
// Weighs all signals and produces a final confidence score + decision.

import Foundation

enum ScoringEngine {

    /// Weights for each signal. These are tuned for general document validation.
    /// Keyword match is the strongest signal — if the text says "PASSPORT" and
    /// you expected a passport, that's the best indicator.
    private enum Weight {
        static let keywordMatch: Double     = 0.35
        static let patternMatch: Double     = 0.20
        static let documentEdges: Double    = 0.15
        static let textDensity: Double      = 0.15
        static let faceExpectation: Double  = 0.10
        static let barcodePresence: Double  = 0.05
    }

    struct ScoringResult: Sendable {
        let confidence: Double
        let isValid: Bool
        let reason: String
    }

    static func score(
        category: DocumentCategory,
        edgeScore: Double,
        textDensity: Double,
        faceDetected: Bool,
        contentMatch: ContentMatcher.MatchResult,
        hasBarcodes: Bool,
        threshold: Double
    ) -> ScoringResult {

        var confidence: Double = 0
        var reasons: [String] = []
        var penalties: [String] = []

        // ── 1. Keyword Match (strongest signal) ──────────────

        if contentMatch.keywordMatch {
            confidence += Weight.keywordMatch
            reasons.append("Text contains expected keywords")
        } else if !category.keywordGroups.isEmpty {
            // No keywords matched but we expected them — strong negative
            penalties.append("No expected keywords found in text")
        }

        // ── 2. Pattern Match ─────────────────────────────────

        if contentMatch.patternMatch {
            confidence += Weight.patternMatch
            reasons.append("Expected patterns detected (dates, IDs, etc.)")
        }

        // ── 3. Document Edges ────────────────────────────────

        if category.expectsDocumentEdges {
            if edgeScore > 0.3 {
                confidence += Weight.documentEdges * edgeScore
                reasons.append("Document edges detected")
            } else {
                penalties.append("No document edges detected")
            }
        } else {
            // Not required, give partial credit if present
            confidence += Weight.documentEdges * 0.5
        }

        // ── 4. Text Density ──────────────────────────────────

        if textDensity >= category.minimumTextDensity {
            confidence += Weight.textDensity * min(textDensity / 0.3, 1.0)
            reasons.append("Text density is appropriate")
        } else if textDensity < 0.02 {
            // Almost no text at all — probably not a document
            penalties.append("Almost no text detected in image")
        }

        // ── 5. Face Expectation ──────────────────────────────

        if category.expectsFace {
            if faceDetected {
                confidence += Weight.faceExpectation
                reasons.append("Expected face/photo detected")
            } else {
                penalties.append("Expected face/photo not found")
            }
        } else {
            // Face not expected — give the points
            confidence += Weight.faceExpectation
        }

        // ── 6. Barcode Presence ──────────────────────────────

        if hasBarcodes {
            confidence += Weight.barcodePresence
            reasons.append("Barcode detected")
        }

        // ── Clamp to 0–1 ────────────────────────────────────

        confidence = min(max(confidence, 0), 1.0)

        // ── Hard rejection: no text + no edges = not a document ──

        if textDensity < 0.02 && edgeScore < 0.1 && !hasBarcodes {
            confidence = min(confidence, 0.1)
            penalties.append("Image does not appear to contain a document")
        }

        // ── Decision ─────────────────────────────────────────

        let isValid = confidence >= threshold

        let reason: String
        if isValid {
            reason = "Document appears to be a valid \(category.name). " +
                     reasons.prefix(2).joined(separator: ". ") + "."
        } else if !penalties.isEmpty {
            reason = "Does not appear to be a valid \(category.name). " +
                     penalties.prefix(2).joined(separator: ". ") + "."
        } else {
            reason = "Low confidence that this is a valid \(category.name)."
        }

        return ScoringResult(confidence: confidence, isValid: isValid, reason: reason)
    }
}

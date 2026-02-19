// ContentMatcher.swift — DocumentValidatorKit
// Matches OCR text against a DocumentCategory's keyword groups and regex patterns.

import Foundation

enum ContentMatcher {

    struct MatchResult: Sendable {
        let keywordMatch: Bool
        let matchedKeywordGroups: [[String]]
        let patternMatch: Bool
        let matchedPatterns: [String]
    }

    /// Checks the uppercased OCR text against the category's keywords and patterns.
    static func match(
        ocrText: String,
        barcodeText: String,
        category: DocumentCategory
    ) -> MatchResult {

        // Combine OCR + barcode text for matching
        let combined = (ocrText + " " + barcodeText).uppercased()

        // ── Keyword Groups (OR of AND-groups) ────────────────

        var matchedGroups: [[String]] = []

        for group in category.keywordGroups {
            let allPresent = group.allSatisfy { keyword in
                combined.contains(keyword.uppercased())
            }
            if allPresent {
                matchedGroups.append(group)
            }
        }

        // ── Regex Patterns ───────────────────────────────────

        var matchedPatterns: [String] = []

        for pattern in category.expectedPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               regex.firstMatch(in: combined, range: NSRange(combined.startIndex..., in: combined)) != nil {
                matchedPatterns.append(pattern)
            }
        }

        return MatchResult(
            keywordMatch: !matchedGroups.isEmpty,
            matchedKeywordGroups: matchedGroups,
            patternMatch: !matchedPatterns.isEmpty,
            matchedPatterns: matchedPatterns
        )
    }
}

// DocumentValidatorKitTests.swift

import XCTest
@testable import DocumentValidatorKit

final class DocumentValidatorKitTests: XCTestCase {

    // MARK: - DocumentCategory Tests

    func testBuiltInCategoriesExist() {
        XCTAssertFalse(DocumentCategory.allIndividual.isEmpty)
        XCTAssertFalse(DocumentCategory.allBusiness.isEmpty)
    }

    func testDriversLicenseCategory() {
        let dl = DocumentCategory.driversLicense
        XCTAssertEqual(dl.id, "drivers_license")
        XCTAssertTrue(dl.expectsFace)
        XCTAssertTrue(dl.expectsDocumentEdges)
        XCTAssertFalse(dl.keywordGroups.isEmpty)
    }

    func testCustomCategory() {
        let custom = DocumentCategory(
            name: "My Custom Doc",
            id: "custom",
            expectsFace: false,
            keywordGroups: [["invoice", "payment"]],
            expectedPatterns: [#"\$\d+"#]
        )
        XCTAssertEqual(custom.name, "My Custom Doc")
        XCTAssertEqual(custom.keywordGroups.count, 1)
        XCTAssertEqual(custom.expectedPatterns.count, 1)
    }

    // MARK: - ContentMatcher Tests

    func testKeywordMatchSuccess() {
        let category = DocumentCategory.driversLicense
        let result = ContentMatcher.match(
            ocrText: "STATE OF FLORIDA DRIVER LICENSE CLASS E",
            barcodeText: "",
            category: category
        )
        XCTAssertTrue(result.keywordMatch)
        XCTAssertFalse(result.matchedKeywordGroups.isEmpty)
    }

    func testKeywordMatchFailure() {
        let category = DocumentCategory.driversLicense
        let result = ContentMatcher.match(
            ocrText: "CUTE FLUFFY CAT SITTING ON A COUCH",
            barcodeText: "",
            category: category
        )
        XCTAssertFalse(result.keywordMatch)
        XCTAssertTrue(result.matchedKeywordGroups.isEmpty)
    }

    func testPatternMatchDates() {
        let category = DocumentCategory.utilityBill
        let result = ContentMatcher.match(
            ocrText: "AMOUNT DUE $125.50 DUE DATE 03/15/2025",
            barcodeText: "",
            category: category
        )
        XCTAssertTrue(result.patternMatch)
    }

    func testBarcodeTextIncludedInMatch() {
        let category = DocumentCategory.driversLicense
        let result = ContentMatcher.match(
            ocrText: "SOME RANDOM TEXT",
            barcodeText: "ANSI DRIVER LICENSE DL12345",
            category: category
        )
        XCTAssertTrue(result.keywordMatch)
    }

    func testPassportMRZPatternMatch() {
        let category = DocumentCategory.passport
        let result = ContentMatcher.match(
            ocrText: "PASSPORT UNITED STATES P<USASMITH<<JOHN<JAMES",
            barcodeText: "",
            category: category
        )
        XCTAssertTrue(result.keywordMatch)
        XCTAssertTrue(result.patternMatch)
    }

    // MARK: - ScoringEngine Tests

    func testHighConfidenceValidDocument() {
        let contentMatch = ContentMatcher.MatchResult(
            keywordMatch: true,
            matchedKeywordGroups: [["driver", "license"]],
            patternMatch: true,
            matchedPatterns: [#"\d{2}/\d{2}/\d{4}"#]
        )

        let result = ScoringEngine.score(
            category: .driversLicense,
            edgeScore: 0.85,
            textDensity: 0.3,
            faceDetected: true,
            contentMatch: contentMatch,
            hasBarcodes: true,
            threshold: 0.45
        )

        XCTAssertTrue(result.isValid)
        XCTAssertGreaterThan(result.confidence, 0.7)
    }

    func testRandomPhotoRejection() {
        let contentMatch = ContentMatcher.MatchResult(
            keywordMatch: false,
            matchedKeywordGroups: [],
            patternMatch: false,
            matchedPatterns: []
        )

        let result = ScoringEngine.score(
            category: .driversLicense,
            edgeScore: 0.0,
            textDensity: 0.0,
            faceDetected: false,
            contentMatch: contentMatch,
            hasBarcodes: false,
            threshold: 0.45
        )

        XCTAssertFalse(result.isValid)
        XCTAssertLessThan(result.confidence, 0.2)
    }

    func testWrongDocumentTypeRejection() {
        let contentMatch = ContentMatcher.MatchResult(
            keywordMatch: false,
            matchedKeywordGroups: [],
            patternMatch: false,
            matchedPatterns: []
        )

        let result = ScoringEngine.score(
            category: .passport,
            edgeScore: 0.7,
            textDensity: 0.4,
            faceDetected: false,
            contentMatch: contentMatch,
            hasBarcodes: false,
            threshold: 0.45
        )

        XCTAssertFalse(result.isValid)
    }

    // MARK: - ValidationOptions Tests

    func testDefaultOptions() {
        let options = ValidationOptions()
        XCTAssertEqual(options.confidenceThreshold, 0.45)
    }

    func testCustomOptions() {
        let options = ValidationOptions(ocrLevel: .fast, confidenceThreshold: 0.6)
        XCTAssertEqual(options.confidenceThreshold, 0.6)
    }

    // MARK: - Error Tests

    func testErrorDescriptions() {
        let invalidImage = DocumentValidatorError.invalidImage
        XCTAssertTrue(invalidImage.description.contains("CGImage"))
    }
}

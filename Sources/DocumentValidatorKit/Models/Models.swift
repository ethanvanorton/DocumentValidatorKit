// Models.swift — DocumentValidatorKit
// Public types for document validation.

import Foundation

// MARK: - Document Category

/// A category of document the user claims to be uploading.
/// Use the built-in presets or create custom categories with your own keywords.
public struct DocumentCategory: Sendable, Equatable, Hashable {

    /// Display name shown in UI or logs (e.g. "Driver's License").
    public let name: String

    /// Unique identifier (e.g. "drivers_license").
    public let id: String

    /// Whether a face/photo is expected on this document type.
    public let expectsFace: Bool

    /// Whether a rectangular document shape is expected.
    public let expectsDocumentEdges: Bool

    /// Keywords that should appear in the OCR text to confirm this document type.
    /// Matching is case-insensitive. At least one keyword group must match.
    /// Each inner array is an AND-group: all words in the group must appear.
    /// The outer array is OR: any group matching counts as a hit.
    ///
    /// Example for driver's license:
    /// ```
    /// [["driver", "license"], ["driver", "licence"], ["DL"], ["operator", "license"]]
    /// ```
    /// This means: ("driver" AND "license") OR ("driver" AND "licence") OR ("DL") OR ...
    public let keywordGroups: [[String]]

    /// Minimum text density (0–1) expected. Documents with less text than this
    /// are suspicious. Set low (e.g. 0.05) for photo-heavy docs like passports.
    public let minimumTextDensity: Double

    /// Optional regex patterns that should match somewhere in the OCR text.
    /// Useful for dates, ID numbers, dollar amounts, etc.
    public let expectedPatterns: [String]

    public init(
        name: String,
        id: String,
        expectsFace: Bool = false,
        expectsDocumentEdges: Bool = true,
        keywordGroups: [[String]] = [],
        minimumTextDensity: Double = 0.05,
        expectedPatterns: [String] = []
    ) {
        self.name = name
        self.id = id
        self.expectsFace = expectsFace
        self.expectsDocumentEdges = expectsDocumentEdges
        self.keywordGroups = keywordGroups
        self.minimumTextDensity = minimumTextDensity
        self.expectedPatterns = expectedPatterns
    }
}

// MARK: - Built-in Categories

public extension DocumentCategory {

    // ── Individual Documents ─────────────────────────────────

    static let driversLicense = DocumentCategory(
        name: "Driver's License",
        id: "drivers_license",
        expectsFace: true,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["driver", "license"],
            ["driver", "licence"],
            ["operator", "license"],
            ["DL"],
            ["driving", "license"],
            ["identification", "card"],
        ],
        minimumTextDensity: 0.08,
        expectedPatterns: [
            #"\d{2}[/-]\d{2}[/-]\d{2,4}"#,     // date pattern
            #"[A-Z]\d{3,}"#,                     // license number patterns
        ]
    )

    static let passport = DocumentCategory(
        name: "Passport",
        id: "passport",
        expectsFace: true,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["passport"],
            ["pasaporte"],            // Spanish
            ["travel", "document"],
        ],
        minimumTextDensity: 0.05,
        expectedPatterns: [
            #"[A-Z]{1,2}\d{6,9}"#,   // passport number
            #"[PM][<]"#,              // MRZ line start
        ]
    )

    static let utilityBill = DocumentCategory(
        name: "Utility Bill",
        id: "utility_bill",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["electric", "bill"],
            ["water", "bill"],
            ["gas", "bill"],
            ["utility", "bill"],
            ["account", "number"],
            ["amount", "due"],
            ["billing", "statement"],
            ["energy", "statement"],
            ["service", "address"],
        ],
        minimumTextDensity: 0.15,
        expectedPatterns: [
            #"\$[\d,]+\.\d{2}"#,                 // dollar amount
            #"\d{2}[/-]\d{2}[/-]\d{2,4}"#,       // date
        ]
    )

    static let bankStatement = DocumentCategory(
        name: "Bank Statement",
        id: "bank_statement",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["bank", "statement"],
            ["account", "summary"],
            ["checking", "account"],
            ["savings", "account"],
            ["beginning", "balance"],
            ["ending", "balance"],
            ["deposits", "withdrawals"],
        ],
        minimumTextDensity: 0.2,
        expectedPatterns: [
            #"\$[\d,]+\.\d{2}"#,
            #"\d{2}[/-]\d{2}[/-]\d{2,4}"#,
        ]
    )

    static let socialSecurityCard = DocumentCategory(
        name: "Social Security Card",
        id: "social_security_card",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["social", "security"],
            ["social security administration"],
        ],
        minimumTextDensity: 0.05,
        expectedPatterns: [
            #"\d{3}-\d{2}-\d{4}"#,   // SSN format
        ]
    )

    // ── Business Documents ───────────────────────────────────

    static let articlesOfIncorporation = DocumentCategory(
        name: "Articles of Incorporation",
        id: "articles_of_incorporation",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["articles", "incorporation"],
            ["certificate", "incorporation"],
            ["certificate", "formation"],
            ["articles", "organization"],
            ["corporate", "charter"],
            ["secretary", "state"],
        ],
        minimumTextDensity: 0.2,
        expectedPatterns: [
            #"(?i)incorporat"#,
            #"(?i)registered\s+agent"#,
        ]
    )

    static let businessLicense = DocumentCategory(
        name: "Business License",
        id: "business_license",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["business", "license"],
            ["business", "licence"],
            ["occupational", "license"],
            ["business", "permit"],
            ["license", "number"],
        ],
        minimumTextDensity: 0.1,
        expectedPatterns: [
            #"\d{2}[/-]\d{2}[/-]\d{2,4}"#,
        ]
    )

    static let einLetter = DocumentCategory(
        name: "EIN Confirmation Letter",
        id: "ein_letter",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["employer", "identification", "number"],
            ["EIN"],
            ["internal", "revenue", "service"],
            ["IRS"],
            ["147C"],
            ["SS-4"],
        ],
        minimumTextDensity: 0.15,
        expectedPatterns: [
            #"\d{2}-\d{7}"#,         // EIN format
        ]
    )

    static let taxReturn = DocumentCategory(
        name: "Tax Return",
        id: "tax_return",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["form", "1040"],
            ["form", "1120"],
            ["form", "1065"],
            ["tax", "return"],
            ["internal", "revenue"],
            ["taxable", "income"],
            ["adjusted", "gross"],
        ],
        minimumTextDensity: 0.2,
        expectedPatterns: [
            #"\$[\d,]+\.\d{2}"#,
            #"(?i)form\s+\d{3,4}"#,
        ]
    )

    static let proofOfInsurance = DocumentCategory(
        name: "Proof of Insurance",
        id: "proof_of_insurance",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["insurance", "certificate"],
            ["certificate", "liability"],
            ["proof", "insurance"],
            ["policy", "number"],
            ["general", "liability"],
            ["workers", "compensation"],
            ["ACORD"],
        ],
        minimumTextDensity: 0.15,
        expectedPatterns: [
            #"\d{2}[/-]\d{2}[/-]\d{2,4}"#,
            #"(?i)policy"#,
        ]
    )

    static let w9 = DocumentCategory(
        name: "W-9 Form",
        id: "w9",
        expectsFace: false,
        expectsDocumentEdges: true,
        keywordGroups: [
            ["W-9"],
            ["taxpayer", "identification"],
            ["request", "taxpayer"],
            ["certification", "tin"],
        ],
        minimumTextDensity: 0.15,
        expectedPatterns: [
            #"\d{2}-\d{7}"#,         // EIN
            #"\d{3}-\d{2}-\d{4}"#,   // SSN
        ]
    )

    /// Convenience: all built-in individual document types.
    static let allIndividual: [DocumentCategory] = [
        .driversLicense, .passport, .utilityBill,
        .bankStatement, .socialSecurityCard,
    ]

    /// Convenience: all built-in business document types.
    static let allBusiness: [DocumentCategory] = [
        .articlesOfIncorporation, .businessLicense, .einLetter,
        .taxReturn, .proofOfInsurance, .w9,
    ]
}

// MARK: - Validation Result

public struct ValidationResult: Sendable {
    /// Whether the image likely matches the expected document category.
    public let isValid: Bool

    /// Overall confidence score 0–1.
    public let confidence: Double

    /// Human-readable explanation of the decision.
    public let reason: String

    /// The category that was expected.
    public let expectedCategory: DocumentCategory

    /// Detailed signal breakdown (useful for debugging and tuning).
    public let signals: ValidationSignals

    public init(
        isValid: Bool,
        confidence: Double,
        reason: String,
        expectedCategory: DocumentCategory,
        signals: ValidationSignals
    ) {
        self.isValid = isValid
        self.confidence = confidence
        self.reason = reason
        self.expectedCategory = expectedCategory
        self.signals = signals
    }
}

// MARK: - Validation Signals

/// Raw signal scores from each analyzer.
public struct ValidationSignals: Sendable {
    /// 0–1 confidence that a document-shaped rectangle exists.
    public let documentEdgeScore: Double

    /// 0–1 normalized text density.
    public let textDensityScore: Double

    /// Whether at least one face was detected.
    public let faceDetected: Bool

    /// Whether any keyword group from the category matched the OCR text.
    public let keywordMatch: Bool

    /// Which keyword groups matched (for debugging).
    public let matchedKeywords: [[String]]

    /// Whether any expected regex pattern matched.
    public let patternMatch: Bool

    /// Which patterns matched (for debugging).
    public let matchedPatterns: [String]

    /// The raw OCR text lines recognized in the image.
    public let ocrLines: [String]

    /// Detected barcode payloads, if any.
    public let barcodePayloads: [BarcodePayload]

    public init(
        documentEdgeScore: Double,
        textDensityScore: Double,
        faceDetected: Bool,
        keywordMatch: Bool,
        matchedKeywords: [[String]],
        patternMatch: Bool,
        matchedPatterns: [String],
        ocrLines: [String],
        barcodePayloads: [BarcodePayload]
    ) {
        self.documentEdgeScore = documentEdgeScore
        self.textDensityScore = textDensityScore
        self.faceDetected = faceDetected
        self.keywordMatch = keywordMatch
        self.matchedKeywords = matchedKeywords
        self.patternMatch = patternMatch
        self.matchedPatterns = matchedPatterns
        self.ocrLines = ocrLines
        self.barcodePayloads = barcodePayloads
    }
}

// MARK: - Barcode Payload

public struct BarcodePayload: Sendable {
    public enum BarcodeKind: String, Sendable {
        case pdf417
        case qr
        case aztec
        case dataMatrix
        case other
    }

    public let kind: BarcodeKind
    public let rawString: String

    public init(kind: BarcodeKind, rawString: String) {
        self.kind = kind
        self.rawString = rawString
    }
}

// MARK: - Validation Options

public struct ValidationOptions: Sendable {
    /// OCR accuracy: `.fast` for quick checks, `.accurate` for best results.
    public let ocrLevel: OCRLevel

    /// Minimum overall confidence to consider the document valid (0–1). Default 0.45.
    public let confidenceThreshold: Double

    public init(ocrLevel: OCRLevel = .accurate, confidenceThreshold: Double = 0.45) {
        self.ocrLevel = ocrLevel
        self.confidenceThreshold = confidenceThreshold
    }

    public enum OCRLevel: Sendable {
        case fast
        case accurate
    }
}

// MARK: - Errors

public enum DocumentValidatorError: Error, Sendable, CustomStringConvertible {
    case invalidImage
    case analysisFailed(underlying: Error)

    public var description: String {
        switch self {
        case .invalidImage:
            return "The provided UIImage could not be converted to CGImage."
        case .analysisFailed(let e):
            return "Analysis failed: \(e.localizedDescription)"
        }
    }
}

# DocumentValidatorKit

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An on-device iOS SDK that validates uploaded images against expected document types. Catches cat photos, selfies, screenshots, and mismatched documents — no ML model training required.

## The Problem

Your app asks a user to upload their Driver's License, and they upload a picture of a clown. Or you request Articles of Incorporation and get a selfie. DocumentValidatorKit answers one question: **"Is this image likely what the user says it is?"**

## How It Works

Instead of training an ML model for every document type, the SDK uses a **signal-based approach**:

1. **OCR** — Reads text from the image and matches against expected keywords
2. **Edge Detection** — Checks for document-shaped rectangles
3. **Face Detection** — Verifies face presence for IDs/passports
4. **Barcode Detection** — Finds PDF417, QR codes, etc.
5. **Pattern Matching** — Looks for dates, ID numbers, dollar amounts

All signals are weighted and scored to produce a confidence value. Adding new document types is just defining keywords — no retraining.

## Requirements

| Requirement | Version |
|-------------|---------|
| iOS         | 16.0+   |
| Swift       | 6.2+    |
| Xcode       | 16.0+   |

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/ethanvanorton/DocumentValidatorKit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repo URL.

## Quick Start

### Validate a Specific Document

```swift
import DocumentValidatorKit

let image: UIImage = // from camera or photo library

// Is this really a driver's license?
let result = try await DocumentValidator.validate(image, expected: .driversLicense)

if result.isValid {
    print("✅ Looks legit — confidence: \(result.confidence)")
} else {
    print("❌ \(result.reason)")
}
```

### Built-in Document Types

**Individual:**
`.driversLicense` · `.passport` · `.utilityBill` · `.bankStatement` · `.socialSecurityCard`

**Business:**
`.articlesOfIncorporation` · `.businessLicense` · `.einLetter` · `.taxReturn` · `.proofOfInsurance` · `.w9`

### Auto-Detect Document Type

```swift
let ranked = try await DocumentValidator.classify(
    image,
    candidates: DocumentCategory.allIndividual + DocumentCategory.allBusiness
)

if let best = ranked.first, best.isValid {
    print("Best match: \(best.expectedCategory.name) (\(best.confidence))")
}
```

### Custom Document Types

No SDK update needed — just define your own category:

```swift
let vendorInvoice = DocumentCategory(
    name: "Vendor Invoice",
    id: "vendor_invoice",
    expectsFace: false,
    keywordGroups: [
        ["invoice", "number"],
        ["bill", "to"],
        ["purchase", "order"],
        ["amount", "due"],
    ],
    minimumTextDensity: 0.15,
    expectedPatterns: [
        #"\$[\d,]+\.\d{2}"#,                // dollar amounts
        #"\d{2}[/-]\d{2}[/-]\d{2,4}"#,      // dates
        #"(?i)inv[-#]?\d{3,}"#,              // invoice numbers
    ]
)

let result = try await DocumentValidator.validate(image, expected: vendorInvoice)
```

### Inspecting Signals

```swift
let result = try await DocumentValidator.validate(image, expected: .passport)

// Debugging
print("Edge score:  \(result.signals.documentEdgeScore)")
print("Text density: \(result.signals.textDensityScore)")
print("Face found:  \(result.signals.faceDetected)")
print("Keywords:    \(result.signals.matchedKeywords)")
print("Patterns:    \(result.signals.matchedPatterns)")
print("OCR lines:   \(result.signals.ocrLines)")
print("Barcodes:    \(result.signals.barcodePayloads.count)")
```

## Architecture

```
DocumentValidatorKit/
├── Package.swift
└── Sources/DocumentValidatorKit/
    ├── Core/
    │   ├── DocumentValidator.swift     ← Public API
    │   └── ScoringEngine.swift         ← Weighted signal scoring
    ├── Analyzers/
    │   ├── TextAnalyzer.swift          ← OCR recognition
    │   ├── EdgeDetector.swift          ← Rectangle detection
    │   ├── FaceDetector.swift          ← Face presence
    │   ├── BarcodeDetector.swift       ← Barcode reading
    │   ├── ContentMatcher.swift        ← Keyword/pattern matching
    │   └── VisionRequestRunner.swift   ← Safe Vision execution
    └── Models/
        └── Models.swift                ← All public types
```

### Validation Pipeline

```
UIImage
  ↓
┌─────────────────────────────────────────────┐
│            Concurrent Analysis               │
│  ┌──────┐ ┌─────┐ ┌──────┐ ┌───────────┐   │
│  │ OCR  │ │Edge │ │ Face │ │  Barcode  │   │
│  └──┬───┘ └──┬──┘ └──┬───┘ └─────┬─────┘   │
│     └────────┼───────┼───────────┘           │
│              ↓       ↓                       │
│     Content Matcher (keywords + patterns)    │
│              ↓                               │
│     Scoring Engine (weighted signals)        │
│              ↓                               │
│     Valid / Invalid + Confidence             │
└─────────────────────────────────────────────┘
```

### Signal Weights

| Signal | Weight | What It Checks |
|--------|--------|---------------|
| Keyword match | 35% | Expected words found in OCR text |
| Pattern match | 20% | Dates, ID numbers, amounts via regex |
| Document edges | 15% | Rectangular shape in image |
| Text density | 15% | Enough text for a document |
| Face expectation | 10% | Face present when expected (IDs) |
| Barcode presence | 5% | Any barcode detected |

## What Gets Rejected

| Upload | Expected | Result |
|--------|----------|--------|
| Cat photo | Driver's License | ❌ No text, no edges, no face |
| Clown photo | Articles of Incorporation | ❌ No document keywords |
| Utility bill | Passport | ❌ Wrong keywords, no face |
| Selfie | Business License | ❌ No document text/edges |
| Screenshot of text | Driver's License | ❌ No document edges, wrong keywords |
| Actual DL photo | Driver's License | ✅ Keywords + face + edges + patterns |

## Contributing

1. Fork → 2. Branch → 3. Commit → 4. PR

## License

MIT — see [LICENSE](LICENSE).

# DocumentValidatorKit

[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-orange.svg)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue.svg)](https://developer.apple.com/ios/)
[![SPM Compatible](https://img.shields.io/badge/SPM-Compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An on-device iOS SDK for validating identity and business documents. Uses CoreML + Vision to classify documents, detect fraud signals, and extract structured data — all without sending images to a server.

## Features

- **Document Classification** — ML-powered identification of driver's licenses, passports, and business documents
- **Fraud Detection** — Safety gates catch screenshots, photocopies, and selfies posing as IDs
- **Barcode Reading** — PDF417 (US/CA driver licenses), QR, Aztec, and DataMatrix with full AAMVA field parsing
- **MRZ Parsing** — Machine Readable Zone extraction for passports (TD3), national IDs (TD1/TD2)
- **OCR Extraction** — Structured field extraction (name, DOB, document number, dates, invoice totals)
- **Fully On-Device** — No network calls. All processing happens locally via CoreML and Vision
- **Async/Await** — Modern Swift concurrency with safe continuation handling throughout

## Requirements

| Requirement | Version |
|-------------|---------|
| iOS         | 16.0+   |
| Swift       | 6.2+    |
| Xcode       | 16.0+   |

## Installation

### Swift Package Manager

Add the dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/YOUR_USERNAME/DocumentValidatorKit.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies** → paste the repository URL.

### Local Development

Clone the repo and add it as a local package:

```bash
git clone https://github.com/YOUR_USERNAME/DocumentValidatorKit.git
```

In Xcode: **File → Add Package Dependencies → Add Local…** → select the cloned folder.

## Quick Start

### Basic Validation

```swift
import DocumentValidatorKit

let image: UIImage = // ... from camera or photo library

let result = try await DocumentValidator.validate(image, expected: .driversLicense)

if result.isValid {
    print("✅ Valid document — confidence: \(result.confidence)")
} else {
    print("❌ \(result.reason)")
}
```

### With Data Extraction

```swift
let options = ValidationOptions(extractData: true, ocrLevel: .accurate)

let result = try await DocumentValidator.validate(
    image,
    expected: .passport,
    options: options
)

// Structured fields from MRZ / barcode / OCR
if let fields = result.extractedData?.fields {
    print("Name: \(fields["firstName"] ?? "N/A") \(fields["lastName"] ?? "N/A")")
    print("DOB:  \(fields["dateOfBirth"] ?? "N/A")")
    print("Doc#: \(fields["documentNumber"] ?? "N/A")")
}

// Raw barcode payload (AAMVA for US driver licenses)
if let barcode = result.extractedData?.barcodePayload {
    print("Barcode type: \(barcode.kind)")
    print("AAMVA fields: \(barcode.aamvaFields ?? [:])")
}
```

### Inspecting Sensor Scores

```swift
let result = try await DocumentValidator.validate(image, expected: .businessDocument)

// Useful for debugging and tuning thresholds
print("Document shape score: \(result.documentScore)")  // 0-1: rectangle detection confidence
print("Text density score:   \(result.textScore)")       // 0-1: how text-heavy the image is
print("Face presence score:  \(result.faceScore)")        // 0 or 1: face detected?
```

## Architecture

```
DocumentValidatorKit/
├── Package.swift
└── Sources/DocumentValidatorKit/
    ├── DocumentValidator.swift              ← Public API entry point
    ├── DocumentClassifier.mlmodel           ← CoreML classification model
    │
    ├── Models/
    │   └── Models.swift                     ← DocumentType, ValidationResult,
    │                                           ExtractedDocumentData, BarcodePayload,
    │                                           ValidationOptions, errors
    ├── Detectors/
    │   ├── MLDocumentClassifier.swift       ← CoreML + Vision classification
    │   ├── VisionDocumentDetector.swift     ← Rectangle/edge detection
    │   ├── TextAnalyzer.swift               ← OCR text density + line extraction
    │   └── FaceDetector.swift               ← Face presence detection
    │
    ├── Extractors/
    │   ├── BarcodeDetector.swift            ← PDF417/QR/Aztec + AAMVA parsing
    │   ├── MRZDetector.swift                ← Passport/ID MRZ parsing (TD1/TD2/TD3)
    │   └── DataExtractor.swift              ← Extraction orchestrator
    │
    └── Utilities/
        └── VisionRequestRunner.swift        ← Safe Vision request execution
```

### Validation Pipeline

```
UIImage input
    ↓
┌───────────────────────────────────────────┐
│         Concurrent Sensor Sweep           │
│  ┌─────────┐ ┌──────────┐ ┌───────────┐  │
│  │Rectangle│ │OCR Density│ │   Face    │  │
│  │Detection│ │  Scanner  │ │ Detector  │  │
│  └────┬────┘ └─────┬────┘ └─────┬─────┘  │
│       └──────┬─────┴─────┬──────┘         │
│              ↓           ↓                │
│     ML Classification   Safety Gates      │
│              ↓           ↓                │
│        DocumentType + Confidence          │
└───────────────────────┬───────────────────┘
                        ↓
          ┌─────────────────────────┐
          │   Data Extraction       │
          │  (if options.extract)   │
          │  ┌───────┐ ┌─────┐     │
          │  │Barcode│ │ MRZ │     │
          │  └───┬───┘ └──┬──┘     │
          │      └───┬────┘        │
          │     OCR Heuristics     │
          └────────┬───────────────┘
                   ↓
          ValidationResult
```

## Safety Gates

The SDK includes built-in heuristic checks that override ML predictions when sensor signals indicate fraud:

| Scenario | Detection Method |
|----------|-----------------|
| Screenshot pretending to be a document | High text density + no document edges + no face |
| Selfie classified as driver's license | High face score + low document edge score |
| Low-confidence classification | Confidence below 40% threshold → `.unknown` |

## Document Types

| Type | Barcode Support | MRZ Support | OCR Heuristics |
|------|:-:|:-:|:-:|
| Driver's License | ✅ PDF417 (AAMVA) | ✅ TD1 | ✅ DOB, expiry, DL number |
| Passport | ✅ | ✅ TD2/TD3 | — |
| Business Document | — | — | ✅ Invoice #, total, date |

## Error Handling

The SDK uses typed errors for clear diagnostics:

```swift
do {
    let result = try await DocumentValidator.validate(image, expected: .passport)
} catch DocumentValidatorError.invalidImage {
    // UIImage couldn't produce a CGImage
} catch DocumentValidatorError.classificationFailed(let underlying) {
    // CoreML model failed
} catch DocumentValidatorError.detectionFailed(let sensor, let underlying) {
    // A specific Vision sensor failed
} catch {
    // Other errors
}
```

> **Note:** Individual sensor failures (face, text, rectangle) are caught internally and fall back to a score of `0` — they won't crash the pipeline. Only the ML classifier throws fatally since it's the core decision-maker.

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

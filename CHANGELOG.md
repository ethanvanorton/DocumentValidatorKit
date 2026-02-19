# Changelog

All notable changes to DocumentValidatorKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2025-02-18

### Changed
- **BREAKING:** Replaced CoreML classifier with signal-based validation (OCR keywords, edge detection, face detection, barcode scanning, regex patterns)
- **BREAKING:** `DocumentType` enum replaced by extensible `DocumentCategory` struct
- **BREAKING:** `ValidationResult` now returns `ValidationSignals` instead of raw sensor scores
- No ML model required — add new document types by defining keywords, no retraining needed

### Added
- 11 built-in document categories (5 individual, 6 business)
- Custom document category support via `DocumentCategory` initializer
- `DocumentValidator.classify()` for auto-detecting document type from candidates
- `ContentMatcher` for keyword group and regex pattern matching
- `ScoringEngine` with weighted signal scoring
- Configurable confidence threshold via `ValidationOptions`

### Removed
- `DocumentClassifier.mlmodel` — no longer shipped
- `MLDocumentClassifier` — CoreML dependency removed
- `DataExtractor`, `MRZDetector` — removed in favor of signal-based approach
- `ExtractedDocumentData` — replaced by `ValidationSignals`

## [1.0.0] - 2025-02-17

### Added
- CoreML + Vision document classification (driver's license, passport, business document)
- Safety gates for screenshot and selfie rejection
- Concurrent sensor pipeline (rectangle detection, text density, face presence)
- PDF417 barcode detection with AAMVA field parsing
- MRZ detection and parsing for passports (TD3), national IDs (TD1), travel docs (TD2)
- OCR-based heuristic field extraction
- Safe Vision request runner preventing hanging continuations
- Full Swift 6.2 concurrency support with Sendable conformance

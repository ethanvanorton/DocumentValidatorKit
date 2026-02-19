// DocumentValidatorKit.swift — Public exports

// All public types are already marked `public` in their own files.
// This file exists as the module entry point and for any future
// convenience extensions.

/// DocumentValidatorKit — Validate identity & business documents on-device.
///
/// Quick start:
/// ```swift
/// let result = try await DocumentValidator.validate(image, expected: .driversLicense)
/// print(result.isValid, result.confidence)
/// ```
///
/// With data extraction:
/// ```swift
/// let options = ValidationOptions(extractData: true, ocrLevel: .accurate)
/// let result = try await DocumentValidator.validate(image, expected: .passport, options: options)
/// print(result.extractedData?.fields["firstName"])
/// ```

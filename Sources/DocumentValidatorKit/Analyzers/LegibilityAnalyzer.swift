// LegibilityAnalyzer.swift — DocumentValidatorKit
// Checks whether a document image is sharp and readable enough to validate.
//
// Uses two complementary signals:
// 1. Laplacian variance — measures edge sharpness (blurry images have low variance)
// 2. OCR confidence — average confidence of recognized text observations

import UIKit
import Accelerate
import CoreImage

enum LegibilityAnalyzer {

    struct LegibilityResult: Sendable {
        /// 0–1 overall legibility score.
        let score: Double

        /// 0–1 image sharpness from Laplacian variance. Below ~0.3 is blurry.
        let sharpnessScore: Double

        /// 0–1 average OCR confidence across recognized text lines.
        let ocrConfidence: Double

        /// Human-readable feedback if image quality is poor.
        let feedback: String?
    }

    /// Analyzes image legibility using sharpness detection and OCR confidence.
    ///
    /// - Parameters:
    ///   - image: The document image to assess.
    ///   - ocrObservations: Pre-computed OCR observations from TextAnalyzer (avoids running OCR twice).
    static func analyze(
        image: UIImage,
        ocrConfidences: [Float]
    ) async -> LegibilityResult {

        let sharpness = measureSharpness(image)
        let avgOCRConfidence = ocrConfidences.isEmpty
            ? 0.0
            : Double(ocrConfidences.reduce(0, +)) / Double(ocrConfidences.count)

        // Weighted combination: sharpness matters more since blurry = unreadable
        let score = (sharpness * 0.6) + (avgOCRConfidence * 0.4)

        let feedback = generateFeedback(
            sharpness: sharpness,
            ocrConfidence: avgOCRConfidence,
            score: score
        )

        return LegibilityResult(
            score: score,
            sharpnessScore: sharpness,
            ocrConfidence: avgOCRConfidence,
            feedback: feedback
        )
    }
}

// MARK: - Sharpness Detection (Laplacian Variance)

private extension LegibilityAnalyzer {

    /// Computes a 0–1 sharpness score using the variance of a Laplacian filter.
    ///
    /// The Laplacian highlights edges. Sharp images have high edge variance;
    /// blurry images have low variance because edges are smoothed out.
    ///
    /// The raw variance is mapped to 0–1 using a sigmoid-like normalization
    /// where ~500+ variance = very sharp (1.0) and <50 = very blurry (~0.1).
    static func measureSharpness(_ image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0 }

        let width = cgImage.width
        let height = cgImage.height

        // Convert to grayscale pixel buffer
        guard let grayscale = grayscalePixels(from: cgImage, width: width, height: height) else {
            return 0
        }

        // Apply 3×3 Laplacian kernel: [0,1,0; 1,-4,1; 0,1,0]
        let laplacian = applyLaplacian(to: grayscale, width: width, height: height)

        // Compute variance of the Laplacian output
        let variance = computeVariance(laplacian)

        // Normalize to 0–1 range
        // Empirically: variance < 50 = very blurry, > 500 = very sharp
        let normalized = min(max(variance / 500.0, 0), 1.0)

        return normalized
    }

    /// Converts a CGImage to a grayscale Float array.
    static func grayscalePixels(from cgImage: CGImage, width: Int, height: Int) -> [Float]? {
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bytesPerRow = width
        let totalBytes = width * height

        var pixelData = [UInt8](repeating: 0, count: totalBytes)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        return pixelData.map { Float($0) }
    }

    /// Applies a 3×3 Laplacian convolution kernel.
    static func applyLaplacian(to pixels: [Float], width: Int, height: Int) -> [Float] {
        // Laplacian kernel: [0,1,0; 1,-4,1; 0,1,0]
        var output = [Float](repeating: 0, count: width * height)

        for y in 1..<(height - 1) {
            for x in 1..<(width - 1) {
                let idx = y * width + x
                let lap = -4.0 * pixels[idx]
                    + pixels[(y - 1) * width + x]     // top
                    + pixels[(y + 1) * width + x]     // bottom
                    + pixels[y * width + (x - 1)]     // left
                    + pixels[y * width + (x + 1)]     // right
                output[idx] = lap
            }
        }

        return output
    }

    /// Computes the variance of a Float array.
    static func computeVariance(_ values: [Float]) -> Double {
        guard !values.isEmpty else { return 0 }

        var mean: Float = 0
        var meanSq: Float = 0
        let count = vDSP_Length(values.count)

        vDSP_meanv(values, 1, &mean, count)
        vDSP_measqv(values, 1, &meanSq, count)

        // Variance = E[X²] - (E[X])²
        let variance = meanSq - (mean * mean)
        return Double(max(variance, 0))
    }
}

// MARK: - Feedback Generation

private extension LegibilityAnalyzer {

    static func generateFeedback(
        sharpness: Double,
        ocrConfidence: Double,
        score: Double
    ) -> String? {
        // Only provide feedback if there's a problem
        if score >= 0.5 { return nil }

        var issues: [String] = []

        if sharpness < 0.2 {
            issues.append("Image is too blurry — please retake with a steady hand")
        } else if sharpness < 0.35 {
            issues.append("Image is slightly blurry — try better lighting or hold the camera steadier")
        }

        if ocrConfidence < 0.3 && ocrConfidence > 0 {
            issues.append("Text is difficult to read — ensure the document is well-lit and in focus")
        }

        if sharpness < 0.15 && ocrConfidence < 0.2 {
            return "Image is too blurry to read. Please retake the photo with good lighting and a steady hand."
        }

        return issues.isEmpty ? "Image quality is too low to validate." : issues.joined(separator: ". ") + "."
    }
}

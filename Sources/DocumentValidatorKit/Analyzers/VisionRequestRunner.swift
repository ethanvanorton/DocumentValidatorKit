// VisionRequestRunner.swift — DocumentValidatorKit
// Centralised, safe runner for Vision requests.
// Guarantees the continuation always resumes exactly once.

import Vision
import UIKit
import os

enum VisionRequestRunner {

    /// Perform a single `VNRequest` on `image` and transform the results.
    static func run<T: Sendable>(
        on image: UIImage,
        configure: ((VNRequest) -> Void)? = nil,
        makeRequest: @escaping @Sendable (@escaping VNRequestCompletionHandler) -> VNRequest,
        transform: @escaping @Sendable ([Any]?) -> T,
        fallback: T
    ) async throws -> T {
        guard let cgImage = image.cgImage else {
            throw DocumentValidatorError.invalidImage
        }

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in

            let resumed = AtomicBool(false)

            func safeResume(returning value: T) {
                if resumed.compareExchange(expected: false, desired: true) {
                    continuation.resume(returning: value)
                }
            }

            func safeResume(throwing error: Error) {
                if resumed.compareExchange(expected: false, desired: true) {
                    continuation.resume(throwing: error)
                }
            }

            let request = makeRequest { request, error in
                if let error {
                    safeResume(throwing: error)
                    return
                }
                let value = transform(request.results)
                safeResume(returning: value)
            }

            configure?(request)

            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                safeResume(throwing: error)
            }
        }
    }
}

// MARK: - Atomic Bool

private final class AtomicBool: @unchecked Sendable {
    private var _value: Bool
    private var _lock = os_unfair_lock()

    init(_ initial: Bool) {
        _value = initial
    }

    func compareExchange(expected: Bool, desired: Bool) -> Bool {
        os_unfair_lock_lock(&_lock)
        defer { os_unfair_lock_unlock(&_lock) }
        if _value == expected {
            _value = desired
            return true
        }
        return false
    }
}

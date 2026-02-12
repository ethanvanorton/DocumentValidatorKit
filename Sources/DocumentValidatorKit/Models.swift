import Foundation

public enum DocumentType: String, Codable, Sendable {
    case driversLicense
    case passport
    case businessDocument
    case unknown
}

public struct ValidationResult: Sendable {
    public let isValid: Bool
    public let confidence: Double
    public let detectedType: DocumentType
    public let reason: String
    
    // Debug scores (important for tuning before ML)
    public let documentScore: Double
    public let textScore: Double
    public let faceScore: Double
    
    public init(
        isValid: Bool,
        confidence: Double,
        detectedType: DocumentType,
        reason: String,
        documentScore: Double,
        textScore: Double,
        faceScore: Double
    ) {
        self.isValid = isValid
        self.confidence = confidence
        self.detectedType = detectedType
        self.reason = reason
        self.documentScore = documentScore
        self.textScore = textScore
        self.faceScore = faceScore
    }
}

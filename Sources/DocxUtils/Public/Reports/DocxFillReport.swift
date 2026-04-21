import Foundation

public struct DocxFillReport: Sendable {
    public var processedParts: [String] = []
    public var foundKeys: Set<String> = []
    public var replacedKeys: Set<String> = []
    public var missingKeys: Set<String> = []
    public var replacementsCount: Int = 0
    public var issues: [DocxProcessingIssue] = []

    public init() {}
}

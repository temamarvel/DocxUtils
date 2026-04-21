import Foundation

public struct DocxScanReport: Sendable {
    public var processedParts: [String] = []
    public var orderedKeys: [String] = []
    public var foundKeys: Set<String> = []
    public var occurrences: [String: Int] = [:]
    public var partsByKey: [String: Set<String>] = [:]
    public var issues: [DocxProcessingIssue] = []

    public init() {}

    public var sortedKeys: [String] {
        foundKeys.sorted()
    }
}

public struct DocxProcessingIssue: Sendable, Hashable {
    public let partPath: String
    public let operation: Operation
    public let message: String

    public enum Operation: Sendable, Hashable {
        case read
        case parse
        case mutate
        case write
    }
}

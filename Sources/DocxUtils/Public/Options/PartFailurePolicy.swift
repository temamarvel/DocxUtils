public enum PartFailurePolicy: Sendable {
    case failFast
    case collectAndThrow
    case continueAndReport
}

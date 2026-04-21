public enum MissingKeyPolicy: Sendable {
    case error
    case keepPlaceholder
    case replaceWithEmptyString
}

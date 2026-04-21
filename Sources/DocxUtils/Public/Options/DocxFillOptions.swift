public struct DocxFillOptions: Sendable {
    public var scope: DocxProcessingScope
    public var pattern: DocxPlaceholderPattern
    public var missingKeyPolicy: MissingKeyPolicy
    public var partFailurePolicy: PartFailurePolicy
    public var replacementStylePolicy: ReplacementStylePolicy

    public init(
        scope: DocxProcessingScope = .init(),
        pattern: DocxPlaceholderPattern = .init(),
        missingKeyPolicy: MissingKeyPolicy = .error,
        partFailurePolicy: PartFailurePolicy = .failFast,
        replacementStylePolicy: ReplacementStylePolicy = .removeHighlightOnly
    ) {
        self.scope = scope
        self.pattern = pattern
        self.missingKeyPolicy = missingKeyPolicy
        self.partFailurePolicy = partFailurePolicy
        self.replacementStylePolicy = replacementStylePolicy
    }
}

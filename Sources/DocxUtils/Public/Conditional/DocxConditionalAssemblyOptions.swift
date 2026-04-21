import Foundation

/// Policy applied when a switch key is not found in the provided values dictionary.
public enum MissingSwitchValuePolicy: Sendable {
    /// Throw ``DocxConditionalAssemblyError/missingValueForSwitch(key:part:)``.
    case error
    /// Remove the entire switch block from the document.
    case removeBlock
    /// Use the default block if present; otherwise remove the entire switch block.
    case useDefaultIfPresent
}

/// Policy applied when the provided value for a switch key does not match any case.
public enum UnknownCasePolicy: Sendable {
    /// Throw ``DocxConditionalAssemblyError/noMatchingCase(key:value:part:)``.
    case error
    /// Remove the entire switch block from the document.
    case removeBlock
    /// Use the default block if present; otherwise remove the entire switch block.
    case useDefaultIfPresent
}

/// Options that control the behaviour of ``DocxTemplateConditionalAssembler``.
public struct DocxConditionalAssemblyOptions: Sendable {
    /// The parts of the DOCX that will be processed.
    public var scope: DocxProcessingScope

    /// Policy applied when a switch key is absent from the values dictionary.
    public var missingSwitchValuePolicy: MissingSwitchValuePolicy

    /// Policy applied when no case matches the provided value.
    public var unknownCasePolicy: UnknownCasePolicy

    public init(
        scope: DocxProcessingScope = .init(),
        missingSwitchValuePolicy: MissingSwitchValuePolicy = .useDefaultIfPresent,
        unknownCasePolicy: UnknownCasePolicy = .useDefaultIfPresent
    ) {
        self.scope = scope
        self.missingSwitchValuePolicy = missingSwitchValuePolicy
        self.unknownCasePolicy = unknownCasePolicy
    }
}

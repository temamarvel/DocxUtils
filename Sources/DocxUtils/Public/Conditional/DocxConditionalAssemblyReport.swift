import Foundation

/// A single resolved switch block included in a ``DocxConditionalAssemblyReport``.
public struct ResolvedSwitchInfo: Sendable {
    /// The switch key (from `<!switch_start:key!>`).
    public let key: String
    /// The DOCX part in which this switch block was found (e.g. `"word/document.xml"`).
    public let partName: String
    /// The case value that was selected, or `nil` if the default block was used.
    public let selectedCase: String?
    /// Whether the selected content came from the default block.
    public let usedDefault: Bool
    /// Whether the entire block was removed (no match, no default, policy = removeBlock).
    public let blockRemoved: Bool
}

/// A summary of the work performed by ``DocxTemplateConditionalAssembler``.
public struct DocxConditionalAssemblyReport: Sendable {
    /// The DOCX part names that were processed.
    public var processedParts: [String] = []
    /// Details of every resolved switch block.
    public var resolvedSwitches: [ResolvedSwitchInfo] = []
    /// Total number of control-marker paragraphs removed from the document.
    public var removedControlMarkersCount: Int = 0
    /// Total number of block nodes (paragraphs, tables, …) removed because they
    /// belonged to an unselected case or an entirely removed switch block.
    public var removedBlocksCount: Int = 0

    public init() {}
}

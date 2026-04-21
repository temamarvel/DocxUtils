import Foundation

public struct DocxProcessingScope: Sendable {
    public enum PartSelection: Sendable {
        case standard
        case allWordXML
    }

    public var selection: PartSelection
    public var includeFootnotes: Bool
    public var includeEndnotes: Bool
    public var includeComments: Bool
    public var includeFieldInstructionText: Bool

    public init(
        selection: PartSelection = .standard,
        includeFootnotes: Bool = true,
        includeEndnotes: Bool = true,
        includeComments: Bool = true,
        includeFieldInstructionText: Bool = false
    ) {
        self.selection = selection
        self.includeFootnotes = includeFootnotes
        self.includeEndnotes = includeEndnotes
        self.includeComments = includeComments
        self.includeFieldInstructionText = includeFieldInstructionText
    }
}

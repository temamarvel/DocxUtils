import Foundation

/// Examines a single `<w:p>` element and returns the ``TemplateControlToken`` it contains,
/// or `nil` if the paragraph is ordinary content.
///
/// A control-token paragraph must contain *only* the token text (after trimming whitespace).
enum DocxControlTokenScanner {

    // MARK: - Compiled patterns

    private static let switchStartPattern = try! NSRegularExpression(
        pattern: #"^<!switch_start:([A-Za-z0-9_]+)!>$"#)
    private static let switchEndPattern = try! NSRegularExpression(
        pattern: #"^<!switch_end!>$"#)
    private static let caseStartPattern = try! NSRegularExpression(
        pattern: #"^<!case_start:([^!]+)!>$"#)
    private static let caseEndPattern = try! NSRegularExpression(
        pattern: #"^<!case_end!>$"#)
    private static let defaultStartPattern = try! NSRegularExpression(
        pattern: #"^<!default_start!>$"#)
    private static let defaultEndPattern = try! NSRegularExpression(
        pattern: #"^<!default_end!>$"#)

    // MARK: - API

    static func scan(paragraph: XMLElement) -> TemplateControlToken? {
        let projection = ParagraphTextProjection.build(
            from: paragraph,
            includeFieldInstructionText: false
        )
        let text = projection.fullText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return nil }

        let nsRange = NSRange(text.startIndex..., in: text)

        if let match = switchStartPattern.firstMatch(in: text, range: nsRange),
           let keyRange = Range(match.range(at: 1), in: text) {
            return TemplateControlToken(
                kind: .switchStart(key: String(text[keyRange])),
                paragraphElement: paragraph
            )
        }

        if switchEndPattern.firstMatch(in: text, range: nsRange) != nil {
            return TemplateControlToken(kind: .switchEnd, paragraphElement: paragraph)
        }

        if let match = caseStartPattern.firstMatch(in: text, range: nsRange),
           let valRange = Range(match.range(at: 1), in: text) {
            let value = String(text[valRange]).trimmingCharacters(in: .whitespaces)
            return TemplateControlToken(kind: .caseStart(value: value), paragraphElement: paragraph)
        }

        if caseEndPattern.firstMatch(in: text, range: nsRange) != nil {
            return TemplateControlToken(kind: .caseEnd, paragraphElement: paragraph)
        }

        if defaultStartPattern.firstMatch(in: text, range: nsRange) != nil {
            return TemplateControlToken(kind: .defaultStart, paragraphElement: paragraph)
        }

        if defaultEndPattern.firstMatch(in: text, range: nsRange) != nil {
            return TemplateControlToken(kind: .defaultEnd, paragraphElement: paragraph)
        }

        return nil
    }
}

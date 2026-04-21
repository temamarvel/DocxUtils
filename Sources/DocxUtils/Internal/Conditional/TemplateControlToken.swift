import Foundation

/// A single control token found in a standalone paragraph.
struct TemplateControlToken {
    enum Kind {
        case switchStart(key: String)
        case switchEnd
        case caseStart(value: String)
        case caseEnd
        case defaultStart
        case defaultEnd
    }

    let kind: Kind
    /// The `<w:p>` element that contains only this control token.
    let paragraphElement: XMLElement
}

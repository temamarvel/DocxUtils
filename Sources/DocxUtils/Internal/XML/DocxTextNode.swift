import Foundation

enum DocxTextNodeKind {
    case text
    case instrText
}

struct DocxTextNode {
    let element: XMLElement
    let kind: DocxTextNodeKind
    var text: String
    var isDirty: Bool = false
}

enum DocxTextNodeCollector {
    static func collectEditableTextNodes(
        in paragraph: XMLElement,
        includeFieldInstructionText: Bool
    ) -> [DocxTextNode] {
        guard let nodes = try? paragraph.nodes(
            forXPath: ".//*[local-name()='t' or local-name()='instrText']"
        ) as? [XMLElement] else {
            return []
        }

        return nodes.compactMap { element in
            let localName = element.localName ?? element.name ?? ""

            if localName == "instrText", !includeFieldInstructionText {
                return nil
            }

            return DocxTextNode(
                element: element,
                kind: localName == "instrText" ? .instrText : .text,
                text: element.stringValue ?? ""
            )
        }
    }
}

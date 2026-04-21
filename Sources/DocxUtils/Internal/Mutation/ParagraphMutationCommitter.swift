import Foundation

struct ParagraphMutationCommitter {
    static func commitChanges(to nodes: inout [DocxTextNode]) {
        for index in nodes.indices {
            guard nodes[index].isDirty else { continue }

            DocxXMLDocument.setExactText(nodes[index].text, on: nodes[index].element)

            if nodes[index].kind == .text {
                if DocxXMLDocument.needsXMLSpacePreserve(for: nodes[index].text) {
                    DocxXMLDocument.ensureXMLSpacePreserve(on: nodes[index].element)
                }
            }

            nodes[index].isDirty = false
        }
    }
}

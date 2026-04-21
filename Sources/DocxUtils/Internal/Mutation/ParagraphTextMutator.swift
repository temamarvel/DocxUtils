import Foundation

struct ParagraphTextMutator {
    static func applyReplacement(
        nodes: inout [DocxTextNode],
        start: TextLocation,
        end: TextLocation,
        replacement: String
    ) {
        let si = start.nodeIndex
        let ei = end.nodeIndex

        if si == ei {
            let original = nodes[si].text
            let pre = original.prefixCharacters(start.offset)
            let suf = original.suffixCharacters(from: end.offset)
            nodes[si].text = pre + replacement + suf
            nodes[si].isDirty = true
            return
        }

        let first = nodes[si].text
        let last = nodes[ei].text
        let pre = first.prefixCharacters(start.offset)
        let suf = last.suffixCharacters(from: end.offset)

        nodes[si].text = pre + replacement + suf
        nodes[si].isDirty = true

        for index in (si + 1)...ei {
            if !nodes[index].text.isEmpty {
                nodes[index].text = ""
                nodes[index].isDirty = true
            }
        }
    }
}

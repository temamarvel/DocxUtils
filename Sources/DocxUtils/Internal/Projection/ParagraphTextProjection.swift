import Foundation

struct ParagraphTextProjection {
    let paragraphNode: XMLElement
    var textNodes: [DocxTextNode]
    let fullText: String
    let offsetMapper: TextOffsetMapper

    static func build(
        from paragraph: XMLElement,
        includeFieldInstructionText: Bool
    ) -> ParagraphTextProjection {
        let nodes = DocxTextNodeCollector.collectEditableTextNodes(
            in: paragraph,
            includeFieldInstructionText: includeFieldInstructionText
        )
        let fullText = nodes.map(\.text).joined()
        let lengths = nodes.map(\.text.count)
        let mapper = TextOffsetMapper(prefixSums: TextOffsetMapper.computePrefixSums(for: lengths))

        return ParagraphTextProjection(
            paragraphNode: paragraph,
            textNodes: nodes,
            fullText: fullText,
            offsetMapper: mapper
        )
    }
}

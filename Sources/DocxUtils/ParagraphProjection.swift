//
//  ParagraphProjection.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


import Foundation
//import ZIPFoundation

struct ParagraphProjection {
    var nodes: [EditableTextNode]
    let fullText: String
    
    static func build(
        from paragraph: XMLElement,
        includeFieldInstructionText: Bool
    ) -> ParagraphProjection {
        let nodes = DocxXML.collectEditableTextNodes(
            in: paragraph,
            includeFieldInstructionText: includeFieldInstructionText
        )
        
        return ParagraphProjection(
            nodes: nodes,
            fullText: nodes.map(\.text).joined()
        )
    }
}

//
//  EditableTextNode.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


import Foundation

struct EditableTextNode {
    let element: XMLElement
    let kind: EditableTextKind
    var text: String
    var isDirty: Bool = false
}

//
//  DocxPartOptions.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


struct DocxPartOptions: Sendable {
    var includeFootnotes: Bool
    var includeEndnotes: Bool
    var includeComments: Bool
    var includeFieldInstructionText: Bool
    var selection: DocxPartSelection
}

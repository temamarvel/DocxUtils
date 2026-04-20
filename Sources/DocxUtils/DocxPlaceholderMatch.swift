//
//  DocxPlaceholderMatch.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


struct DocxPlaceholderMatch {
    let raw: String
    let key: String
    let range: Range<String.Index>
}

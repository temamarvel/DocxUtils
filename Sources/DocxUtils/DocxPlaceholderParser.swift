//
//  DocxPlaceholderParser.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


import Foundation

enum DocxPlaceholderParser {
    static let regex = try! NSRegularExpression(pattern: #"<\!([A-Za-z0-9_]+)\!>"#)
    
    static func findMatches(in text: String) -> [DocxPlaceholderMatch] {
        let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
        
        return regex.matches(in: text, options: [], range: nsRange).compactMap { match in
            guard
                match.numberOfRanges == 2,
                let fullRange = Range(match.range(at: 0), in: text),
                let keyRange = Range(match.range(at: 1), in: text)
            else {
                return nil
            }
            
            return DocxPlaceholderMatch(
                raw: String(text[fullRange]),
                key: String(text[keyRange]),
                range: fullRange
            )
        }
    }
}

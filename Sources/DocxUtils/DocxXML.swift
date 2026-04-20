//
//  DocxXML.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


import Foundation

enum DocxXML {
    /// Parses DOCX XML data into an `XMLDocument`.
    ///
    /// Apple's `XMLDocument` silently drops whitespace-only text nodes
    /// (e.g. `<w:t xml:space="preserve"> </w:t>`) even with `.nodePreserveAll`.
    /// We work around this by converting whitespace-only content inside `<w:t>`
    /// and `<w:instrText>` elements to `&#x20;` entity references before parsing.
    static func parseDocument(data: Data, partPath: String) throws -> XMLDocument {
        let preprocessed = protectWhitespaceOnlyTextNodes(in: data)
        do {
            return try XMLDocument(data: preprocessed, options: [.nodePreserveAll])
        } catch {
            throw DocxProcessingError.failedToParseXML(part: partPath)
        }
    }
    
    /// Replaces whitespace-only content in `<w:t ...>` and `<w:instrText ...>` with
    /// `&#x20;` / `&#x09;` entity references so `XMLDocument` does not discard them.
    private static func protectWhitespaceOnlyTextNodes(in data: Data) -> Data {
        guard var xmlString = String(data: data, encoding: .utf8) else { return data }
        
        // Pattern: (opening w:t or w:instrText tag)(whitespace-only content)(closing tag)
        let pattern = #"(<(?:\w+:)?(?:t|instrText)\b[^>]*>)([ \t\r\n]+)(</(?:\w+:)?(?:t|instrText)>)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return data }
        
        let ns = xmlString as NSString
        let matches = regex.matches(in: xmlString, range: NSRange(location: 0, length: ns.length))
        
        // Process in reverse to preserve indices
        for match in matches.reversed() {
            guard match.numberOfRanges == 4 else { continue }
            let contentRange = match.range(at: 2)
            let content = ns.substring(with: contentRange)
            
            let escaped = content
                .replacingOccurrences(of: " ", with: "&#x20;")
                .replacingOccurrences(of: "\t", with: "&#x09;")
                .replacingOccurrences(of: "\r", with: "&#xD;")
                .replacingOccurrences(of: "\n", with: "&#xA;")
            
            let startIdx = xmlString.index(xmlString.startIndex, offsetBy: contentRange.location)
            let endIdx = xmlString.index(startIdx, offsetBy: contentRange.length)
            xmlString.replaceSubrange(startIdx..<endIdx, with: escaped)
        }
        
        return xmlString.data(using: .utf8) ?? data
    }
    
    static func findParagraphs(in document: XMLDocument) -> [XMLElement] {
        ((try? document.nodes(forXPath: "//*[local-name()='p']")) as? [XMLElement]) ?? []
    }
    
    static func collectEditableTextNodes(
        in paragraph: XMLElement,
        includeFieldInstructionText: Bool
    ) -> [EditableTextNode] {
        guard let nodes = try? paragraph.nodes(
            forXPath: ".//*[local-name()='t' or local-name()='instrText']"
        ) as? [XMLElement] else {
            return []
        }
        
        return nodes.compactMap { element in
            let localName = element.localName ?? element.name ?? ""
            
            if localName == "instrText", includeFieldInstructionText == false {
                return nil
            }
            
            return EditableTextNode(
                element: element,
                kind: localName == "instrText" ? .instrText : .text,
                text: element.stringValue ?? ""
            )
        }
    }
    
    static func setExactText(_ value: String, on element: XMLElement) {
        for child in element.children ?? [] {
            child.detach()
        }
        
        if !value.isEmpty {
            let textNode = XMLNode.text(withStringValue: value) as! XMLNode
            element.addChild(textNode)
        }
    }
    
    static func ensureXMLSpacePreserve(on element: XMLElement) {
        if let attribute = element.attribute(forName: "xml:space") {
            attribute.stringValue = "preserve"
        } else {
            let attribute = XMLNode.attribute(withName: "xml:space", stringValue: "preserve") as! XMLNode
            element.addAttribute(attribute)
        }
        
    }
    
    static func needsXMLSpacePreserve(for text: String) -> Bool {
        guard !text.isEmpty else { return false }
        if text.first == " " || text.last == " " { return true }
        if text.contains("  ") { return true }
        if text.contains("\t") || text.contains("\n") { return true }
        return false
    }
}

import Foundation

enum DocxXMLDocument {
    static func parse(data: Data, partPath: String) throws -> XMLDocument {
        let preprocessed = protectWhitespaceOnlyTextNodes(in: data)
        do {
            return try XMLDocument(data: preprocessed, options: [.nodePreserveAll])
        } catch {
            throw DocxError.parsePartFailed(path: partPath, underlying: error.localizedDescription)
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

    private static func protectWhitespaceOnlyTextNodes(in data: Data) -> Data {
        guard var xmlString = String(data: data, encoding: .utf8) else { return data }

        let pattern = #"(<(?:\w+:)?(?:t|instrText)\b[^>]*>)([ \t\r\n]+)(</(?:\w+:)?(?:t|instrText)>)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return data }

        let ns = xmlString as NSString
        let matches = regex.matches(in: xmlString, range: NSRange(location: 0, length: ns.length))

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
}

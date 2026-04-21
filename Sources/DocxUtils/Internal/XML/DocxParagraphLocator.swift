import Foundation

enum DocxParagraphLocator {
    static func findParagraphs(in document: XMLDocument) -> [XMLElement] {
        ((try? document.nodes(forXPath: "//*[local-name()='p']")) as? [XMLElement]) ?? []
    }
}

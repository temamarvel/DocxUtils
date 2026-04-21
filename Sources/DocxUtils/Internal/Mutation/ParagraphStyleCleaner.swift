import Foundation

struct ParagraphStyleCleaner {
    let policy: ReplacementStylePolicy

    func cleanAfterReplacement(in nodes: [DocxTextNode], from startIndex: Int, to endIndex: Int) {
        guard policy == .removeHighlightOnly else { return }
        guard startIndex <= endIndex else { return }

        var handledRuns = Set<ObjectIdentifier>()

        for index in startIndex...endIndex {
            guard let run = owningRun(for: nodes[index].element) else { continue }

            let runID = ObjectIdentifier(run)
            guard handledRuns.insert(runID).inserted else { continue }

            clearHighlightAttributes(from: run)
        }
    }

    private func owningRun(for element: XMLElement) -> XMLElement? {
        var current = element.parent
        while let node = current {
            if let el = node as? XMLElement,
               (el.localName ?? el.name ?? "") == "r" {
                return el
            }
            current = node.parent
        }
        return nil
    }

    private func clearHighlightAttributes(from run: XMLElement) {
        let path = "./*[local-name()='rPr']"

        let rPr: XMLElement
        if let existing = ((try? run.nodes(forXPath: path)) as? [XMLElement])?.first {
            rPr = existing
        } else {
            let created = XMLElement(name: "w:rPr")
            run.insertChild(created, at: 0)
            rPr = created
        }

        removeChildren(named: "shd", from: rPr)
        removeChildren(named: "highlight", from: rPr)
    }

    private func removeChildren(named localName: String, from element: XMLElement) {
        for child in (element.children ?? []).reversed() {
            guard let childElement = child as? XMLElement else { continue }
            let childLocalName = childElement.localName ?? childElement.name ?? ""
            if childLocalName == localName {
                child.detach()
            }
        }
    }
}

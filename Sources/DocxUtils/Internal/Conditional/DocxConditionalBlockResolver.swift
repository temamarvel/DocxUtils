import Foundation

/// Resolves all ``ConditionalSwitchBlock`` instances inside one XML document,
/// mutating the XML tree in-place.
struct DocxConditionalBlockResolver {

    let values: [String: String]
    let options: DocxConditionalAssemblyOptions
    let partName: String

    // MARK: - Public entry point

    /// Returns ``ResolvedSwitchInfo`` for every switch block found and processed.
    func resolve(in xmlDocument: XMLDocument) throws -> (
        infos: [ResolvedSwitchInfo],
        removedControlMarkers: Int,
        removedBlocks: Int
    ) {
        // Find all direct container elements (w:body, w:hdr, w:ftr, w:footnotes/footnote, …)
        let containers = findBlockContainers(in: xmlDocument)

        var allInfos: [ResolvedSwitchInfo] = []
        var totalMarkers = 0
        var totalBlocks = 0

        for container in containers {
            let blockNodes = directBlockChildren(of: container)
            let switchBlocks = try DocxConditionalBlockParser.parse(
                blockNodes: blockNodes,
                partName: partName
            )
            for block in switchBlocks.reversed() {
                let (info, markers, blocks) = try resolveSwitch(block)
                allInfos.append(info)
                totalMarkers += markers
                totalBlocks += blocks
            }
        }

        return (allInfos, totalMarkers, totalBlocks)
    }

    // MARK: - Switch resolution

    private func resolveSwitch(_ block: ConditionalSwitchBlock) throws -> (
        ResolvedSwitchInfo, Int, Int
    ) {
        let value = values[block.key]

        // Determine which content nodes to keep (nil = remove entire switch)
        let keepNodes: [XMLElement]?
        var selectedCase: String?
        var usedDefault = false

        if let value {
            if let matchingCase = block.cases.first(where: { $0.value == value }) {
                keepNodes = matchingCase.contentNodes
                selectedCase = value
            } else {
                // No matching case
                switch options.unknownCasePolicy {
                case .error:
                    throw DocxConditionalAssemblyError.noMatchingCase(
                        key: block.key, value: value, part: partName)
                case .removeBlock:
                    keepNodes = nil
                case .useDefaultIfPresent:
                    if let def = block.defaultBlock {
                        keepNodes = def.contentNodes
                        usedDefault = true
                    } else {
                        keepNodes = nil
                    }
                }
            }
        } else {
            // No value for this switch key
            switch options.missingSwitchValuePolicy {
            case .error:
                throw DocxConditionalAssemblyError.missingValueForSwitch(
                    key: block.key, part: partName)
            case .removeBlock:
                keepNodes = nil
            case .useDefaultIfPresent:
                if let def = block.defaultBlock {
                    keepNodes = def.contentNodes
                    usedDefault = true
                } else {
                    keepNodes = nil
                }
            }
        }

        // ---- Mutate the XML tree ----
        var removedBlocks = 0
        var removedMarkers = 0

        // Collect all nodes that belong to this switch (except what we keep).
        // Order of deletion: collect everything between switchStart..switchEnd inclusive,
        // then reinsert kept nodes in place.

        guard let parent = block.switchStartNode.parent as? XMLElement else {
            // Shouldn't happen
            return (
                ResolvedSwitchInfo(
                    key: block.key, partName: partName,
                    selectedCase: selectedCase, usedDefault: usedDefault,
                    blockRemoved: keepNodes == nil
                ),
                0, 0
            )
        }

        // Collect indices of all nodes belonging to this switch block in parent.
        let allSiblings = parent.children?.compactMap({ $0 as? XMLElement }) ?? []

        // Identify the range [switchStart … switchEnd] among siblings
        guard
            let startIdx = allSiblings.firstIndex(where: { $0 === block.switchStartNode }),
            let endIdx   = allSiblings.firstIndex(where: { $0 === block.switchEndNode }),
            startIdx <= endIdx
        else {
            return (
                ResolvedSwitchInfo(
                    key: block.key, partName: partName,
                    selectedCase: selectedCase, usedDefault: usedDefault,
                    blockRemoved: keepNodes == nil
                ),
                0, 0
            )
        }

        let nodesInSwitch = Array(allSiblings[startIdx...endIdx])

        // Identify content nodes to remove
        let keepSet: Set<ObjectIdentifier> = Set(
            (keepNodes ?? []).map { ObjectIdentifier($0) }
        )

        // We'll remove all nodes in the switch range from the parent,
        // then reinsert kept nodes at the same position.
        let insertionIndex = startIdx

        // Detach all nodes in the switch block
        for node in nodesInSwitch {
            let ident = ObjectIdentifier(node)
            let isControlMarker = isMarker(node, in: block)
            if isControlMarker {
                removedMarkers += 1
            } else if !keepSet.contains(ident) {
                removedBlocks += 1
            }
            node.detach()
        }

        // Reinsert kept nodes at the original position (in original order)
        if let keepNodes, !keepNodes.isEmpty {
            // parent.children might have shifted; use XMLElement's index-based insert
            let currentChildren = parent.children ?? []
            let insertAt = min(insertionIndex, currentChildren.count)
            for (offset, node) in keepNodes.enumerated() {
                parent.insertChild(node, at: insertAt + offset)
            }
        }

        let info = ResolvedSwitchInfo(
            key: block.key,
            partName: partName,
            selectedCase: selectedCase,
            usedDefault: usedDefault,
            blockRemoved: keepNodes == nil
        )
        return (info, removedMarkers, removedBlocks)
    }

    // MARK: - Helpers

    private func isMarker(_ node: XMLElement, in block: ConditionalSwitchBlock) -> Bool {
        let ident = ObjectIdentifier(node)
        if ident == ObjectIdentifier(block.switchStartNode) { return true }
        if ident == ObjectIdentifier(block.switchEndNode)   { return true }
        for c in block.cases {
            if ident == ObjectIdentifier(c.caseStartNode) { return true }
            if ident == ObjectIdentifier(c.caseEndNode)   { return true }
        }
        if let def = block.defaultBlock {
            if ident == ObjectIdentifier(def.defaultStartNode) { return true }
            if ident == ObjectIdentifier(def.defaultEndNode)   { return true }
        }
        return false
    }

    /// Returns all elements that are direct block-level containers recognised by DOCX.
    private func findBlockContainers(in xmlDocument: XMLDocument) -> [XMLElement] {
        let xpaths = [
            "//*[local-name()='body']",
            "//*[local-name()='hdr']",
            "//*[local-name()='ftr']",
            "//*[local-name()='footnote']",
            "//*[local-name()='endnote']",
            "//*[local-name()='comment']",
        ]
        var result: [XMLElement] = []
        for xpath in xpaths {
            let nodes = (try? xmlDocument.nodes(forXPath: xpath)) as? [XMLElement] ?? []
            result += nodes
        }
        return result
    }

    /// Returns the direct child elements of a container that are block-level nodes.
    private func directBlockChildren(of element: XMLElement) -> [XMLElement] {
        (element.children ?? []).compactMap { $0 as? XMLElement }
    }
}

import Foundation

// MARK: - Block models

struct ConditionalCaseBlock {
    let value: String
    /// Block-level XML nodes (w:p, w:tbl, …) that form the case content.
    let contentNodes: [XMLElement]
    let caseStartNode: XMLElement
    let caseEndNode: XMLElement
}

struct ConditionalDefaultBlock {
    let contentNodes: [XMLElement]
    let defaultStartNode: XMLElement
    let defaultEndNode: XMLElement
}

struct ConditionalSwitchBlock {
    let key: String
    let cases: [ConditionalCaseBlock]
    let defaultBlock: ConditionalDefaultBlock?
    let switchStartNode: XMLElement
    let switchEndNode: XMLElement
}

// MARK: - Parser

/// Builds a list of ``ConditionalSwitchBlock`` values from the direct block-level children
/// (``w:p``, ``w:tbl``, …) of a single DOCX container element (``w:body``, ``w:hdr``, ``w:ftr``).
enum DocxConditionalBlockParser {
    
    static func parse(
        blockNodes: [XMLElement],
        partName: String
    ) throws -> [ConditionalSwitchBlock] {
        // Pre-scan every node for control tokens.
        let tokens: [Int: TemplateControlToken] = Dictionary(
            uniqueKeysWithValues: blockNodes.enumerated().compactMap { index, node in
                guard node.localName == "p",
                      let token = DocxControlTokenScanner.scan(paragraph: node)
                else { return nil }
                return (index, token)
            }
        )
        
        var result: [ConditionalSwitchBlock] = []
        var i = 0
        
        while i < blockNodes.count {
            guard let token = tokens[i] else { i += 1; continue }
            
            switch token.kind {
                case .switchStart(let key):
                    let (block, next) = try parseSwitchBlock(
                        key: key,
                        switchStartNode: blockNodes[i],
                        startIndex: i,
                        blockNodes: blockNodes,
                        tokens: tokens,
                        partName: partName
                    )
                    result.append(block)
                    i = next
                    
                case .switchEnd:
                    throw DocxConditionalAssemblyError.switchEndWithoutStart(part: partName)
                case .caseStart(let value):
                    throw DocxConditionalAssemblyError.caseStartOutsideSwitch(value: value, part: partName)
                case .caseEnd:
                    throw DocxConditionalAssemblyError.caseEndWithoutStart(part: partName)
                case .defaultStart:
                    throw DocxConditionalAssemblyError.defaultStartOutsideSwitch(part: partName)
                case .defaultEnd:
                    throw DocxConditionalAssemblyError.defaultEndWithoutStart(part: partName)
            }
        }
        
        return result
    }
    
    // MARK: - Switch
    
    private static func parseSwitchBlock(
        key: String,
        switchStartNode: XMLElement,
        startIndex: Int,
        blockNodes: [XMLElement],
        tokens: [Int: TemplateControlToken],
        partName: String
    ) throws -> (ConditionalSwitchBlock, Int) {
        var cases: [ConditionalCaseBlock] = []
        var defaultBlock: ConditionalDefaultBlock?
        var seenCaseValues = Set<String>()
        var i = startIndex + 1
        
        while i < blockNodes.count {
            guard let token = tokens[i] else {
                // Loose content between switch_start and first case_start — skip silently.
                i += 1
                continue
            }
            
            switch token.kind {
                case .switchEnd:
                    return (
                        ConditionalSwitchBlock(
                            key: key,
                            cases: cases,
                            defaultBlock: defaultBlock,
                            switchStartNode: switchStartNode,
                            switchEndNode: blockNodes[i]
                        ),
                        i + 1
                    )
                    
                case .caseStart(let value):
                    if seenCaseValues.contains(value) {
                        throw DocxConditionalAssemblyError.duplicateCaseValue(
                            key: key, value: value, part: partName)
                    }
                    seenCaseValues.insert(value)
                    let (caseBlock, next) = try parseCaseBlock(
                        value: value,
                        caseStartNode: blockNodes[i],
                        startIndex: i,
                        blockNodes: blockNodes,
                        tokens: tokens,
                        partName: partName
                    )
                    cases.append(caseBlock)
                    i = next
                    
                case .defaultStart:
                    if defaultBlock != nil {
                        throw DocxConditionalAssemblyError.duplicateDefault(part: partName)
                    }
                    let (def, next) = try parseDefaultBlock(
                        defaultStartNode: blockNodes[i],
                        startIndex: i,
                        blockNodes: blockNodes,
                        tokens: tokens,
                        partName: partName
                    )
                    defaultBlock = def
                    i = next
                    
                case .switchStart:
                    throw DocxConditionalAssemblyError.nestedSwitchNotSupported(part: partName)
                    
                case .caseEnd:
                    throw DocxConditionalAssemblyError.caseEndWithoutStart(part: partName)
                case .defaultEnd:
                    throw DocxConditionalAssemblyError.defaultEndWithoutStart(part: partName)
            }
        }
        
        throw DocxConditionalAssemblyError.switchStartWithoutEnd(key: key, part: partName)
    }
    
    // MARK: - Case
    
    private static func parseCaseBlock(
        value: String,
        caseStartNode: XMLElement,
        startIndex: Int,
        blockNodes: [XMLElement],
        tokens: [Int: TemplateControlToken],
        partName: String
    ) throws -> (ConditionalCaseBlock, Int) {
        var contentNodes: [XMLElement] = []
        var i = startIndex + 1
        
        while i < blockNodes.count {
            if let token = tokens[i] {
                switch token.kind {
                    case .caseEnd:
                        return (
                            ConditionalCaseBlock(
                                value: value,
                                contentNodes: contentNodes,
                                caseStartNode: caseStartNode,
                                caseEndNode: blockNodes[i]
                            ),
                            i + 1
                        )
                    default:
                        // Any other control token inside a case is an error.
                        throw DocxConditionalAssemblyError.caseStartWithoutEnd(
                            value: value, part: partName)
                }
            } else {
                contentNodes.append(blockNodes[i])
            }
            i += 1
        }
        
        throw DocxConditionalAssemblyError.caseStartWithoutEnd(value: value, part: partName)
    }
    
    // MARK: - Default
    
    private static func parseDefaultBlock(
        defaultStartNode: XMLElement,
        startIndex: Int,
        blockNodes: [XMLElement],
        tokens: [Int: TemplateControlToken],
        partName: String
    ) throws -> (ConditionalDefaultBlock, Int) {
        var contentNodes: [XMLElement] = []
        var i = startIndex + 1
        
        while i < blockNodes.count {
            if let token = tokens[i] {
                switch token.kind {
                    case .defaultEnd:
                        return (
                            ConditionalDefaultBlock(
                                contentNodes: contentNodes,
                                defaultStartNode: defaultStartNode,
                                defaultEndNode: blockNodes[i]
                            ),
                            i + 1
                        )
                    default:
                        throw DocxConditionalAssemblyError.defaultStartWithoutEnd(part: partName)
                }
            } else {
                contentNodes.append(blockNodes[i])
            }
            i += 1
        }
        
        throw DocxConditionalAssemblyError.defaultStartWithoutEnd(part: partName)
    }
}

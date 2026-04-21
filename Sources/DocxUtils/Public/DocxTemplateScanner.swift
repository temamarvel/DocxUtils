import Foundation

public struct DocxTemplateScanner: Sendable {
    public init() {}

    public func scan(
        templateURL: URL,
        scope: DocxProcessingScope = .init(),
        pattern: DocxPlaceholderPattern = .init()
    ) throws -> DocxScanReport {
        let processor = DocxPartProcessor(scope: scope, partFailurePolicy: .continueAndReport)
        let matcher = DocxPlaceholderMatcher(pattern: pattern)

        var report = DocxScanReport()

        let issues = try processor.processPartsInMemory(templateURL: templateURL) { context in
            let paragraphs = DocxParagraphLocator.findParagraphs(in: context.xmlDocument)

            var partHasKeys = false

            for paragraph in paragraphs {
                let projection = ParagraphTextProjection.build(
                    from: paragraph,
                    includeFieldInstructionText: scope.includeFieldInstructionText
                )
                guard !projection.fullText.isEmpty else { continue }

                let matches = matcher.findMatches(in: projection.fullText)

                for match in matches {
                    if report.foundKeys.insert(match.key).inserted {
                        report.orderedKeys.append(match.key)
                    }
                    report.occurrences[match.key, default: 0] += 1
                    report.partsByKey[match.key, default: []].insert(context.path)
                    partHasKeys = true
                }
            }

            if partHasKeys {
                report.processedParts.append(context.path)
            }
        }

        report.issues = issues
        return report
    }

    public func scanKeys(
        templateURL: URL,
        scope: DocxProcessingScope = .init(),
        pattern: DocxPlaceholderPattern = .init()
    ) throws -> [String] {
        try scan(templateURL: templateURL, scope: scope, pattern: pattern).orderedKeys
    }
}

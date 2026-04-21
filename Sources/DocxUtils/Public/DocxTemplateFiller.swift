import Foundation

public struct DocxTemplateFiller: Sendable {
    public init() {}

    public func fill(
        templateURL: URL,
        outputURL: URL,
        values: [String: String],
        options: DocxFillOptions = .init()
    ) throws -> DocxFillReport {
        let processor = DocxPartProcessor(
            scope: options.scope,
            partFailurePolicy: options.partFailurePolicy
        )
        let matcher = DocxPlaceholderMatcher(pattern: options.pattern)
        let resolver = DocxPlaceholderResolver(
            values: values,
            missingKeyPolicy: options.missingKeyPolicy
        )
        let styleCleaner = ParagraphStyleCleaner(policy: options.replacementStylePolicy)

        var report = DocxFillReport()

        let issues = try processor.processPartsOnDisk(
            templateURL: templateURL,
            outputURL: outputURL
        ) { partPath, partURL in
            let data: Data
            do {
                data = try Data(contentsOf: partURL)
            } catch {
                throw DocxError.readPartFailed(path: partPath, underlying: error.localizedDescription)
            }

            let document = try DocxXMLDocument.parse(data: data, partPath: partPath)
            let paragraphs = DocxParagraphLocator.findParagraphs(in: document)

            var didChange = false

            for paragraph in paragraphs {
                var projection = ParagraphTextProjection.build(
                    from: paragraph,
                    includeFieldInstructionText: options.scope.includeFieldInstructionText
                )
                guard !projection.textNodes.isEmpty else { continue }

                let matches = matcher.findMatches(in: projection.fullText)
                guard !matches.isEmpty else { continue }

                for match in matches.reversed() {
                    report.foundKeys.insert(match.key)

                    let resolution = resolver.resolve(key: match.key)

                    let replacement: String?
                    switch resolution {
                    case .replace(let value):
                        replacement = value
                        report.replacedKeys.insert(match.key)
                    case .keepOriginal:
                        replacement = nil
                    case .replaceWithEmptyString:
                        replacement = ""
                        report.replacedKeys.insert(match.key)
                    case .missingRequired(let key):
                        report.missingKeys.insert(key)
                        replacement = nil
                    }

                    guard let replacement else { continue }

                    guard
                        let start = projection.offsetMapper.locateStart(
                            position: match.fullRange.lowerBound,
                            in: projection.fullText
                        ),
                        let end = projection.offsetMapper.locateEnd(
                            position: match.fullRange.upperBound,
                            in: projection.fullText
                        )
                    else { continue }

                    ParagraphTextMutator.applyReplacement(
                        nodes: &projection.textNodes,
                        start: start,
                        end: end,
                        replacement: replacement
                    )
                    styleCleaner.cleanAfterReplacement(
                        in: projection.textNodes,
                        from: start.nodeIndex,
                        to: end.nodeIndex
                    )
                    report.replacementsCount += 1
                    didChange = true
                }

                if didChange {
                    ParagraphMutationCommitter.commitChanges(to: &projection.textNodes)
                }
            }

            if didChange {
                report.processedParts.append(partPath)
                let outData = document.xmlData(options: [.nodePreserveAll])
                do {
                    try outData.write(to: partURL, options: [.atomic])
                } catch {
                    throw DocxError.writePartFailed(path: partPath, underlying: error.localizedDescription)
                }
            }
        }

        report.issues = issues

        // Check missing keys after all parts processed
        if options.missingKeyPolicy == .error, !report.missingKeys.isEmpty {
            throw DocxError.missingPlaceholderValues(report.missingKeys)
        }

        return report
    }
}

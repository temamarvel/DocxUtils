import Foundation

/// Performs conditional block assembly of a DOCX template.
///
/// The assembler recognises the following control tags (each must appear in a
/// **standalone paragraph** — a paragraph whose entire text is the tag):
///
/// ```
/// <!switch_start:contract_type!>
/// <!case_start:sale!>
/// … paragraphs / tables for the "sale" case …
/// <!case_end!>
/// <!case_start:service!>
/// … paragraphs / tables for the "service" case …
/// <!case_end!>
/// <!default_start!>
/// … fallback content …
/// <!default_end!>
/// <!switch_end!>
/// ```
///
/// The assembler reads the template from `templateURL`, resolves all switch
/// blocks according to `values`, and writes the resulting DOCX to `outputURL`.
/// Run this **before** ``DocxTemplateFiller`` so that placeholder replacement
/// only sees the final document content.
public final class DocxTemplateConditionalAssembler: Sendable {

    public init() {}

    /// Resolve all conditional blocks in `templateURL` and write the result to `outputURL`.
    ///
    /// - Parameters:
    ///   - templateURL: Source DOCX template file.
    ///   - outputURL:   Destination for the assembled DOCX. May be the same file.
    ///   - values:      Dictionary mapping switch keys to their selected values.
    ///   - options:     Assembly options (scope, policies, …).
    /// - Returns: A ``DocxConditionalAssemblyReport`` describing what was done.
    @discardableResult
    public func assemble(
        templateURL: URL,
        outputURL: URL,
        values: [String: String],
        options: DocxConditionalAssemblyOptions = .init()
    ) throws -> DocxConditionalAssemblyReport {
        let processor = DocxPartProcessor(
            scope: options.scope,
            partFailurePolicy: .failFast
        )

        var report = DocxConditionalAssemblyReport()

        _ = try processor.processPartsOnDisk(
            templateURL: templateURL,
            outputURL: outputURL
        ) { partPath, partURL in
            let data: Data
            do {
                data = try Data(contentsOf: partURL)
            } catch {
                throw DocxError.readPartFailed(
                    path: partPath,
                    underlying: error.localizedDescription
                )
            }

            let xmlDocument = try DocxXMLDocument.parse(data: data, partPath: partPath)

            let resolver = DocxConditionalBlockResolver(
                values: values,
                options: options,
                partName: partPath
            )
            let (infos, markers, blocks) = try resolver.resolve(in: xmlDocument)

            guard !infos.isEmpty else { return }

            // Serialise the mutated document back to disk.
            let outputData = xmlDocument.xmlData(options: [.nodePreserveAll])
            do {
                try outputData.write(to: partURL)
            } catch {
                throw DocxError.writePartFailed(
                    path: partPath,
                    underlying: error.localizedDescription
                )
            }

            report.processedParts.append(partPath)
            report.resolvedSwitches.append(contentsOf: infos)
            report.removedControlMarkersCount += markers
            report.removedBlocksCount += blocks
        }

        return report
    }
}

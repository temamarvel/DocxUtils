import Foundation

struct DocxPartProcessor {
    let scope: DocxProcessingScope
    let partFailurePolicy: PartFailurePolicy

    init(scope: DocxProcessingScope, partFailurePolicy: PartFailurePolicy = .failFast) {
        self.scope = scope
        self.partFailurePolicy = partFailurePolicy
    }

    /// Process parts from an archive by reading them in memory (for scan).
    func processPartsInMemory(
        templateURL: URL,
        body: (DocxPartContext) throws -> Void
    ) throws -> [DocxProcessingIssue] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: templateURL.path) else {
            throw DocxError.fileNotFound(templateURL)
        }

        let reader = try DocxPackageReader(url: templateURL)
        let allPaths = reader.allEntryPaths()
        let partPaths = DocxPartLocator.locatePaths(in: allPaths, scope: scope)

        guard partPaths.contains("word/document.xml") else {
            throw DocxError.missingRequiredPart("word/document.xml")
        }

        var issues: [DocxProcessingIssue] = []

        for partPath in partPaths {
            do {
                let data = try reader.readData(at: partPath)
                let document = try DocxXMLDocument.parse(data: data, partPath: partPath)
                let context = DocxPartContext(path: partPath, xmlDocument: document)
                try body(context)
            } catch {
                let issue = DocxProcessingIssue(
                    partPath: partPath,
                    operation: .parse,
                    message: error.localizedDescription
                )
                switch partFailurePolicy {
                case .failFast:
                    throw error
                case .collectAndThrow:
                    issues.append(issue)
                case .continueAndReport:
                    issues.append(issue)
                }
            }
        }

        if partFailurePolicy == .collectAndThrow, !issues.isEmpty {
            throw DocxError.partialProcessing(issues)
        }

        return issues
    }

    /// Process parts on disk (for fill — extract, mutate, repack).
    func processPartsOnDisk(
        templateURL: URL,
        outputURL: URL,
        body: (String, URL) throws -> Void
    ) throws -> [DocxProcessingIssue] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: templateURL.path) else {
            throw DocxError.fileNotFound(templateURL)
        }

        let reader = try DocxPackageReader(url: templateURL)

        let tempDir = fm.temporaryDirectory
            .appendingPathComponent("docxutils-\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        defer {
            try? fm.removeItem(at: tempDir)
        }

        try DocxPackageExtractor.extractSafely(from: reader.archive, to: tempDir)

        let partURLs = try DocxPartLocator.locateURLs(root: tempDir, scope: scope)
        var issues: [DocxProcessingIssue] = []

        for url in partURLs {
            let rel = DocxPartLocator.relativePath(of: url, under: tempDir)

            do {
                try body(rel, url)
            } catch {
                let issue = DocxProcessingIssue(
                    partPath: rel,
                    operation: .mutate,
                    message: error.localizedDescription
                )
                switch partFailurePolicy {
                case .failFast:
                    throw error
                case .collectAndThrow:
                    issues.append(issue)
                case .continueAndReport:
                    issues.append(issue)
                }
            }
        }

        if partFailurePolicy == .collectAndThrow, !issues.isEmpty {
            throw DocxError.partialProcessing(issues)
        }

        try DocxPackageWriter.repack(from: tempDir, to: outputURL)

        return issues
    }
}

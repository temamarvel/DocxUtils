import Foundation

struct DocxPartLocator {
    static func locatePaths(in allPaths: [String], scope: DocxProcessingScope) -> [String] {
        switch scope.selection {
        case .standard:
            var result: [String] = []

            if allPaths.contains("word/document.xml") {
                result.append("word/document.xml")
            }

            result += allPaths
                .filter { $0.hasPrefix("word/header") && $0.hasSuffix(".xml") }
                .sorted()

            result += allPaths
                .filter { $0.hasPrefix("word/footer") && $0.hasSuffix(".xml") }
                .sorted()

            if scope.includeFootnotes, allPaths.contains("word/footnotes.xml") {
                result.append("word/footnotes.xml")
            }

            if scope.includeEndnotes, allPaths.contains("word/endnotes.xml") {
                result.append("word/endnotes.xml")
            }

            if scope.includeComments, allPaths.contains("word/comments.xml") {
                result.append("word/comments.xml")
            }

            return result

        case .allWordXML:
            return allPaths
                .filter { $0.hasPrefix("word/") && $0.hasSuffix(".xml") && !$0.hasSuffix(".rels") }
                .sorted()
        }
    }

    static func locateURLs(root: URL, scope: DocxProcessingScope) throws -> [URL] {
        let fileManager = FileManager.default
        let mainDoc = root.appendingPathComponent("word/document.xml")

        guard fileManager.fileExists(atPath: mainDoc.path) else {
            throw DocxError.missingRequiredPart("word/document.xml")
        }

        switch scope.selection {
        case .standard:
            var urls: [URL] = [mainDoc]
            let wordDir = root.appendingPathComponent("word", isDirectory: true)

            let contents = try fileManager.contentsOfDirectory(
                at: wordDir,
                includingPropertiesForKeys: nil
            )

            urls += contents
                .filter { $0.lastPathComponent.hasPrefix("header") && $0.pathExtension.lowercased() == "xml" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            urls += contents
                .filter { $0.lastPathComponent.hasPrefix("footer") && $0.pathExtension.lowercased() == "xml" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }

            if scope.includeFootnotes {
                let url = wordDir.appendingPathComponent("footnotes.xml")
                if fileManager.fileExists(atPath: url.path) { urls.append(url) }
            }

            if scope.includeEndnotes {
                let url = wordDir.appendingPathComponent("endnotes.xml")
                if fileManager.fileExists(atPath: url.path) { urls.append(url) }
            }

            if scope.includeComments {
                let url = wordDir.appendingPathComponent("comments.xml")
                if fileManager.fileExists(atPath: url.path) { urls.append(url) }
            }

            return urls

        case .allWordXML:
            let wordDir = root.appendingPathComponent("word", isDirectory: true)
            let enumerator = fileManager.enumerator(
                at: wordDir,
                includingPropertiesForKeys: nil
            )

            var urls: [URL] = []

            while let url = enumerator?.nextObject() as? URL {
                guard url.pathExtension.lowercased() == "xml" else { continue }
                guard !url.lastPathComponent.hasSuffix(".rels") else { continue }
                urls.append(url)
            }

            return urls.sorted { relativePath(of: $0, under: root) < relativePath(of: $1, under: root) }
        }
    }

    static func relativePath(of url: URL, under root: URL) -> String {
        var path = url.standardizedFileURL.path
        let rootPath = root.standardizedFileURL.path
        if path.hasPrefix(rootPath + "/") {
            path.removeFirst(rootPath.count + 1)
        }
        return path
    }
}

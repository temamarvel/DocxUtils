import Foundation
import ZIPFoundation

struct DocxPackageExtractor {
    static func extractSafely(from archive: Archive, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        let basePath = destinationURL.standardizedFileURL.path

        for entry in archive {
            let entryPath = entry.path

            if entryPath.contains("..") || entryPath.hasPrefix("/") || entryPath.hasPrefix("\\") {
                throw DocxError.unsafeArchiveEntry(entryPath)
            }

            let outputURL = destinationURL.appendingPathComponent(entryPath)
            let standardizedOutputPath = outputURL.standardizedFileURL.path

            guard standardizedOutputPath == basePath || standardizedOutputPath.hasPrefix(basePath + "/") else {
                throw DocxError.unsafeArchiveEntry(entryPath)
            }

            try fileManager.createDirectory(
                at: outputURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )

            switch entry.type {
            case .directory:
                try fileManager.createDirectory(at: outputURL, withIntermediateDirectories: true)
            default:
                _ = try archive.extract(entry, to: outputURL)
            }
        }
    }
}

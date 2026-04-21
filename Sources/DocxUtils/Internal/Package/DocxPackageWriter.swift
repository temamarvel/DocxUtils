import Foundation
import ZIPFoundation

struct DocxPackageWriter {
    static func repack(from directoryURL: URL, to outputURL: URL) throws {
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: outputURL.path) {
            try fileManager.removeItem(at: outputURL)
        }
        
        let archive: Archive
        do {
            archive = try Archive(url: outputURL, accessMode: .create)
        } catch {
            throw DocxError.cannotCreateOutputArchive(outputURL)
        }
        
        let basePath = directoryURL.standardizedFileURL.path
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if values.isDirectory == true { continue }
            
            var relativePath = fileURL.standardizedFileURL.path
            if relativePath.hasPrefix(basePath + "/") {
                relativePath.removeFirst(basePath.count + 1)
            }
            
            try archive.addEntry(
                with: relativePath,
                fileURL: fileURL,
                compressionMethod: .deflate
            )
        }
    }
}

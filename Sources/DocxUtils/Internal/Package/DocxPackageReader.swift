import Foundation
import ZIPFoundation

struct DocxPackageReader {
    let archive: Archive
    
    init(url: URL) throws {
        do {
            self.archive = try Archive(url: url, accessMode: .read)
        } catch {
            throw DocxError.invalidArchive(url)
        }
    }
    
    func allEntryPaths() -> [String] {
        archive.map(\.path)
    }
    
    func readData(at path: String) throws -> Data {
        guard let entry = archive[path] else {
            throw DocxError.readPartFailed(path: path, underlying: "Entry not found")
        }
        var data = Data()
        _ = try archive.extract(entry) { chunk in
            data.append(chunk)
        }
        return data
    }
}

import Foundation

public enum DocxError: LocalizedError, Sendable {
    case fileNotFound(URL)
    case invalidArchive(URL)
    case cannotCreateOutputArchive(URL)
    case unsafeArchiveEntry(String)
    case missingRequiredPart(String)
    case readPartFailed(path: String, underlying: String)
    case parsePartFailed(path: String, underlying: String)
    case writePartFailed(path: String, underlying: String)
    case missingPlaceholderValues(Set<String>)
    case partialProcessing([DocxProcessingIssue])

    public var errorDescription: String? {
        switch self {
        case .fileNotFound(let url):
            return "DOCX file not found: \(url.path)"
        case .invalidArchive(let url):
            return "File is not a valid DOCX archive: \(url.path)"
        case .cannotCreateOutputArchive(let url):
            return "Cannot create output DOCX archive at: \(url.path)"
        case .unsafeArchiveEntry(let path):
            return "Unsafe ZIP entry path detected: \(path)"
        case .missingRequiredPart(let part):
            return "DOCX does not contain required part: \(part)"
        case .readPartFailed(let path, let underlying):
            return "Failed to read XML part \(path): \(underlying)"
        case .parsePartFailed(let path, let underlying):
            return "Failed to parse XML part \(path): \(underlying)"
        case .writePartFailed(let path, let underlying):
            return "Failed to write XML part \(path): \(underlying)"
        case .missingPlaceholderValues(let keys):
            return "Missing values for placeholders: \(keys.sorted().joined(separator: ", "))"
        case .partialProcessing(let issues):
            return "Partial processing completed with \(issues.count) issue(s)."
        }
    }
}

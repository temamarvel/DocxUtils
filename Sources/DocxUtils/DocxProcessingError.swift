//
//  DocxProcessingError.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


import Foundation

public enum DocxProcessingError: LocalizedError {
    case fileNotFound(URL)
    case invalidDocx(URL)
    case missingMainDocumentXML
    case cannotCreateOutputArchive(URL)
    case failedToReadXML(part: String)
    case failedToParseXML(part: String)
    case failedToWriteXML(part: String)
    case missingReplacementValues([String])
    case zipSlipDetected(String)
    
    public var errorDescription: String? {
        switch self {
            case .fileNotFound(let url):
                return "DOCX file not found: \(url.path)"
            case .invalidDocx(let url):
                return "File is not a valid DOCX archive: \(url.path)"
            case .missingMainDocumentXML:
                return "DOCX does not contain word/document.xml"
            case .cannotCreateOutputArchive(let url):
                return "Cannot create output DOCX archive at: \(url.path)"
            case .failedToReadXML(let part):
                return "Failed to read XML part: \(part)"
            case .failedToParseXML(let part):
                return "Failed to parse XML part: \(part)"
            case .failedToWriteXML(let part):
                return "Failed to write XML part: \(part)"
            case .missingReplacementValues(let keys):
                return "Missing values for placeholders: \(keys.joined(separator: ", "))"
            case .zipSlipDetected(let entryPath):
                return "Unsafe ZIP entry path detected: \(entryPath)"
        }
    }
}

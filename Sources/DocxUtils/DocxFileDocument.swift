//
//  DocxFileDocument.swift
//  DocxUtils
//
//  Created by Артем Денисов on 21.04.2026.
//


import SwiftUI
import UniformTypeIdentifiers

public struct DocxFileDocument: FileDocument {
    // Для exporter важнее writableContentTypes
    public static var writableContentTypes: [UTType] { [.docxSafe] }
    public static var readableContentTypes: [UTType] { [.docxSafe, .data] } // можно и так
    
    var data: Data
    
    init(fileURL: URL) throws {
        self.data = try Data(contentsOf: fileURL)
    }
    
    public init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }
    
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

extension UTType {
    static var docxSafe: UTType {
        UTType(filenameExtension: "docx")
        ?? UTType("org.openxmlformats.wordprocessingml.document")
        ?? .data
    }
}

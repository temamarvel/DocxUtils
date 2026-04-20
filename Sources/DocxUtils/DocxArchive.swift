//
//  DocxArchive.swift
//  DocxUtils
//
//  Created by Артем Денисов on 20.04.2026.
//


import Foundation
import ZIPFoundation

enum DocxArchive {
    static func openForRead(_ url: URL) throws -> Archive {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw DocxProcessingError.invalidDocx(url)
        }
        return archive
    }
    
    static func openForCreate(_ url: URL) throws -> Archive {
        guard let archive = Archive(url: url, accessMode: .create) else {
            throw DocxProcessingError.cannotCreateOutputArchive(url)
        }
        return archive
    }
    
    static func extractEntryData(from entry: Entry, in archive: Archive) throws -> Data {
        var data = Data()
        _ = try archive.extract(entry) { chunk in
            data.append(chunk)
        }
        return data
    }
    
    static func locatePartPaths(in archive: Archive, options: DocxPartOptions) -> [String] {
        let allPaths = archive.map(\.path)
        
        switch options.selection {
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
                
                if options.includeFootnotes, allPaths.contains("word/footnotes.xml") {
                    result.append("word/footnotes.xml")
                }
                
                if options.includeEndnotes, allPaths.contains("word/endnotes.xml") {
                    result.append("word/endnotes.xml")
                }
                
                if options.includeComments, allPaths.contains("word/comments.xml") {
                    result.append("word/comments.xml")
                }
                
                return result
                
            case .allWordXML:
                return allPaths
                    .filter { $0.hasPrefix("word/") && $0.hasSuffix(".xml") && !$0.hasSuffix(".rels") }
                    .sorted()
        }
    }
    
    static func extractAllSafely(from archive: Archive, to destinationURL: URL) throws {
        let fileManager = FileManager.default
        let basePath = destinationURL.standardizedFileURL.path
        
        for entry in archive {
            let entryPath = entry.path
            
            if entryPath.contains("..") || entryPath.hasPrefix("/") || entryPath.hasPrefix("\\") {
                throw DocxProcessingError.zipSlipDetected(entryPath)
            }
            
            let outputURL = destinationURL.appendingPathComponent(entryPath)
            let standardizedOutputPath = outputURL.standardizedFileURL.path
            
            guard standardizedOutputPath == basePath || standardizedOutputPath.hasPrefix(basePath + "/") else {
                throw DocxProcessingError.zipSlipDetected(entryPath)
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
    
    static func addDirectoryContents(
        from directoryURL: URL,
        to archive: Archive
    ) throws {
        let fileManager = FileManager.default
        let basePath = directoryURL.standardizedFileURL.path
        
        guard let enumerator = fileManager.enumerator(
            at: directoryURL,
            includingPropertiesForKeys: [.isDirectoryKey]
        ) else {
            return
        }
        
        for case let fileURL as URL in enumerator {
            let values = try fileURL.resourceValues(forKeys: [.isDirectoryKey])
            if values.isDirectory == true {
                continue
            }
            
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
    
    static func locatePartURLs(
        root: URL,
        options: DocxPartOptions
    ) throws -> [URL] {
        let fileManager = FileManager.default
        let mainDoc = root.appendingPathComponent("word/document.xml")
        
        guard fileManager.fileExists(atPath: mainDoc.path) else {
            throw DocxProcessingError.missingMainDocumentXML
        }
        
        switch options.selection {
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
                
                if options.includeFootnotes {
                    let url = wordDir.appendingPathComponent("footnotes.xml")
                    if fileManager.fileExists(atPath: url.path) { urls.append(url) }
                }
                
                if options.includeEndnotes {
                    let url = wordDir.appendingPathComponent("endnotes.xml")
                    if fileManager.fileExists(atPath: url.path) { urls.append(url) }
                }
                
                if options.includeComments {
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

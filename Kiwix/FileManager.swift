//
//  FileManager.swift
//  Kiwix
//
//  Created by Chris Li on 3/28/16.
//  Copyright © 2016 Chris. All rights reserved.
//

class FileManager {
    
    // MARK: - Path Utilities
    
    class var docDirPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths.first!
    }
    
    class var docDirURL: URL {
        return URL(fileURLWithPath: docDirPath, isDirectory: true)
    }
    
    class var libDirPath: String {
        let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
        return paths.first!
    }
    
    class var libDirURL: URL {
        return URL(fileURLWithPath: libDirPath, isDirectory: true)
    }
    
    // MARK: - Move Book
    
    class func move(_ book: Book, fromURL: URL, suggestedFileName: String?) {
        let fileName: String = {
            if let suggestedFileName = suggestedFileName {return suggestedFileName}
            if let id = book.id {return "\(id).zim"}
            return Date().description + ".zim"
        }()
        let directory = docDirURL
        createDirectory(directory, includeInICloudBackup: false)
        let destination = try! directory.appendingPathComponent(fileName)
        moveOrReplaceFile(from: fromURL, to: destination)
    }
    
    // MARK: - Book Resume Data
    
    private class func resumeDataURL(_ book: Book) -> URL {
        let tempDownloadLocation = try! URL(fileURLWithPath: libDirPath).appendingPathComponent("DownloadTemp", isDirectory: true)
        return try! tempDownloadLocation.appendingPathComponent(book.id ?? Date().description, isDirectory: false)
    }
    
    class func saveResumeData(_ data: Data, book: Book) {
        let tempDownloadLocation = try! URL(fileURLWithPath: libDirPath).appendingPathComponent("DownloadTemp", isDirectory: true)
        if !Foundation.FileManager.default.fileExists(atPath: tempDownloadLocation.path!) {
            do {
                try Foundation.FileManager.default.createDirectory(at: tempDownloadLocation, withIntermediateDirectories: true, attributes: [URLResourceKey.isExcludedFromBackupKey.rawValue: true])
            } catch let error as NSError {
                print("Create temp download folder failed: \(error.localizedDescription)")
            }
        }
        try? data.write(to: resumeDataURL(book), options: [.atomic])
    }
    
    class func readResumeData(_ book: Book) -> Data? {
        guard let path = resumeDataURL(book).path else {return nil}
        return Foundation.FileManager.default.contents(atPath: path)
    }
    
    class func removeResumeData(_ book: Book) {
        if Foundation.FileManager.default.fileExists(atPath: resumeDataURL(book).path!) {
            removeItem(atURL: resumeDataURL(book))
        }
    }
    
    // MARK: - Contents of Doc Folder
    
    class var zimFileURLsInDocDir: [URL] {
        return [URL]()
    }
    
    // MARK: - Item Operations
    
    class func itemExistAtURL(_ url: URL) -> Bool {
        guard let path = url.path else {return false}
        return Foundation.FileManager.default.fileExists(atPath: path)
    }
    
    class func removeItem(atURL location: URL) -> Bool {
        var succeed = true
        do {
            try Foundation.FileManager.default.removeItem(at: location)
        } catch let error as NSError {
            succeed = false
            print("Remove File failed: \(error.localizedDescription)")
        }
        return succeed
    }
    
    class func moveOrReplaceFile(from fromURL: URL, to toURL: URL) -> Bool {
        var succeed = true
        guard let path = toURL.path else {return false}
        if Foundation.FileManager.default.fileExists(atPath: path) {
            succeed = removeItem(atURL: toURL)
        }
        
        do {
            try Foundation.FileManager.default.moveItem(at: fromURL, to: toURL)
        } catch let error as NSError {
            succeed = false
            print("Move File failed: \(error.localizedDescription)")
        }
        return succeed
    }
    
    // MARK: - Dir Operations
    
    class func createDirectory(_ url: URL, includeInICloudBackup: Bool) {
        guard let path = url.path else {return}
        do {
            try Foundation.FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: [URLResourceKey.isExcludedFromBackupKey.rawValue: true])
        } catch let error as NSError {
            print("Create Directory failed: \(error.localizedDescription)")
        }
    }
    
    class func contentsOfDirectory(_ url: URL) -> [URL] {
        do {
            return try Foundation.FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants)
        } catch let error as NSError {
            print("Contents of Directory failed: \(error.localizedDescription)")
            return [URL]()
        }
    }
    
    class func removeContentsOfDirectory(_ url: URL) {
        for fileURL in contentsOfDirectory(url) {
            removeItem(atURL: fileURL)
        }
    }
    
    // MARK: - Backup Attribute
    
    class func setSkipBackupAttribute(_ skipBackup: Bool, url: URL) {
        guard let path = url.path else {return}
        guard Foundation.FileManager.default.fileExists(atPath: path) else {return}
        
        do {
            try (url as NSURL).setResourceValues([URLResourceKey.isExcludedFromBackupKey: skipBackup])
        } catch let error as NSError {
            print("Set skip backup attribute for item \(url) failed, error: \(error.localizedDescription)")
        }
    }
    
    class func getSkipBackupAttribute(item url: URL) -> Bool? {
        guard let path = url.path else {return nil}
        guard Foundation.FileManager.default.fileExists(atPath: path) else {return nil}
        
        var skipBackup: AnyObject? = nil
        
        do {
            try (url as NSURL).getResourceValue(&skipBackup, forKey: URLResourceKey.isExcludedFromBackupKey)
        } catch let error as NSError {
            print("Get skip backup attribute for item \(url) failed, error: \(error.localizedDescription)")
        }
        
        guard let number = skipBackup as? NSNumber else {return nil}
        return number.boolValue
    }
}

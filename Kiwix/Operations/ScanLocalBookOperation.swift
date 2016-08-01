//
//  ScanLocalBookOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import Operations

class ScanLocalBookOperation: Procedure {
    private let context: NSManagedObjectContext
    private var firstBookAdded = false
    
    private var lastZimFileURLSnapshot: Set<URL>
    private var currentZimFileURLSnapshot = Set<URL>()
    private let lastIndexFolderURLSnapshot: Set<URL>
    private var currentIndexFolderURLSnapshot = Set<URL>()
    
    private var completionHandler: ((currentZimFileURLSnapshot: Set<URL>, currentIndexFolderURLSnapshot: Set<URL>, firstBookAdded: Bool) -> Void)
    
    init(lastZimFileURLSnapshot: Set<URL>, lastIndexFolderURLSnapshot: Set<URL>,
         completionHandler: ((currentZimFileURLSnapshot: Set<URL>, currentIndexFolderURLSnapshot: Set<URL>, firstBookAdded: Bool) -> Void)) {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        self.lastZimFileURLSnapshot = lastZimFileURLSnapshot
        self.lastIndexFolderURLSnapshot = lastIndexFolderURLSnapshot
        
        self.completionHandler = completionHandler
        super.init()
        addCondition(MutuallyExclusive<ZimMultiReader>())
        name = String(self)
    }
    
    override func execute() {
        defer {finish()}
        
        currentZimFileURLSnapshot = ScanLocalBookOperation.getCurrentZimFileURLsInDocDir()
        currentIndexFolderURLSnapshot = ScanLocalBookOperation.getCurrentIndexFolderURLsInDocDir()
        
//        let zimFileHasChanges = lastZimFileURLSnapshot != currentZimFileURLSnapshot
        let indexFolderHasDeletions = lastIndexFolderURLSnapshot.subtracting(currentIndexFolderURLSnapshot).count > 0
        
//        guard zimFileHasChanges || indexFolderHasDeletions else {return}
        
        if indexFolderHasDeletions {
            lastZimFileURLSnapshot.removeAll()
        }
        
        updateReaders()
        updateCoreData()
    }
    
    override func operationDidFinish(_ errors: [ErrorProtocol]) {
        context.performAndWait {self.context.saveIfNeeded()}
        NSManagedObjectContext.mainQueueContext.performAndWait {NSManagedObjectContext.mainQueueContext.saveIfNeeded()}
        OperationQueue.main.addOperation { 
            self.completionHandler(currentZimFileURLSnapshot: self.currentZimFileURLSnapshot,
                currentIndexFolderURLSnapshot: self.currentIndexFolderURLSnapshot, firstBookAdded: self.firstBookAdded)
        }
    }
    
    private func updateReaders() {
        let addedZimFileURLs = currentZimFileURLSnapshot.subtracting(lastZimFileURLSnapshot)
        let removedZimFileURLs = lastZimFileURLSnapshot.subtracting(currentZimFileURLSnapshot)
        
        guard addedZimFileURLs.count > 0 || removedZimFileURLs.count > 0 else {return}
        ZimMultiReader.sharedInstance.removeReaders(removedZimFileURLs)
        ZimMultiReader.sharedInstance.addReaders(addedZimFileURLs)
    }
    
    private func updateCoreData() {
        let localBooks = Book.fetchLocal(context)
        let zimReaderIDs = Set(ZimMultiReader.sharedInstance.readers.keys)
        let addedZimFileIDs = zimReaderIDs.subtracting(Set(localBooks.keys))
        let removedZimFileIDs = Set(localBooks.keys).subtracting(zimReaderIDs)
        
        for id in removedZimFileIDs {
            guard let book = localBooks[id] else {continue}
            if let _ = book.meta4URL {
                book.isLocal = false
            } else {
                context.delete(book)
            }
        }
        
        for id in addedZimFileIDs {
            guard let reader = ZimMultiReader.sharedInstance.readers[id] else {return}
            let book: Book? = {
                let book = Book.fetch(id, context: NSManagedObjectContext.mainQueueContext)
                return book ?? Book.add(metadata: reader.metaData, context: NSManagedObjectContext.mainQueueContext)
            }()
            book?.isLocal = true
            book?.hasIndex = reader.hasIndex()
            book?.hasPic = !(reader.fileURL.absoluteString?.contains("nopic") ?? false)
        }
        
        for (id, book) in localBooks {
            guard !context.deletedObjects.contains(book) else {continue}
            guard let reader = ZimMultiReader.sharedInstance.readers[id] else {return}
            book.hasIndex = reader.hasIndex()
        }
        
        if localBooks.count == 0 && addedZimFileIDs.count == 1 {
            firstBookAdded = true
        }
    }
    
    // MARK: - Helper
    
    private class func getCurrentZimFileURLsInDocDir() -> Set<URL> {
        FileManager.
        let fileURLs = FileManager.contentsOfDirectory(FileManager.docDirURL) ?? [URL]()
        var zimURLs = Set<URL>()
        for url in fileURLs {
            let keys = Set(arrayLiteral: URLResourceKey.isDirectoryKey)
            guard let values = try? url.resourceValues(forKeys: keys),
                let isDirectory = values.isDirectory,
                isDirectory == false else {continue}
            guard let pathExtension = url.pathExtension?.lowercased(),
                pathExtension.contains("zim") else {continue}
            zimURLs.insert(url)
        }
        return zimURLs
    }
    
    private class func getCurrentIndexFolderURLsInDocDir() -> Set<URL> {
        let fileURLs = FileManager.contentsOfDirectory(FileManager.docDirURL) ?? [URL]()
        var folderURLs = Set<URL>()
        for url in fileURLs {
            do {
                var isDirectory: AnyObject? = nil
                try (url as NSURL).getResourceValue(&isDirectory, forKey: URLResourceKey.isDirectoryKey)
                if let isDirectory = (isDirectory as? NSNumber)?.boolValue {
                    if isDirectory {
                        guard let pathExtension = url.pathExtension?.lowercased() else {continue}
                        guard pathExtension == "idx" else {continue}
                        folderURLs.insert(url)
                    }
                }
            } catch {
                continue
            }
        }
        return folderURLs
    }

}

//
//  ZimMultiReader.swift
//  Kiwix
//
//  Created by Chris on 12/19/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import CoreData
import PSOperations

class ZimMultiReader: NSObject, DirectoryMonitorDelegate {
    static let sharedInstance = ZimMultiReader()
    
    weak var delegate: ZimMultiReaderDelegate?
    private weak var scanOperation: ScanLocalBookOperation?
    private weak var searchOperation: SearchOperation?
    
    private let searchQueue = OperationQueue()
    private(set) var isScanning = false
    private(set) var readers = [ZimID: ZimReader]()
    private let monitor = DirectoryMonitor(URL: FileManager.docDirURL)
    private var lastZimFileURLSnapshot = Set<URL>()
    private var lastIndexFolderURLSnapshot = Set<URL>()
    
    override init() {
        super.init()
        
        startScan()
        monitor.delegate = self
        monitor.startMonitoring()
    }
    
    deinit {
        monitor.stopMonitoring()
    }
    
    func startScan() {
        isScanning = true
        let scanOperation = ScanLocalBookOperation(lastZimFileURLSnapshot: lastZimFileURLSnapshot, lastIndexFolderURLSnapshot: lastIndexFolderURLSnapshot) { (currentZimFileURLSnapshot, currentIndexFolderURLSnapshot, firstBookAdded) in
            self.lastZimFileURLSnapshot = currentZimFileURLSnapshot
            self.lastIndexFolderURLSnapshot = currentIndexFolderURLSnapshot
            self.isScanning = false
            if firstBookAdded {
                self.delegate?.firstBookAdded()
            }
        }
        GlobalOperationQueue.sharedInstance.addOperation(scanOperation)
        self.scanOperation = scanOperation
    }
    
    // MARK: - Reader Addition / Deletion
    
    func addReaders(_ urls: Set<URL>) {
        for url in urls {
            guard let reader = ZimReader(zimFileURL: url) else {continue}
            let id = reader.getID()
            readers[id!] = reader
        }
    }
    
    func removeReaders(_ urls: Set<URL>) {
        for (id, reader) in readers {
            guard urls.contains(reader.fileURL) else {continue}
            readers[id] = nil
        }
    }
    
    // MARK: - DirectoryMonitorDelegate
    
    func directoryMonitorDidObserveChange() {
        startScan()
    }
    
    // MARK: - Search
    
    func startSearch(_ searchOperation: SearchOperation) {
        if let scanOperation = scanOperation {
            searchOperation.addDependency(scanOperation)
        }
        
        if let searchOperation = self.searchOperation {
            searchOperation.cancel()
        }
        searchQueue.addOperation(searchOperation)
        self.searchOperation = searchOperation
    }
    
    // MARK: Search (Old)
    
    func search(_ searchTerm: String, zimFileID: String) -> [(id: String, articleTitle: String)] {
        var resultTuples = [(id: String, articleTitle: String)]()
        let firstCharRange = searchTerm.startIndex...searchTerm.startIndex
        let firstLetterCapitalisedSearchTerm = searchTerm.replacingCharacters(in: firstCharRange, with: searchTerm.substring(with: firstCharRange).capitalized)
        let searchTermVariations = Set([searchTerm, searchTerm.uppercased(), searchTerm.lowercased(), searchTerm.capitalized, firstLetterCapitalisedSearchTerm])
        
        let reader = readers[zimFileID]
        var results = Set<String>()
        for searchTermVariation in searchTermVariations {
            guard let result = reader?.searchSuggestionsSmart(searchTermVariation) as? [String] else {continue}
            results.formUnion(result)
        }
        
        for result in results {
            resultTuples.append((id: zimFileID, articleTitle: result))
        }
        
        return resultTuples
    }
    
    // MARK: - Loading System
    
    func data(_ id: String, contentURLString: String) -> [String: AnyObject]? {
        guard let reader = readers[id] else {return nil}
        return reader.data(withContentURLString: contentURLString) as? [String: AnyObject]
    }
    
    func pageURLString(_ articleTitle: String, bookid id: String) -> String? {
        guard let reader = readers[id] else {return nil}
        return reader.pageURL(fromTitle: articleTitle)
    }
    
    func mainPageURLString(bookid id: String) -> String? {
        guard let reader = readers[id] else {return nil}
        return reader.mainPageURL()
    }
    
    func randomPageURLString() -> (id: String, contentURLString: String)? {
        var randomPageURLs = [(String, String)]()
        for (id, reader) in readers{
            randomPageURLs.append((id, reader.getRandomPageUrl()))
        }
        
        guard randomPageURLs.count > 0 else {return nil}
        let index = arc4random_uniform(UInt32(randomPageURLs.count))
        return randomPageURLs[Int(index)]
    }
}

protocol ZimMultiReaderDelegate: class {
    func firstBookAdded()
}


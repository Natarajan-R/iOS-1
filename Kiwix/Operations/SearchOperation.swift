//
//  SearchOperation.swift
//  Kiwix
//
//  Created by Chris Li on 4/9/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

class SearchOperation: GroupOperation {
    let completionHandler: ([SearchResult]?) -> Void
    private(set) var results = [SearchResult]()
    //private let startTime = NSDate()
    
    init(searchTerm: String, completionHandler: ([SearchResult]?) -> Void) {
        self.completionHandler = completionHandler
        super.init(operations: [Operation]())
        
        let sortOperation = SortSearchResultsOperation { (results) in
            self.results = results
        }
        
        for (id, zimReader) in ZimMultiReader.sharedInstance.readers {
            let managedObjectContext = UIApplication.appDelegate.managedObjectContext
            guard let book = Book.fetch(id, context: managedObjectContext) else {continue}
            guard book.includeInSearch else {continue}
            let operation = SingleBookSearchOperation(zimReader: zimReader,
                                                      lowerCaseSearchTerm: searchTerm.lowercased(),
                                                      completionHandler: { [unowned sortOperation] (results) in
                sortOperation.results += results
            })
            
            addOperation(operation)
            sortOperation.addDependency(operation)
        }
        
        addOperation(sortOperation)
        
        addCondition(MutuallyExclusive<ZimMultiReader>())
    }
    
    override func finished(_ errors: [NSError]) {
        //print("Search Operation finished, status \(cancelled ? "Canceled" : "Not Canceled"), \(NSDate().timeIntervalSinceDate(startTime))")
        OperationQueue.main.addOperationWithBlock {
            self.completionHandler(self.cancelled ? nil : self.results)
        }
    }
}

private class SingleBookSearchOperation: Operation {
    let zimReader: ZimReader
    let lowerCaseSearchTerm: String
    let completionHandler: ([SearchResult]) -> Void
    
    init(zimReader: ZimReader, lowerCaseSearchTerm: String, completionHandler: ([SearchResult]) -> Void) {
        self.zimReader = zimReader
        self.lowerCaseSearchTerm = lowerCaseSearchTerm
        self.completionHandler = completionHandler
    }
    
    override private func execute() {
        var results = [String: SearchResult]()
        let indexedDics = zimReader.search(usingIndex: lowerCaseSearchTerm) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        let titleDics = zimReader.searchSuggestionsSmart(lowerCaseSearchTerm) as? [[String: AnyObject]] ?? [[String: AnyObject]]()
        let mixedDics = titleDics + indexedDics // It is important we process the title search result first, so that we always keep the indexed search result
        for dic in mixedDics {
            guard let result = SearchResult (rawResult: dic, lowerCaseSearchTerm: lowerCaseSearchTerm) else {continue}
            results[result.path] = result
        }
        completionHandler(Array(results.values))
        finish()
    }
}

private class SortSearchResultsOperation: Operation {
    let completionHandler: ([SearchResult]) -> Void
    var results = [SearchResult]()
    
    init(completionHandler: ([SearchResult]) -> Void) {
        self.completionHandler = completionHandler
    }
    
    override private func execute() {
        sort()
        completionHandler(results)
        finish()
    }
    
    private func sort() {
        results.sort { (result0, result1) -> Bool in
            if result0.score != result1.score {
                return result0.score < result1.score
            } else {
                if result0.snippet != nil {return true}
                if result1.snippet != nil {return false}
                return titleCaseInsensitiveCompare(result0, result1: result1)
            }
        }
    }
    
    // MARK: - Utilities
    
    private func titleCaseInsensitiveCompare(_ result0: SearchResult, result1: SearchResult) -> Bool {
        return result0.title.caseInsensitiveCompare(result1.title) == ComparisonResult.orderedAscending
    }
}


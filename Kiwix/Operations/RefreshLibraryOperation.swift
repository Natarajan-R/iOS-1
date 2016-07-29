//
//  RefreshLibraryOperation.swift
//  Kiwix
//
//  Created by Chris Li on 2/7/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import CoreData
import Operations

class RefreshLibraryOperation: GroupOperation {
    
    var completionHandler: ((errors: [NSError]) -> Void)?
    
    init(invokedAutomatically: Bool, completionHandler: ((errors: [NSError]) -> Void)?) {
        super.init(operations: [])
        
        name = String(RefreshLibraryOperation.self)
        self.completionHandler = completionHandler
        
        // 1.Parse
        let parseOperation = ParseLibraryOperation()
        
        // 0.Download library
        let url = URL(string: "http://www.kiwix.org/library.xml")!
        let task = URLSession.shared.dataTask(with: url) { [unowned parseOperation] (data, response, error) -> Void in
            if let error = error {self.addFatalError(error)}
            parseOperation.xmlData = data
        }
        let fetchOperation = URLSessionTaskOperation(task: task)
        fetchOperation.name = "Library XML download operation"
        
        #if os(iOS) || os(watchOS) || os(tvOS)
            fetchOperation.addObserver(NetworkObserver())
        #endif
        fetchOperation.addCondition(ReachabilityCondition(host: url, allowCellular: Preference.libraryRefreshAllowCellularData))
        
        if invokedAutomatically {
            addCondition(AllowAutoRefreshCondition())
        }
        
        addOperation(fetchOperation)
        addOperation(parseOperation)
        parseOperation.addDependency(fetchOperation)
    }
    
    override func operationDidFinish(_ errors: [ErrorProtocol]) {
        let 🛠_passErrorsToCaller = 0
        completionHandler?(errors: [NSError]())
    }
}

class ParseLibraryOperation: Procedure, XMLParserDelegate {
    var xmlData: Data?
    let context: NSManagedObjectContext
    
    var oldBookIDs = Set<String>()
    var newBookIDs = Set<String>()
    
    override init() {
        self.context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = NSManagedObjectContext.mainQueueContext
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        super.init()
        name = String(ParseLibraryOperation.self)
    }
    
    override func execute() {
        guard let data = xmlData else {finish(); return}
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = self
        xmlParser.parse()
        finish()
    }
    
    // MARK: NSXMLParser Delegate
    
    @objc internal func parserDidStartDocument(_ parser: XMLParser) {
        context.performAndWait { () -> Void in
            self.oldBookIDs = Set(Book.fetchAll(self.context).map({$0.id ?? ""}))
        }
    }
    
    @objc internal func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        guard elementName == "book" else {return}
        guard let id = attributeDict["id"] else {return}
        
        if !oldBookIDs.contains(id) {
            context.performAndWait({ () -> Void in
                _ = Book.add(metadata: attributeDict, context: self.context)
            })
        }
        newBookIDs.insert(id)
    }
    
    @objc internal func parserDidEndDocument(_ parser: XMLParser) {
        // ID of Books on device but no longer in library.xml
        let ids = oldBookIDs.subtracting(newBookIDs)
        
        for id in ids {
            context.performAndWait({ () -> Void in
                guard let book = Book.fetch(id, context: self.context) else {return}
                
                // Delete Book object only if book is online, i.e., is not associated with a download task or is not local
                guard book.isLocal == false else {return}
                self.context.delete(book)
            })
        }

        saveManagedObjectContexts()
        Preference.libraryLastRefreshTime = Date()
        //print("Parse finished successfully")
    }
    
    @objc internal func parser(_ parser: XMLParser, parseErrorOccurred parseError: NSError) {
        saveManagedObjectContexts()
    }
    
    // MARK: - Tools
    
    func saveManagedObjectContexts() {
        context.performAndWait { () -> Void in
            self.context.saveIfNeeded()
        }
        context.parent?.performAndWait({ () -> Void in
            self.context.parent?.saveIfNeeded()
        })
    }
}

private struct AllowAutoRefreshCondition: OperationCondition {
    let name = "LibraryAllowAutoRefresh"
    let isMutuallyExclusive = false
    
    init() {}
    
    func dependencyForOperation(_ operation: Procedure) -> Operation? {
        return nil
    }
    
    func evaluateForOperation(_ operation: Procedure, completion: (OperationConditionResult) -> Void) {
        let allowAutoRefresh = !Preference.libraryAutoRefreshDisabled
        
        if allowAutoRefresh {
            completion(.satisfied)
        } else {
//            let error = NSError(code: .ConditionFailed, userInfo: [OperationConditionKey: self.dynamicType.name])
            completion(.failed(OperationError.conditionFailed))
        }
    }
}

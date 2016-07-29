//
//  GlobalOperationQueue.swift
//  Kiwix
//
//  Created by Chris Li on 5/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Operations

class GlobalOperationQueue: ProcedureQueue {
    static let sharedInstance = GlobalOperationQueue()
}

public enum OperationErrorCode: Int {
    case conditionFailed = 1
    case executionFailed = 2
    
    // Error that should be reported to user
    case networkError
    case serverNameInvalid
    case authError
    case accessRevoked
    case unreachable
    case lackOfValue
    case unexpectedError
}

extension OperationQueue {
    // Oneday should be replaced with ExclusivityController
    func getOperation(_ id: String) -> Operation? {
        for operation in operations {
            guard operation.name == id else {continue}
            guard let operation = operation as? Operation else {continue}
            return operation
        }
        return nil
    }
}

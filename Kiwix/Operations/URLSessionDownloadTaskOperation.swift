//
//  URLSessionDownloadTaskOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import PSOperations

private var URLSessionTaskOperationKVOContext = 0

public class URLSessionDownloadTaskOperation: Operation {
    let task: URLSessionDownloadTask
    private var produceResumeData = false
    private var observerRemoved = false
    private let stateLock = Lock()
    
    public init(downloadTask: URLSessionDownloadTask) {
        self.task = downloadTask
        super.init()
        
        addObserver(BlockObserver(cancelHandler: { _ in
            if self.produceResumeData {
                downloadTask.cancelByProducingResumeData({ (data) in
                })
            } else {
                downloadTask.cancel()
            }
        }))
    }
    
    public func cancel(produceResumeData: Bool) {
        self.produceResumeData = produceResumeData
        cancel()
    }
    
    override public func execute() {
        guard task.state == .suspended || task.state == .running else {
            finish()
            return
        }
        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions(), context: &URLSessionTaskOperationKVOContext)
        if task.state == .suspended {
            task.resume()
        }
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &URLSessionTaskOperationKVOContext else { return }
        
        stateLock.withCriticalScope {
            if object === task && keyPath == "state" && !observerRemoved {
                switch task.state {
                case .completed:
                    finish()
                    fallthrough
                case .canceling:
                    observerRemoved = true
                    task.removeObserver(self, forKeyPath: "state")
                default:
                    return
                }
            }
        }
    }
}

private extension Lock {
    func withCriticalScope<T>(_ block: @noescape (Void) -> T) -> T {
        lock()
        let value = block()
        unlock()
        return value
    }
}

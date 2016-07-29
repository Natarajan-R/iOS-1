//
//  URLSessionDownloadTaskOperation.swift
//  Kiwix
//
//  Created by Chris Li on 7/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Operations

private var URLSessionDownloadTaskOperationKVOContext = 0

class URLSessionDownloadTaskOperation: Procedure {
    let task: URLSessionDownloadTask
    private var produceResumeData = false
    private var observerRemoved = false
    private let stateLock = Lock()
    
    init(downloadTask: URLSessionDownloadTask) {
        self.task = downloadTask
        super.init()
        
        let observer = BlockObserver(willExecute: nil, willCancel: nil, didCancel: { (operation) in
            if self.produceResumeData {
                self.task.cancel(byProducingResumeData: { (data) in
                })
            } else {
                self.task.cancel()
            }
            }, didProduce: nil, willFinish: nil, didFinish: nil)
        addObserver(observer)
    }
    
    func cancel(produceResumeData: Bool) {
        self.produceResumeData = produceResumeData
        cancel()
    }
    
    override func execute() {
        guard task.state == .suspended || task.state == .running else {
            finish()
            return
        }
        task.addObserver(self, forKeyPath: "state", options: NSKeyValueObservingOptions(), context: &URLSessionDownloadTaskOperationKVOContext)
        if task.state == .suspended {
            task.resume()
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        guard context == &URLSessionDownloadTaskOperationKVOContext else { return }
        
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

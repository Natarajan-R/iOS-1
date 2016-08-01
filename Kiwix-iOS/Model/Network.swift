//
//  Network.swift
//  Kiwix
//
//  Created by Chris Li on 3/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import CoreData
import Operations

class Network: NSObject, URLSessionDelegate, URLSessionDownloadDelegate, URLSessionTaskDelegate, OperationQueueDelegate {
    static let sharedInstance = Network()
    weak var delegate: DownloadProgressReporting?
    
    private let context = NSManagedObjectContext.mainQueueContext
    let queue = ProcedureQueue()
    
    var progresses = [String: DownloadProgress]()
    private var timer: Foundation.Timer?
    private var shouldReportProgress = false
    private var completionHandler: (()-> Void)?
    
    lazy var session: Foundation.URLSession = {
        let configuration = URLSessionConfiguration.background(withIdentifier: "org.kiwix.www")
        configuration.allowsCellularAccess = false
        configuration.isDiscretionary = false
        return Foundation.URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    }()
    
    override init() {
        super.init()
        queue.delegate = self
    }
    
    func restoreProgresses() {
        let downloadTasks = DownloadTask.fetchAll(context)
        for downloadTask in downloadTasks {
            guard let book = downloadTask.book, let id = book.id else {continue}
            progresses[id] = DownloadProgress(book: book)
        }
        session.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) -> Void in
            for task in downloadTasks {
                let operation = URLSessionDownloadTaskOperation(downloadTask: task)
                operation.name = task.taskDescription
                operation.addObserver(NetworkObserver())
                self.queue.addOperation(operation)
            }
        }
    }
    
    func rejoinSessionWithIdentifier(_ identifier: String, completionHandler: ()-> Void) {
        guard identifier == session.configuration.identifier else {return}
        self.completionHandler = completionHandler
    }
    
    func resetProgressReportingFlag() {shouldReportProgress = true}
    
    // MARK: - Tasks
    
    func download(_ book: Book) {
        guard let url = book.url else {return}
        book.isLocal = nil
        let task = session.downloadTask(with: url)
        startTask(task, book: book)
    }
    
    func resume(_ book: Book) {
        guard let resumeData = FileManager.readResumeData(book) else {
            // TODO: Alert
            print("Could not resume, data mmissing / damaged")
            return
        }
        let task = session.downloadTask(withResumeData: resumeData)
        startTask(task, book: book)
    }
    
    func pause(_ book: Book) {
        guard let id = book.id,
            let operation = queue.getProcedure(name: id) as? URLSessionDownloadTaskOperation else {return}
        operation.cancel(produceResumeData: true)
    }
    
    func cancel(_ book: Book) {
        guard let id = book.id,
            let operation = queue.getProcedure(name: id) as? URLSessionDownloadTaskOperation else {return}
        operation.cancel(produceResumeData: false)
    }
    
    private func startTask(_ task: URLSessionDownloadTask, book: Book) {
        guard let id = book.id else {return}
        task.taskDescription = id
        
        let downloadTask = DownloadTask.addOrUpdate(book, context: context)
        downloadTask?.state = .queued
        
        let operation = URLSessionDownloadTaskOperation(downloadTask: task)
        operation.name = id
        operation.addObserver(NetworkObserver())
        queue.addOperation(operation)
        
        let progress = DownloadProgress(book: book)
        progress.downloadStarted(task)
        progresses[id] = progress
    }
    
    // MARK: - OperationQueueDelegate
    
    func operationQueue(_ queue: ProcedureQueue, willAddOperation operation: Operation) {
        guard queue.operationCount == 0 else {return}
        shouldReportProgress = true
        OperationQueue.main.addOperation { () -> Void in
            self.timer = Foundation.Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(Network.resetProgressReportingFlag), userInfo: nil, repeats: true)
        }
    }
    
    func operationQueue(_ queue: ProcedureQueue, willFinishOperation operation: Operation, withErrors errors: [ErrorProtocol]) {
        
    }
    
    func operationQueue(_ queue: ProcedureQueue, didFinishOperation operation: Operation, withErrors errors: [ErrorProtocol]) {
        guard queue.operationCount == 1 else {return}
        OperationQueue.main.addOperation { () -> Void in
            self.timer?.invalidate()
            self.shouldReportProgress = false
        }
    }
    
    func operationQueue(_ queue: ProcedureQueue, willProduceOperation operation: Operation) {
        
    }
    
    // MARK: - NSURLSessionDelegate
    
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        OperationQueue.main.addOperation {
            self.completionHandler?()
            
            let notification = UILocalNotification()
            notification.alertTitle = NSLocalizedString("Book download finished", comment: "Notification: Book download finished")
            notification.alertBody = NSLocalizedString("All download tasks are finished.", comment: "Notification: Book download finished")
            notification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.shared().presentLocalNotificationNow(notification)
        }
    }
    
    // MARK: - NSURLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: NSError?) {
        guard let error = error, let id = task.taskDescription,
            let progress = progresses[id], let downloadTask = progress.book.downloadTask else {return}
        progress.downloadTerminated()
        if error.code == NSURLErrorCancelled {
            context.perform({ () -> Void in
                downloadTask.state = .paused
                guard let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data else {
                    downloadTask.totalBytesWritten = 0
                    return
                }
                downloadTask.totalBytesWritten = Int64(task.countOfBytesReceived)
                progress.completedUnitCount = Int64(task.countOfBytesReceived)
                FileManager.saveResumeData(resumeData, book: progress.book)
            })
        }
    }
    
    // MARK: - NSURLSessionDownloadDelegate
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let id = downloadTask.taskDescription,
              let book = progresses[id]?.book,
              let bookDownloadTask = book.downloadTask else {return}
        
        context.performAndWait { () -> Void in
            self.context.delete(bookDownloadTask)
        }
        
        progresses[id] = nil
        FileManager.move(book, fromURL: location, suggestedFileName: downloadTask.response?.suggestedFilename)
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        guard let id = downloadTask.taskDescription,
              let downloadTask = progresses[id]?.book.downloadTask else {return}
        context.performAndWait { () -> Void in
            guard downloadTask.state == .queued else {return}
            downloadTask.state = .downloading
        }
        
        guard shouldReportProgress else {return}
        OperationQueue.main.addOperation { () -> Void in
            self.delegate?.refreshProgress()
        }
        shouldReportProgress = false
    }
}

protocol DownloadProgressReporting: class {
    func refreshProgress()
}

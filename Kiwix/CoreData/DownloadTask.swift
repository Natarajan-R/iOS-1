//
//  DownloadTask.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData


class DownloadTask: NSManagedObject {

    class func addOrUpdate(_ book: Book, context: NSManagedObjectContext) -> DownloadTask? {
        let downloadTask = DownloadTask.fetch(book: book, context: context) ?? insert(DownloadTask.self, context: context)
        downloadTask?.creationTime = Date()
        downloadTask?.book = book
        return downloadTask
    }
    
    class func fetch(book: Book, context: NSManagedObjectContext) -> DownloadTask? {
        let fetchRequest = NSFetchRequest<DownloadTask>(entityName: "DownloadTask")
        fetchRequest.predicate = Predicate(format: "book = %@", book)
        return (try? context.fetch(fetchRequest))?.first
    }
    
    class func fetchAll(_ context: NSManagedObjectContext) -> [DownloadTask] {
        let fetchRequest = NSFetchRequest<DownloadTask>(entityName: "DownloadTask")
        return (try? context.fetch(fetchRequest)) ?? [DownloadTask]()
    }
    
    var state: DownloadTaskState {
        get {
            switch stateRaw {
            case 0: return .queued
            case 1: return .downloading
            case 2: return .paused
            default: return .error
            }
        }
        set {
            stateRaw = Int16(newValue.rawValue)
        }
    }
}

enum DownloadTaskState: Int {
    case queued, downloading, paused, error
}

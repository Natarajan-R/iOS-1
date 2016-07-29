//
//  Book.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData
#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

class Book: NSManagedObject {

    // MARK: - Add Book
    
    class func add(_ metadata: [String: AnyObject], context: NSManagedObjectContext) -> Book? {
        guard let book = insert(Book.self, context: context) else {return nil}
        
        book.id = metadata["id"] as? String
        book.title = metadata["title"] as? String
        book.creator = metadata["creator"] as? String
        book.publisher = metadata["publisher"] as? String
        book.desc = metadata["description"] as? String
        book.meta4URL = metadata["url"] as? String
        
        if let articleCount = metadata["articleCount"] as? String,
            let mediaCount = metadata["mediaCount"] as? String,
            let fileSize = metadata["size"] as? String {
            let numberFormatter = NumberFormatter()
            numberFormatter.numberStyle = NumberFormatter.Style.decimal
            book.articleCount = numberFormatter.number(from: articleCount)?.int64Value ?? 0
            book.mediaCount = numberFormatter.number(from: mediaCount)?.int64Value ?? 0
            
            if let fileSize = numberFormatter.number(from: fileSize) {
                book.fileSize = NSNumber(value: fileSize.int64Value * Int64(1024.0)).int64Value
            }
        }
        
        if let date = metadata["date"] as? String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            book.date = dateFormatter.date(from: date)
        }
        
        if let favIcon = metadata["favicon"] as? Data {
            book.favIcon = favIcon
        } else if let favIcon = metadata["favicon"] as? String {
            book.favIcon = Data(base64Encoded: favIcon, options: .ignoreUnknownCharacters)
        }
        
        if let meta4url = book.meta4URL {
            book.hasPic = !meta4url.contains("nopic")
        }
        
        if let languageCode = metadata["language"] as? String {
            if let language = Language.fetchOrAdd(languageCode, context: context) {
                book.language = language
            }
        }

        return book
    }
    
    // MARK: - Properties
    
    var url: URL? {
        guard let meta4URL = meta4URL else {return nil}
        // return url = NSURL(string: meta4URL.stringByReplacingOccurrencesOfString(".meta4", withString: ""))
        var urlComponents = URLComponents(string: meta4URL.replacingOccurrences(of: ".meta4", with: ""))
        urlComponents?.scheme = "https"
        return urlComponents?.url
    }
    
    // MARK: - Fetch
    
    class func fetchAll(_ context: NSManagedObjectContext) -> [Book] {
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        return (try? context.fetch(fetchRequest)) ?? [Book]()
    }
    
    class func fetchLocal(_ context: NSManagedObjectContext) -> [ZimID: Book] {
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        let predicate = Predicate(format: "isLocal = true")
        fetchRequest.predicate = predicate
        let localBooks = (try? context.fetch(fetchRequest)) ?? [Book]()
        
        var books = [ZimID: Book]()
        for book in localBooks {
            guard let id = book.id else {continue}
            books[id] = book
        }
        return books
    }
    
    class func fetch(_ id: String, context: NSManagedObjectContext) -> Book? {
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        fetchRequest.predicate = Predicate(format: "id = %@", id)
        return (try? context.fetch(fetchRequest))?.first
    }
    
    // MARK: - Properties Description
    
    var dateFormatted: String? {
        guard let date = date else {return nil}
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .medium
        return formatter.string(from: date as Date)
    }
    
    var fileSizeFormatted: String? {
        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var articleCountFormatted: String? {
        func formattedNumberStringFromDouble(_ num: Double) -> String {
            let sign = ((num < 0) ? "-" : "" )
            let abs = fabs(num)
            guard abs >= 1000.0 else {
                if abs - Double(Int(abs)) == 0 {
                    return "\(sign)\(Int(abs))"
                } else {
                    return "\(sign)\(abs)"
                }
            }
            let exp: Int = Int(log10(abs) / log10(1000))
            let units: [String] = ["K","M","G","T","P","E"]
            let roundedNum: Double = round(10 * abs / pow(1000.0,Double(exp))) / 10;
            return "\(sign)\(roundedNum)\(units[exp-1])"
        }
        return formattedNumberStringFromDouble(Double(articleCount)) + (articleCount >= 1 ? " articles" : " article")
    }
    
    // MARK: - Description Label
    
    var detailedDescription: String? {
        var descriptions = [String]()
        if let dateFormatted = dateFormatted {descriptions.append(dateFormatted)}
        if let fileSizeFormatted = fileSizeFormatted {descriptions.append(fileSizeFormatted)}
        if let articleCountFormatted = articleCountFormatted {descriptions.append(articleCountFormatted)}
        
        guard descriptions.count != 0 else {return nil}
        return descriptions.joined(separator: ", ")
    }
    
    var detailedDescription1: String? {
        var descriptions = [String]()
        if let description = detailedDescription {descriptions.append(description)}
        if let bookDescription = desc {descriptions.append(bookDescription)}
        return descriptions.joined(separator: "\n")
    }
    
    var detailedDescription2: String? {
        var descriptions = [String]()
        if let description = detailedDescription {descriptions.append(description)}
        if let bookDescription = desc {descriptions.append(bookDescription)}
        if let creatorAndPublisherDescription = creatorAndPublisherDescription {descriptions.append(creatorAndPublisherDescription)}
        return descriptions.joined(separator: "\n")
    }
    
    private var creatorAndPublisherDescription: String? {
        if let creator = self.creator, publisher = self.publisher {
            if creator == publisher {
                return "Creator and publisher: " + creator
            } else {
                return "Creator: " + creator + " Publisher: " + publisher
            }
        } else if let creator = self.creator {
            return "Creator: " + creator
        } else if let publisher = self.publisher {
            return "Publisher: " + publisher
        } else {
            return nil
        }
    }
    
    // MARK: - States
    
    var spaceState: BookSpaceState {
        #if os(iOS) || os(watchOS) || os(tvOS)
            let freeSpaceInBytes = UIDevice.availableDiskSpace ?? INT64_MAX
            if (0.8 * Double(freeSpaceInBytes)) > Double(fileSize) {
                return .enough
            } else if freeSpaceInBytes < fileSize{
                return .notEnough
            } else {
                return .caution
            }
        #elseif os(OSX)
            return .Enough
        #endif
    }
}

enum BookSpaceState: Int {
    case enough, caution, notEnough
}

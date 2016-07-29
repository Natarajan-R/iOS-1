//
//  Article.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData


class Article: NSManagedObject {

    class func addOrUpdate(_ title: String? = nil, url: URL, book: Book, context: NSManagedObjectContext) -> Article? {
        let fetchRequest = NSFetchRequest(entityName: "Article")
        fetchRequest.predicate = Predicate(format: "urlString = %@", url.absoluteString)
        let article = Article.fetch(fetchRequest, type: Article.self, context: context)?.first ?? insert(Article.self, context: context)
        
        article?.title = title
        article?.urlString = url.absoluteString
        article?.book = book
        
        return article
    }
    
    class func fetchRecentBookmarks(_ count: Int, context: NSManagedObjectContext) -> [Article] {
        let fetchRequest = NSFetchRequest(entityName: "Article")
        let dateDescriptor = SortDescriptor(key: "bookmarkDate", ascending: false)
        let titleDescriptor = SortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [dateDescriptor, titleDescriptor]
        fetchRequest.predicate = Predicate(format: "isBookmarked == true")
        fetchRequest.fetchLimit = count
        return fetch(fetchRequest, type: Article.self, context: context) ?? [Article]()
    }
    
    // MARK: - Helper
    
    var url: URL? {
        guard let urlString = urlString else {return nil}
        return URL(string: urlString)
    }
    
    var thumbImageData: Data? {
        if let urlString = thumbImageURL,
            let url = URL(string: urlString),
            let data = try? Data(contentsOf: url) {
            return data
        } else {
            return book?.favIcon
        }
    }
    
    func dictionarySerilization() -> NSDictionary? {
        guard let title = title,
            let data = thumbImageData,
            let url = url else {return nil}
        return [
            "title": title,
            "thumbImageData": data,
            "url": url.absoluteString!,
            "isMainPage": NSNumber(value: isMainPage)
        ]
    }

}

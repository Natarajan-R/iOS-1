//
//  Language.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation
import CoreData


class Language: NSManagedObject {

    class func fetchOrAdd(_ code: String, context: NSManagedObjectContext) -> Language? {
        let code = Locale.canonicalLanguageIdentifier(from: code)

        if let language = fetch(code, context: context) {
            return language
        }
        
        guard let language = insert(Language.self, context: context) else {return nil}
        language.code = code
        language.name = Locale.current.displayName(forKey: Locale.Key.languageCode, value: code)
        return language
    }
    
    class func fetch(_ code: String, context: NSManagedObjectContext) -> Language? {
        let fetchRequest = NSFetchRequest(entityName: "Language")
        fetchRequest.predicate = Predicate(format: "code == %@", code)
        return fetch(fetchRequest, type: Language.self, context: context)?.first
    }
    
    class func fetch(displayed: Bool, context: NSManagedObjectContext) -> [Language] {
        let fetchRequest = NSFetchRequest(entityName: "Language")
        fetchRequest.predicate = Predicate(format: "isDisplayed == %@ AND name != nil", displayed)
        return fetch(fetchRequest, type: Language.self, context: context) ?? [Language]()
    }
    
    class func fetchAll(_ context: NSManagedObjectContext) -> [Language] {
        let fetchRequest = NSFetchRequest(entityName: "Language")
        return fetch(fetchRequest, type: Language.self, context: context) ?? [Language]()
    }
}

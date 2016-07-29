//
//  UIOperations.swift
//  Kiwix
//
//  Created by Chris Li on 3/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import PSOperations

// MARK: - Alerts

class SpaceCautionAlert: AlertOperation {
    init(book: Book, presentationContext: UIViewController?) {
        super.init(presentationContext: presentationContext)
        
        let comment = "Library: Download Space Caution Alert"
        
        title = NSLocalizedString("Space Caution", comment: comment)
        message = NSLocalizedString("This book takes up more than 80% of the remaining space on your device. Are you sure you want to download it?", comment: comment)
        addAction(NSLocalizedString("Download Anyway", comment: comment), style: .default) { (action) -> Void in
            Network.sharedInstance.download(book)
        }
        addAction(LocalizedStrings.cancel)
    }
}

class SpaceNotEnoughAlert: AlertOperation {
    init(book: Book, presentationContext: UIViewController?) {
        super.init(presentationContext: presentationContext)
        
        let comment = "Library: Download Space Not Enough Alert"
        
        title = NSLocalizedString("Space Not Enough", comment: comment)
        message = NSLocalizedString("You don't have enough remaining space to download this book.", comment: comment)
        addAction(LocalizedStrings.ok)
    }
}

class RefreshLibraryLanguageFilterAlert: AlertOperation {
    let context = UIApplication.appDelegate.managedObjectContext
    init(libraryOnlineTBVC: LibraryOnlineTBVC?) {
        super.init(presentationContext: libraryOnlineTBVC)
        
        var preferredLanguageCodes = [String]()
        var preferredLanguageNames = [String]()
        
        for code in Locale.preferredLanguages {
            guard let code = code.components(separatedBy: "-").first else {continue}
            guard let name = Locale.current.displayName(forKey: Locale.Key.identifier, value: code) else {continue}
            preferredLanguageCodes.append(code)
            preferredLanguageNames.append(name)
        }
        print(preferredLanguageCodes)
        
        let languageString: String = {
            switch preferredLanguageNames.count {
            case 0:
                return ""
            case 1:
                return preferredLanguageNames[0]
            case 2:
                return andJoinedString(preferredLanguageNames[0], b: preferredLanguageNames[1])
            default:
                let last = preferredLanguageNames.popLast()!
                let secondToLast = preferredLanguageNames.popLast()!
                return preferredLanguageNames.joined(separator: ", ") + ", " + andJoinedString(secondToLast, b: last)
            }
        }()
        
        let comment = "Library: Language Filter Alert"
        
        title = NSLocalizedString("Only Show Preferred Language?", comment: comment)
        message = NSLocalizedString("We have found you may know \(languageString), would you like to filter the library by these languages?", comment: comment)
        addAction(LocalizedStrings.ok, style: .default) { (action) in
            self.context.perform({
                let languages = Language.fetchAll(self.context)
                for language in languages {
                    guard let code = language.code else {continue}
                    language.isDisplayed = preferredLanguageCodes.contains(code)
                }
                libraryOnlineTBVC?.refreshFetchedResultController()
            })
        }
        addAction(LocalizedStrings.cancel)
    }
    
    override func finished(_ errors: [NSError]) {
        Preference.libraryHasShownPreferredLanguagePrompt = true
    }
    
    func andJoinedString(_ a: String, b: String) -> String {
        return a + " " + LocalizedStrings.and + " " + b
    }
}

class RefreshLibraryInternetRequiredAlert: AlertOperation {
    override init(presentationContext: UIViewController?) {
        super.init(presentationContext: presentationContext)
        
        let comment = "Library: Internet Required Alert"
        
        title = NSLocalizedString("Internet Connection Required", comment: comment)
        message = NSLocalizedString("You need to connect to the Internet to refresh the library.", comment: comment)
        addAction(LocalizedStrings.ok)
    }
}

class GetStartedAlert: AlertOperation {
    init(mainController: MainController?) {
        super.init(presentationContext: mainController)
        
        let comment = "First Time Launch Message"
        
        title = NSLocalizedString("Welcome to Kiwix", comment: comment)
        message = NSLocalizedString("Add a Book to Get Started", comment: comment)
        addAction(NSLocalizedString("Download", comment: comment), style: .default) { (alert) in
            mainController?.showLibraryButtonTapped()
        }
        addAction(NSLocalizedString("Import", comment: comment), style: .default) { (alert) in
            let operation = ShowHelpPageOperation(type: .ImportBookLearnMore, presentationContext: mainController)
            GlobalOperationQueue.sharedInstance.addOperation(operation)
        }
        addAction(NSLocalizedString("Dismiss", comment: comment))
    }
}

// MARK: - Help Pages

class ShowHelpPageOperation: Operation {
    private let type: WebViewControllerContentType
    private weak var presentationContext: UIViewController?
    
    init(type: WebViewControllerContentType, presentationContext: UIViewController?) {
        self.type = type
        self.presentationContext = presentationContext
    }
    
    override func execute() {
        OperationQueue.main.addOperation { 
            guard let controller = UIStoryboard.setting.instantiateViewController(withIdentifier: "WebViewController") as? WebViewController else {return}
            controller.page = self.type
            let navController = UINavigationController(rootViewController: controller)
            self.presentationContext?.present(navController, animated: true, completion: nil)
        }
    }
}

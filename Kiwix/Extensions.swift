//
//  Extensions.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
    import UIKit
#elseif os(OSX)
    import AppKit
#endif

// MARK: - App Delegate Accessor

#if os(iOS) || os(watchOS) || os(tvOS)
    extension UIApplication {
        class var appDelegate: AppDelegate {
            return UIApplication.shared().delegate as! AppDelegate
        }
    }
#elseif os(OSX)
    extension NSApplication {
        class var appDelegate: AppDelegate {
            return NSApplication.sharedApplication().delegate as! AppDelegate
        }
    }
#endif

// MARK: - Model

extension Locale {
    class var preferredLangCodes: [String] {
        let preferredLangNames = self.preferredLanguages
        var preferredLangCodes = Set<String>()
        for lang in preferredLangNames {
            guard let code = lang.components(separatedBy: "-").first else {continue}
            preferredLangCodes.insert(Locale.canonicalLanguageIdentifier(from: code))
        }
        return Array(preferredLangCodes)
    }
}

extension Bundle {
    class var appShortVersion: String {
        return (Bundle.main.objectForInfoDictionaryKey("CFBundleShortVersionString") as? String) ?? ""
    }
    
    class var buildVersion: String {
        return (Bundle.main.objectForInfoDictionaryKey(kCFBundleVersionKey as String) as? String) ?? "Unknown"
    }
}



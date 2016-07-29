//
//  Utilities.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class Utilities: NSObject {
    
    class func truncatedPlaceHolderString(_ string: String?, searchBar: UISearchBar) -> String? {
        guard let string = string else {return nil}
        guard let label = searchBar.value(forKey: "_searchField") as? UITextField else {return nil}
        guard let labelFont = label.font else {return nil}
        let preferredSize = CGSize(width: searchBar.frame.width - 45.0, height: 1000)
        var rect = (string as NSString).boundingRect(with: preferredSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
        
        var truncatedString = string as NSString
        var istruncated = false
        while rect.height > label.frame.height {
            istruncated = true
            truncatedString = truncatedString.substring(to: truncatedString.length - 2)
            rect = truncatedString.boundingRect(with: preferredSize, options: NSStringDrawingOptions.usesLineFragmentOrigin, attributes: [NSFontAttributeName: labelFont], context: nil)
        }
        return truncatedString as String + (istruncated ? "..." : "")
    }
    
    class func contentOfFileAtPath(_ path: String) -> String? {
        do {
            return try String(contentsOfFile: path)
        } catch {
            return nil
        }
    }
}

extension UIDevice {
    class var availableDiskSpace: Int64? {
        do {
            let docDirPath = NSSearchPathForDirectoriesInDomains(Foundation.FileManager.SearchPathDirectory.documentDirectory, Foundation.FileManager.SearchPathDomainMask.userDomainMask, true).first!
            let systemAttributes = try Foundation.FileManager.default.attributesOfFileSystem(forPath: docDirPath)
            guard let freeSize = systemAttributes[FileAttributeKey.systemFreeSize] as? NSNumber else {return nil}
            return freeSize.int64Value
        } catch let error as NSError {
            print("Fetch system disk free space failed, error: \(error.localizedDescription)")
            return nil
        }
    }
}

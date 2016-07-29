//
//  StringTools.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Foundation

extension String {
    static func formattedDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd-yyyy"
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    static func formattedFileSizeString(_ fileBytes: Int64?) -> String {
        guard let fileBytes = fileBytes else {return LocalizedStrings.unknown}
        return ByteCountFormatter.string(fromByteCount: fileBytes, countStyle: .file)
    }
    
    static func formattedPercentString(_ double: Double) -> String? {
        let number = NSNumber(value: double)
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumIntegerDigits = 3
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale.current
        return formatter.string(from: number)
    }
    
    static func formattedNumberString(_ double: Double) -> String {
        let sign = ((double < 0) ? "-" : "" )
        let abs = fabs(double)
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
}

class LocalizedStrings {
    // Basic
    class var yes: String {return NSLocalizedString("Yes", comment: "Basic")}
    class var no: String {return NSLocalizedString("No", comment: "Basic")}
    class var on: String {return NSLocalizedString("On", comment: "Basic")}
    class var off: String {return NSLocalizedString("Off", comment: "Basic")}
    class var and: String {return NSLocalizedString("and", comment: "Basic")}
    class var ok: String {return NSLocalizedString("OK", comment: "Basic")}
    class var cancel: String {return NSLocalizedString("Cancel", comment: "Basic")}
    class var others: String {return NSLocalizedString("Others", comment: "Basic")}
    class var unknown: String {return NSLocalizedString("Unknown", comment: "Basic")}
    class var disabled: String {return NSLocalizedString("Disabled", comment: "Basic")}
    class var remove: String {return NSLocalizedString("Remove", comment: "Basic")}
    class var delete: String {return NSLocalizedString("Delete", comment: "Basic")}
    class var refreshing: String {return NSLocalizedString("Refreshing...", comment: "Basic")}
    class var history: String {return NSLocalizedString("History", comment: "Basic")}
    
    // MARK: - OS X
    class var General: String {return NSLocalizedString("General", comment: "OS X, Preference")}
    class var Library: String {return NSLocalizedString("Library", comment: "OS X, Preference")}
    class var ZimFiles: String {return NSLocalizedString("Zim Files", comment: "OS X, Preference")}
}

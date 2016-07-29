//
//  iOSExtensions.swift
//  Kiwix
//
//  Created by Chris Li on 5/17/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// MARK: - CoreData

extension NSFetchedResultsController {
    func performFetch(deleteCache: Bool) {
        do {
            if deleteCache {
                guard let cacheName = cacheName else {return}
                NSFetchedResultsController.deleteCache(withName: cacheName)
            }
            
            try performFetch()
        } catch let error as NSError {
            print("FetchedResultController performFetch failed: \(error.localizedDescription)")
        }
    }
}

extension NSManagedObjectContext {
    class var mainQueueContext: NSManagedObjectContext {
        return (UIApplication.shared().delegate as! AppDelegate).managedObjectContext
    }
}

// MARK: - UI

enum BuildStatus {
    case alpha, beta, release
}

extension UIApplication {
    class var buildStatus: BuildStatus {
        get {
            return .release
        }
    }
}

extension UIStoryboard {
    class var library: UIStoryboard {get {return UIStoryboard(name: "Library", bundle: nil)}}
    class var main: UIStoryboard {get {return UIStoryboard(name: "Main", bundle: nil)}}
    class var search: UIStoryboard {get {return UIStoryboard(name: "Search", bundle: nil)}}
    class var setting: UIStoryboard {get {return UIStoryboard(name: "Setting", bundle: nil)}}
    class var welcome: UIStoryboard {get {return UIStoryboard(name: "Welcome", bundle: nil)}}
    
    func initViewController<T:UIViewController>(_ type: T.Type) -> T? {
        guard let className = NSStringFromClass(T).components(separatedBy: ".").last else {
            print("NSManagedObjectExtension: Unable to get class name")
            return nil
        }
        return instantiateViewController(withIdentifier: className) as? T
    }
    
    func initViewController<T:UIViewController>(_ identifier: String, type: T.Type) -> T? {
        return instantiateViewController(withIdentifier: identifier) as? T
    }
    
    func controller<T:UIViewController>(_ type: T.Type) -> T? {
        return instantiateViewController(withIdentifier: String(T)) as? T
    }
}

extension UIColor {
    class var havePicTintColor: UIColor {
        return UIColor(red: 255.0/255.0, green: 153.0/255.0, blue: 51.0/255.0, alpha: 1.0)
    }
    
    class var themeColor: UIColor {
        return UIColor(red: 71.0 / 255.0, green: 128.0 / 255.0, blue: 182.0 / 255.0, alpha: 1.0)
    }
}

extension UITableView {
    
    func setBackgroundText(_ text: String?) {
        let label = UILabel()
        label.textAlignment = .center
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 20.0)
        label.numberOfLines = 0
        label.textColor = UIColor.gray()
        backgroundView = label
    }
}

extension UINavigationBar {
    func hideBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView!.isHidden = true
    }
    
    func showBottomHairline() {
        let navigationBarImageView = hairlineImageViewInNavigationBar(self)
        navigationBarImageView!.isHidden = false
    }
    
    private func hairlineImageViewInNavigationBar(_ view: UIView) -> UIImageView? {
        if view.isKind(of: UIImageView.self) && view.bounds.height <= 1.0 {
            return (view as! UIImageView)
        }
        
        let subviews = (view.subviews as [UIView])
        for subview: UIView in subviews {
            if let imageView: UIImageView = hairlineImageViewInNavigationBar(subview) {
                return imageView
            }
        }
        return nil
    }
}

extension UIToolbar {
    func hideHairline() {
        let navigationBarImageView = hairlineImageViewInToolbar(self)
        navigationBarImageView!.isHidden = true
    }
    
    func showHairline() {
        let navigationBarImageView = hairlineImageViewInToolbar(self)
        navigationBarImageView!.isHidden = false
    }
    
    private func hairlineImageViewInToolbar(_ view: UIView) -> UIImageView? {
        if view.isKind(of: UIImageView.self) && view.bounds.height <= 1.0 {
            return (view as! UIImageView)
        }
        
        let subviews = (view.subviews as [UIView])
        for subview: UIView in subviews {
            if let imageView: UIImageView = hairlineImageViewInToolbar(subview) {
                return imageView
            }
        }
        return nil
    }
}

// MARK: - View Controller

extension UIAlertController {
    convenience init(title: String, message: String, style: UIAlertControllerStyle = .alert, actions:[UIAlertAction]) {
        self.init(title: title, message: message , preferredStyle: style)
        for action in actions {addAction(action)}
    }
}

//
//  BookmarkController.swift
//  Kiwix
//
//  Created by Chris Li on 7/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class BookmarkController: UIViewController {
    
    var bookmarkAdded = true
    private var timer: Foundation.Timer?
    
    @IBOutlet weak var centerView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var centerViewYOffset: NSLayoutConstraint!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNeedsStatusBarAppearanceUpdate()
        label.text = bookmarkAdded ? NSLocalizedString("Bookmarked", comment: "Bookmark Overlay") : NSLocalizedString("Removed", comment: "Bookmark Overlay")
        messageLabel.text = NSLocalizedString("Tap anywhere to dismiss", comment: "Bookmark Overlay")
        messageLabel.alpha = 1.0
        imageView.isHighlighted = !bookmarkAdded
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        timer = Foundation.Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(BookmarkController.dismissSelf), userInfo: nil, repeats: false)
    }
    
    @IBAction func tapRecognized(_ sender: UITapGestureRecognizer) {
        dismissSelf()
    }
    
    func dismissSelf() {
        dismiss(animated: true, completion: nil)
    }
    
    var topHalfHeight: CGFloat {
        return centerView.frame.height / 2 + imageView.frame.height
    }
    
    var bottomHalfHeight: CGFloat {
        return centerView.frame.height / 2 + label.frame.height
    }
}

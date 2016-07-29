//
//  MainControllerShowHide.swift
//  Kiwix
//
//  Created by Chris Li on 7/20/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

extension MainController {
    
    func hidePresentedController(_ animated: Bool, completion: (() -> Void)? = nil) {
        guard let controller = presentedViewController else {
            completion?()
            return
        }
        controller.dismiss(animated: animated, completion: completion)
    }
    
    // MARK: - Show/Hide Search
    
    func showSearch(animated: Bool) {
        navigationController?.setToolbarHidden(true, animated: animated)
        showSearchResultController(animated: animated)
        searchBar.placeholder = LocalizedStrings.search
        if !searchBar.isFirstResponder() {
            searchBar.becomeFirstResponder()
        }
        if traitCollection.horizontalSizeClass == .compact {
            searchBar.setShowsCancelButton(true, animated: animated)
        }
        if UIDevice.current().userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact {
            navigationItem.setRightBarButton(cancelButton, animated: animated)
        }
        if isShowingTableOfContents && traitCollection.horizontalSizeClass == .compact {
            animateOutTableOfContentsController()
        }
    }
    
    func hideSearch(animated: Bool) {
        hideSearchResultController(animated: true)
        searchBar.setShowsCancelButton(false, animated: animated)
        searchBar.text = nil
        if searchBar.isFirstResponder() {
            searchBar.resignFirstResponder()
        }
        if UIDevice.current().userInterfaceIdiom == .pad && traitCollection.horizontalSizeClass == .compact {
            navigationItem.setRightBarButton(nil, animated: animated)
        }
    }
    
    private func showSearchResultController(animated: Bool) {
        guard let searchController = searchController ?? UIStoryboard.search.instantiateInitialViewController() as? SearchController else {return}
        self.searchController = searchController
        guard !childViewControllers.contains(searchController) else {return}
        addChildViewController(searchController)
        searchController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchController.view)
        
        let views = ["SearchController": searchController.view]
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[SearchController]|", options: .alignAllCenterY, metrics: nil, views: views))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[SearchController]|", options: .alignAllCenterX, metrics: nil, views: views))
        
        if animated {
            searchController.view.alpha = 0.5
            searchController.view.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .curveEaseOut, animations: { () -> Void in
                searchController.view.alpha = 1.0
                searchController.view.transform = CGAffineTransform.identity
            }) { (completed) -> Void in
                searchController.didMove(toParentViewController: self)
            }
        } else {
            searchController.view.alpha = 1.0
            searchController.view.transform = CGAffineTransform.identity
            searchController.didMove(toParentViewController: self)
        }
    }
    
    private func hideSearchResultController(animated: Bool) {
        guard let searchController = childViewControllers.flatMap({$0 as? SearchController}).first else {return}
        let completion = { (complete: Bool) -> Void in
            searchController.view.removeFromSuperview()
            searchController.removeFromParentViewController()
            guard self.traitCollection.horizontalSizeClass == .compact else {return}
            self.navigationController?.setToolbarHidden(false, animated: animated)
        }
        
        searchController.willMove(toParentViewController: nil)
        if animated {
            UIView.animate(withDuration: 0.15, delay: 0.0, options: .beginFromCurrentState, animations: { 
                searchController.view.alpha = 0.0
                searchController.view.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
                }, completion: completion)
        } else {
            completion(true)
        }
    }
    
    // MARK: - Show/Hide TOC
    
    func animateInTableOfContentsController() {
        isShowingTableOfContents = true
        tocVisiualEffectView.isHidden = false
        dimView.isHidden = false
        dimView.alpha = 0.0
        view.layoutIfNeeded()
        tableOfContentsController?.headings = getTableOfContents(webView)
        configureTOCViewConstraints()
        UIView.animate(withDuration: 0.3, delay: 0.0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.5
        }) { (completed) in
            
        }
    }
    
    func animateOutTableOfContentsController() {
        isShowingTableOfContents = false
        view.layoutIfNeeded()
        configureTOCViewConstraints()
        UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseIn, animations: {
            self.view.layoutIfNeeded()
            self.dimView.alpha = 0.0
        }) { (completed) in
            self.dimView.isHidden = true
            self.tocVisiualEffectView.isHidden = true
        }
    }
    
    func configureTOCViewConstraints() {
        switch traitCollection.horizontalSizeClass {
        case .compact:
            let tocHeight: CGFloat = {
                guard let controller = tableOfContentsController else {return floor(view.frame.height * 0.4)}
                let tocContentHeight = controller.tableView.contentSize.height
                guard controller.headings.count != 0 else {return floor(view.frame.height * 0.4)}
                let toolBarHeight: CGFloat = traitCollection.horizontalSizeClass == .regular ? 0.0 : (traitCollection.verticalSizeClass == .compact ? 32.0 : 44.0)
                return min(tocContentHeight + toolBarHeight, floor(view.frame.height * 0.65))
            }()
            tocHeightConstraint.constant = tocHeight
            tocTopToSuperViewBottomSpacing.constant = isShowingTableOfContents ? tocHeight : 0.0
        case .regular:
            tocLeadSpacing.constant = isShowingTableOfContents ? 0.0 : 270
            break
        default:
            break
        }
    }
    
    // MARK: - Show Bookmark
    
    func showBookmarkTBVC() {
        guard let controller = bookmarkNav ?? UIStoryboard.main.initViewController("BookmarkNav", type: UINavigationController.self) else {return}
        bookmarkNav = controller
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Show/Hide Welcome
    
    func showWelcome() {
        guard let controller = welcomeController ?? UIStoryboard.welcome.instantiateInitialViewController() else {return}
        welcomeController = controller
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(controller)
        view.addSubview(controller.view)
        
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: NSLayoutFormatOptions.alignAllTop, metrics: nil, views: ["view": controller.view]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: NSLayoutFormatOptions.alignAllLeft, metrics: nil, views: ["view": controller.view]))
        
        controller.didMove(toParentViewController: self)
    }
    
    func hideWelcome() {
        guard let controller = welcomeController else {return}
        controller.removeFromParentViewController()
        controller.view.removeFromSuperview()
    }
    
    // MARK: - Show/Hide Get Started
    
    func showGetStarted() {
        guard let controller = UIStoryboard.welcome.initViewController(GetStartedController.self) else {return}
        controller.modalPresentationStyle = .formSheet
        present(controller, animated: true, completion: nil)
    }
    
    // MARK: - Show First Time Launch Alert
    
    func showGetStartedAlert() {
        guard !Preference.hasShowGetStartedAlert else {return}
        let operation = GetStartedAlert(mainController: self)
        GlobalOperationQueue.sharedInstance.addOperation(operation)
        Preference.hasShowGetStartedAlert = true
    }
}

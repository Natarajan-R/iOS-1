//
//  MainControllerOtherD.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import SafariServices
import JavaScriptCore

extension MainController: LPTBarButtonItemDelegate, TableOfContentsDelegate, ZimMultiReaderDelegate, UISearchBarDelegate, UIPopoverPresentationControllerDelegate, UIWebViewDelegate, SFSafariViewControllerDelegate, UIScrollViewDelegate, UIViewControllerTransitioningDelegate {
    
    // MARK: - LPTBarButtonItemDelegate
    
    func barButtonTapped(_ sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        showBookmarkTBVC()
    }
    
    func barButtonLongPressedStart(_ sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender == bookmarkButton else {return}
        guard !webView.isHidden else {return}
        guard let article = article else {return}
        
        article.isBookmarked = !article.isBookmarked
        if article.isBookmarked {article.bookmarkDate = Date()}
        if article.snippet == nil {article.snippet = getSnippet(webView)}
        
        let operation = UpdateWidgetDataSourceOperation()
        GlobalOperationQueue.sharedInstance.addOperation(operation)
        
        guard let controller = bookmarkController ?? UIStoryboard.main.initViewController("BookmarkController", type: BookmarkController.self) else {return}
        bookmarkController = controller
        controller.bookmarkAdded = article.isBookmarked
        controller.transitioningDelegate = self
        controller.modalPresentationStyle = .overFullScreen
        present(controller, animated: true, completion: nil)
        configureBookmarkButton()
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkControllerAnimator(animateIn: true)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return BookmarkControllerAnimator(animateIn: false)
    }
    
    // MARK: - TableOfContentsDelegate
    
    func scrollTo(_ heading: HTMLHeading) {
        webView.stringByEvaluatingJavaScript(from: heading.scrollToJavaScript)
        if traitCollection.horizontalSizeClass == .compact {
            animateOutTableOfContentsController()
        }
    }
    
    // MARK: - ZimMultiReaderDelegate
    
    func firstBookAdded() {
        guard let id = ZimMultiReader.sharedInstance.readers.keys.first else {return}
        loadMainPage(id)
    }
    
    // MARK: - UISearchBarDelegate
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        showSearch(animated: true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        hideSearch(animated: true)
        configureSearchBarPlaceHolder()
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        searchController?.startSearch(searchText, delayed: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchController?.searchResultTBVC?.selectFirstResultIfPossible()
    }
    
    // MARK: -  UIPopoverPresentationControllerDelegate
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    
    // MARK: - UIWebViewDelegate
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        guard let url = request.url else {return true}
        if url.scheme == "kiwix" {
            return true
        } else {
            let svc = SFSafariViewController(url: url)
            svc.delegate = self
            present(svc, animated: true, completion: nil)
            return false
        }
    }
    
    func webViewDidStartLoad(_ webView: UIWebView) {
        PacketAnalyzer.sharedInstance.startListening()
    }
    
    func webViewDidFinishLoad(_ webView: UIWebView) {
        guard let url = webView.request?.url else {return}
        guard url.scheme?.caseInsensitiveCompare("Kiwix") == .orderedSame else {return}
        
        let title = webView.stringByEvaluatingJavaScript(from: "document.title")
        let managedObjectContext = UIApplication.appDelegate.managedObjectContext
        guard let bookID = url.host else {return}
        guard let book = Book.fetch(bookID, context: managedObjectContext) else {return}
        guard let article = Article.addOrUpdate(title, url: url, book: book, context: managedObjectContext) else {return}
        
        self.article = article
        if let image = PacketAnalyzer.sharedInstance.chooseImage() {
            article.thumbImageURL = image.url.absoluteString
        }
        
        configureSearchBarPlaceHolder()
        injectTableWrappingJavaScriptIfNeeded()
        adjustFontSizeIfNeeded()
        configureNavigationButtonTint()
        configureBookmarkButton()
        
        if traitCollection.horizontalSizeClass == .regular && isShowingTableOfContents {
            tableOfContentsController?.headings = getTableOfContents(webView)
        }
        
        PacketAnalyzer.sharedInstance.stopListening()
    }
    
    // MARK: - Javascript
    
    func injectTableWrappingJavaScriptIfNeeded() {
        if Preference.webViewInjectJavascriptToAdjustPageLayout {
            if traitCollection.horizontalSizeClass == .compact {
                guard let path = Bundle.main.pathForResource("adjustlayoutiPhone", ofType: "js") else {return}
                guard let jString = Utilities.contentOfFileAtPath(path) else {return}
                webView.stringByEvaluatingJavaScript(from: jString)
            } else {
                guard let path = Bundle.main.pathForResource("adjustlayoutiPad", ofType: "js") else {return}
                guard let jString = Utilities.contentOfFileAtPath(path) else {return}
                webView.stringByEvaluatingJavaScript(from: jString)
            }
        }
    }
    
    func adjustFontSizeIfNeeded() {
        let zoomScale = Preference.webViewZoomScale
        guard zoomScale != 100.0 else {return}
        let jString = String(format: "document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= '%.0f%%'", zoomScale)
        webView.stringByEvaluatingJavaScript(from: jString)
    }
    
    func getTableOfContents(_ webView: UIWebView) -> [HTMLHeading] {
        guard let context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext,
            let path = Bundle.main.pathForResource("getTableOfContents", ofType: "js"),
            let jString = Utilities.contentOfFileAtPath(path),
            let elements = context.evaluateScript(jString).toArray() as? [[String: String]] else {return [HTMLHeading]()}
        var headings = [HTMLHeading]()
        for element in elements {
            guard let heading = HTMLHeading(rawValue: element) else {continue}
            headings.append(heading)
        }
        return headings
    }
    
    func getSnippet(_ webView: UIWebView) -> String? {
        guard let context = webView.value(forKeyPath: "documentView.webView.mainFrame.javaScriptContext") as? JSContext,
            let path = Bundle.main.pathForResource("getSnippet", ofType: "js"),
            let jString = Utilities.contentOfFileAtPath(path),
            let snippet = context.evaluateScript(jString).toString() else {return nil}
        return snippet
    }
    
    // MARK: - UIPopoverPresentationControllerDelegate
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentSize.height >= scrollView.frame.height else {return}
        guard let navigationBar = navigationController?.navigationBar else {return}
        guard scrollView.contentOffset.y > 100 else {return}
        
        // Calculate current YOffset but without elasticity
        let currentScrollViewYOffset: CGFloat = {
            let topInset = scrollView.contentInset.top
            let bottomInset = scrollView.contentInset.bottom
            let minYOffset = -topInset
            let maxYOffset = scrollView.contentSize.height + bottomInset - scrollView.frame.height
            return max(minYOffset, min(scrollView.contentOffset.y, maxYOffset))
        }()
        
        // delta content offset y, scroll up minus, scroll down plus
        let yDelta = previousScrollViewYOffset - currentScrollViewYOffset
        
        // Slide up nav bar
        let navOriginY = max(20.0 - 44.0, min(navigationBar.frame.origin.y + yDelta, 20.0))
        let navFrame = CGRect(x: 0, y: navOriginY, width: navigationBar.frame.width, height: navigationBar.frame.height)
        navigationBar.frame = navFrame
        
        // Slide down tool bar
        if let toolBar = navigationController?.toolbar {
            let originY = max(view.frame.height - 44.0, min(toolBar.frame.origin.y - yDelta, view.frame.height))
            let frame = CGRect(x: 0, y: originY, width: toolBar.frame.width, height: toolBar.frame.height)
            toolBar.frame = frame
        }
        
        // Shrink nav bar
        //let newNavBarHeight = max(navBarMinHeight, min(navigationBar.frame.height + yDelta, 44.0))
        //let navFrame = CGRectMake(0, navigationBar.frame.origin.y, navigationBar.frame.width, newNavBarHeight)
        //navigationBar.frame = navFrame
        
        updateNavBarItems()
        configureWebViewInsets()
        previousScrollViewYOffset = currentScrollViewYOffset
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        stoppedScrolling()
    }
    
    func updateNavBarItems() {
        guard let navigationBar = navigationController?.navigationBar else {return}
        let min: CGFloat = 20.0 - 44.0
        let max: CGFloat = 20.0
        let alpha = (navigationBar.frame.origin.y - min) / (max - min)
        navigationItem.titleView?.alpha = alpha
    }
    
    func stoppedScrolling() {
        guard let navigationBar = navigationController?.navigationBar else {return}
        let show = ((navigationBar.frame.origin.y - (20-44)) / 44) > 0.5
        animateBar(show)
    }
    
    func animateBar(_ show: Bool) {
        UIView.animate(withDuration: 0.2) { () -> Void in
            if show {
                if let navBar = self.navigationController?.navigationBar {
                    navBar.frame = CGRect(x: 0, y: 20, width: navBar.frame.width, height: navBar.frame.height)
                }
                if let toolBar = self.navigationController?.toolbar {
                    toolBar.frame = CGRect(x: 0, y: self.view.frame.height - toolBar.frame.height, width: toolBar.frame.width, height: toolBar.frame.height)
                }
                self.navigationItem.titleView?.alpha = 1.0
            } else {
                if let navBar = self.navigationController?.navigationBar {
                    navBar.frame = CGRect(x: 0, y: 20 - 44, width: navBar.frame.width, height: navBar.frame.height)
                }
                if let toolBar = self.navigationController?.toolbar {
                    toolBar.frame = CGRect(x: 0, y: self.view.frame.height, width: toolBar.frame.width, height: toolBar.frame.height)
                }
                self.navigationItem.titleView?.alpha = 0.0
            }
        }
    }
    
}

class HTMLHeading {
    let id: String
    let tagName: String
    let textContent: String
    let level: Int
    
    init?(rawValue: [String: String]) {
        let tagName = rawValue["tagName"] ?? ""
        self.id = rawValue["id"] ?? ""
        self.textContent = rawValue["textContent"] ?? ""
        self.tagName = tagName
        self.level = Int(tagName.replacingOccurrences(of: "H", with: "")) ?? -1
        
        if id == "" {return nil}
        if tagName == "" {return nil}
        if textContent == "" {return nil}
        if level == -1 {return nil}
    }
    
    var scrollToJavaScript: String {
        return "document.getElementById('\(id)').scrollIntoView();"
    }
}

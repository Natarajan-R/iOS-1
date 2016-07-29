
//
//  MainController.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import Operations

class MainController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    @IBOutlet weak var dimView: UIView!
    @IBOutlet weak var tocVisiualEffectView: UIVisualEffectView!
    @IBOutlet weak var tocTopToSuperViewBottomSpacing: NSLayoutConstraint!
    @IBOutlet weak var tocHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tocLeadSpacing: NSLayoutConstraint!
    
    var tableOfContentsController: TableOfContentsController?
    var bookmarkController: BookmarkController?
    var bookmarkNav: UIViewController?
    var libraryController: UIViewController?
    var settingController: UIViewController?
    var searchController: SearchController?
    var welcomeController: UIViewController?
    let searchBar = SearchBar()
    
    var context: UnsafeMutablePointer<Void>? = nil
    var article: Article? {
        willSet(newArticle) {
            article?.removeObserver(self, forKeyPath: "isBookmarked")
            newArticle?.addObserver(self, forKeyPath: "isBookmarked", options: .new, context: context)
        }
    }
    
    private var webViewInitialURL: URL?
    
    var navBarOriginalHeight: CGFloat = 0.0
    let navBarMinHeight: CGFloat = 10.0
    var previousScrollViewYOffset: CGFloat = 0.0
    
    var isShowingTableOfContents = false
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView.delegate = self
        webView.scrollView.delegate = nil
        
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        ZimMultiReader.sharedInstance.delegate = self
        
        UserDefaults.standard.addObserver(self, forKeyPath: "webViewNotInjectJavascriptToAdjustPageLayout", options: .new, context: context)
        UserDefaults.standard.addObserver(self, forKeyPath: "webViewZoomScale", options: .new, context: context)
        configureButtonColor()
        showGetStartedAlert()
        showWelcome()
        load(webViewInitialURL)
    }
    
    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "webViewNotInjectJavascriptToAdjustPageLayout")
        UserDefaults.standard.removeObserver(self, forKeyPath: "webViewZoomScale")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: AnyObject?, change: [NSKeyValueChangeKey : AnyObject]?, context: UnsafeMutablePointer<Void>?) {
        guard context == self.context, let keyPath = keyPath else {return}
        switch keyPath {
        case "webViewZoomScale", "webViewNotInjectJavascriptToAdjustPageLayout":
            webView.reload()
        case "isBookmarked":
            configureBookmarkButton()
        default:
            return
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        tableOfContentsController = nil
        bookmarkController = nil
        bookmarkNav = nil
        libraryController = nil
        settingController = nil
        searchController = nil
        welcomeController = nil
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.horizontalSizeClass != traitCollection.horizontalSizeClass {
            configureUIElements(traitCollection.horizontalSizeClass)
        }
        configureTOCViewConstraints()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbeddedTOCController" {
            guard let destinationViewController = segue.destinationViewController as? TableOfContentsController else {return}
            tableOfContentsController = destinationViewController
            tableOfContentsController?.delegate = self
        }
    }
    
    // MARK: - Load
    
    func load(_ url: URL?) {
        if webView == nil {
            webViewInitialURL = url
            return
        }
        guard let url = url else {return}
        webView.isHidden = false
        hideWelcome()
        let request = URLRequest(url: url)
        webView.loadRequest(request)
    }
    
    func loadMainPage(_ id: ZimID) {
        guard let reader = ZimMultiReader.sharedInstance.readers[id] else {return}
        let mainPageURLString = reader.mainPageURL()
        let mainPageURL = URL.kiwixURLWithZimFileid(id, contentURLString: mainPageURLString)
        load(mainPageURL)
    }
    
    // MARK: - Configure
    
    func configureUIElements(_ horizontalSizeClass: UIUserInterfaceSizeClass) {
        switch horizontalSizeClass {
        case .regular:
            navigationController?.isToolbarHidden = true
            toolbarItems?.removeAll()
            navigationItem.leftBarButtonItems = [navigateLeftButton, navigateRightButton, tableOfContentButton]
            navigationItem.rightBarButtonItems = [settingButton, libraryButton, bookmarkButton]
            searchBar.setShowsCancelButton(false, animated: true)
        case .compact:
            if !searchBar.isFirstResponder() {navigationController?.isToolbarHidden = false}
            if searchBar.isFirstResponder() {searchBar.setShowsCancelButton(true, animated: true)}
            navigationItem.leftBarButtonItems?.removeAll()
            navigationItem.rightBarButtonItems?.removeAll()
            let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbarItems = [navigateLeftButton, spaceButton, navigateRightButton, spaceButton, tableOfContentButton, spaceButton, bookmarkButton, spaceButton, libraryButton, spaceButton, settingButton]            
            if UIDevice.current().userInterfaceIdiom == .pad && searchBar.isFirstResponder() {
                navigationItem.setRightBarButton(cancelButton, animated: true)
            }
        case .unspecified:
            break
        }
    }
    
    func configureButtonColor() {
        configureNavigationButtonTint()
        tableOfContentButton.tintColor = UIColor.gray()
        libraryButton.tintColor = UIColor.gray()
        settingButton.tintColor = UIColor.gray()
        UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.themeColor
    }
    
    func configureNavigationButtonTint() {
        navigateLeftButton.tintColor = webView.canGoBack ? nil : UIColor.gray()
        navigateRightButton.tintColor = webView.canGoForward ? nil : UIColor.gray()
    }
    
    func configureBookmarkButton() {
        bookmarkButton.customImageView?.isHighlighted = article?.isBookmarked ?? false
    }
    
    func configureWebViewInsets() {
        let topInset: CGFloat = {
            guard let navigationBar = navigationController?.navigationBar else {return 44.0}
            return navigationBar.isHidden ? 0.0 : navigationBar.frame.origin.y + navigationBar.frame.height
        }()
        let bottomInset: CGFloat = {
            guard let toolbar = navigationController?.toolbar else {return 0.0}
            return traitCollection.horizontalSizeClass == .compact ? view.frame.height - toolbar.frame.origin.y : 0.0
        }()
        webView.scrollView.contentInset = UIEdgeInsetsMake(topInset, 0, bottomInset, 0)
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(topInset, 0, bottomInset, 0)
    }
    
    func configureSearchBarPlaceHolder() {
        if let title = article?.title {
            let placeHolder =  Utilities.truncatedPlaceHolderString(title, searchBar: searchBar)
            searchBar.placeholder = placeHolder
        } else {
            searchBar.placeholder = LocalizedStrings.search
        }
    }

    // MARK: - Buttons

    lazy var navigateLeftButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "LeftArrow", target: self, action: #selector(MainController.navigateLeftButtonTapped))
    lazy var navigateRightButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "RightArrow", target: self, action: #selector(MainController.navigateRightButtonTapped))
    lazy var tableOfContentButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "TableOfContent", target: self, action: #selector(MainController.showTableOfContentButtonTapped))
    lazy var bookmarkButton: LPTBarButtonItem = LPTBarButtonItem(imageName: "Star", highlightedImageName: "StarHighlighted", delegate: self)
    lazy var libraryButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Library", target: self, action: #selector(MainController.showLibraryButtonTapped))
    lazy var settingButton: UIBarButtonItem = UIBarButtonItem(imageNamed: "Setting", target: self, action: #selector(MainController.showSettingButtonTapped))
    lazy var cancelButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(MainController.cancelButtonTapped))
    
    // MARK: - Actions
    
    func navigateLeftButtonTapped() {
        webView.goBack()
    }
    
    func navigateRightButtonTapped() {
        webView.goForward()
    }
    
    func showTableOfContentButtonTapped(_ sender: UIBarButtonItem) {
        guard let _ = article else {return}
        if isShowingTableOfContents {
            animateOutTableOfContentsController()
        } else {
            animateInTableOfContentsController()
        }
    }
    
    func showLibraryButtonTapped() {
        guard let viewController = libraryController ?? UIStoryboard.library.instantiateInitialViewController() else {return}
        viewController.modalPresentationStyle = .formSheet
        libraryController = viewController
        present(viewController, animated: true, completion: nil)
    }
    
    func showSettingButtonTapped() {
        guard let viewController = settingController ?? UIStoryboard.setting.instantiateInitialViewController() else {return}
        viewController.modalPresentationStyle = .formSheet
        settingController = viewController
        present(viewController, animated: true, completion: nil)
    }
    
    func cancelButtonTapped() {
        hideSearch(animated: true)
        navigationItem.setRightBarButton(nil, animated: true)
    }
    
    @IBAction func dimViewTapGestureRecognizer(_ sender: UITapGestureRecognizer) {
        animateOutTableOfContentsController()
    }
}

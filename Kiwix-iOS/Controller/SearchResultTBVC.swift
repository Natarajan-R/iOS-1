//
//  SearchResultTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/13/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class SearchResultTBVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    var searchResults = [SearchResult]()
    
    var shouldClipRoundCorner: Bool {
        return traitCollection.verticalSizeClass == .regular && traitCollection.horizontalSizeClass == .regular
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.layer.cornerRadius = shouldClipRoundCorner ? 10.0 : 0.0
        tableView.layer.masksToBounds = shouldClipRoundCorner
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        NotificationCenter.default.addObserver(self, selector: #selector(SearchResultTBVC.keyboardDidShow(_:)), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SearchResultTBVC.keyboardWillHide(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        searchResults.removeAll()
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    func keyboardDidShow(_ notification: Notification) {
        guard let userInfo = (notification as NSNotification).userInfo as? [String: NSValue] else {return}
        guard let keyboardOrigin = userInfo[UIKeyboardFrameEndUserInfoKey]?.cgRectValue().origin else {return}
        let point = view.convert(keyboardOrigin, from: UIApplication.appDelegate.window)
        let buttomInset = view.frame.height - point.y
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, buttomInset, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, buttomInset, 0)
    }
    
    func keyboardWillHide(_ notification: Notification) {
        tableView.contentInset = UIEdgeInsetsMake(0.0, 0, 0, 0)
        tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0.0, 0, 0, 0)
    }
    
    func selectFirstResultIfPossible() {
        guard searchResults.count > 0 else {return}
        tableView.selectRow(at: IndexPath(row: 0, section: 0), animated: true, scrollPosition: .top)
        tableView(tableView, didSelectRowAt: IndexPath(row: 0, section: 0))
    }
    
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = searchResults[(indexPath as NSIndexPath).row]
        
        if result.snippet == nil {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleCell", for: indexPath) as! ArticleCell
            configureArticleCell(cell, result: result)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ArticleSnippetCell", for: indexPath) as! ArticleSnippetCell
            configureArticleCell(cell, result: result)
            cell.snippetLabel.text = result.snippet
            return cell
        }
    }
    
    func configureArticleCell(_ cell: ArticleCell, result: SearchResult) {
        guard let book = Book.fetch(result.bookID, context: UIApplication.appDelegate.managedObjectContext) else {return}
        if UIApplication.buildStatus == .alpha {
            cell.titleLabel.text = result.title + result.rankInfo
        } else {
            cell.titleLabel.text = result.title
        }
        cell.hasPicIndicator.backgroundColor = book.hasPic ? UIColor.havePicTintColor : UIColor.lightGray()
        cell.favIcon.image = book.favIcon != nil ? UIImage(data: book.favIcon!) : nil
    }
    
    // MARK: Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let mainVC = parent?.parent as? MainController else {return}
        let result = searchResults[(indexPath as NSIndexPath).row]
        let url = URL.kiwixURLWithZimFileid(result.bookID, articleTitle: result.title)
        mainVC.load(url)
        mainVC.hideSearch(animated: true)
    }

    // MARK: - Search
    
    func startSearch(_ searchText: String) {
        guard searchText != "" else {
            searchResults.removeAll()
            tableView.reloadData()
            return
        }
        let operation = SearchOperation(searchTerm: searchText) { (results) in
            guard let results = results else {return}
            self.searchResults = results
            self.tableView.reloadData()
            if results.count > 0 {
                self.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
        }
        ZimMultiReader.sharedInstance.startSearch(operation)
    }
}

extension LocalizedStrings {
    class var searchAddBookGuide: String {return NSLocalizedString("Add a book to get started", comment: "")}
}

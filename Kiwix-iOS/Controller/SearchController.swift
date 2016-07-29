//
//  SearchController.swift
//  Kiwix
//
//  Created by Chris Li on 1/30/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SearchController: UIViewController, UISearchBarDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var tabControllerContainer: UIView!
    @IBOutlet weak var searchResultTBVCContainer: UIView!
    @IBOutlet var tapGestureRecognizer: UITapGestureRecognizer!
    var searchResultTBVC: SearchResultTBVC?
    
    private var searchText = "" {
        didSet {
            configureViewVisibility()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tapGestureRecognizer.addTarget(self, action: #selector(SearchController.handleTap(_:)))
        tapGestureRecognizer.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureViewVisibility()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard searchText != "" else {return}
        Preference.recentSearchTerms.insert(searchText, at: 0)
        searchText = ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "EmbeddedSearchResultTBVC" {
            guard let destinationViewController = segue.destinationViewController as? SearchResultTBVC else {return}
            searchResultTBVC = destinationViewController
        }
    }
    
    func configureViewVisibility() {
        if searchText == "" {
            searchResultTBVCContainer.isHidden = true
            tabControllerContainer.isHidden = false
        } else {
            searchResultTBVCContainer.isHidden = false
            tabControllerContainer.isHidden = true
        }
    }
    
    // MARK: - Search
    
    func startSearch(_ searchText: String, delayed: Bool) {
        self.searchText = searchText
        if delayed {
            let previousSearchText = searchText
            DispatchQueue.main.after(when: DispatchTime.now() + Double(Int64(275 * USEC_PER_SEC)) / Double(NSEC_PER_SEC)) {
                //print("\(previousSearchText), \(self.searchText)")
                guard previousSearchText == self.searchText else {return}
                self.searchResultTBVC?.startSearch(self.searchText)
            }
        } else {
            searchResultTBVC?.startSearch(searchText)
        }
    }
    
    // MARK: - Handle Gesture
    
    func handleTap(_ tapGestureRecognizer: UIGestureRecognizer) {
        guard let mainVC = parent as? MainController else {return}
        mainVC.hideSearch(animated: true)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return touch.view == view ? true : false
    }
    
}

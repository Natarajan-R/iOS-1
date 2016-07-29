//
//  LibraryLocalBookDetailTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 4/7/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class LibraryLocalBookDetailTBVC: UITableViewController {

    var book: Book?
    let sections = [LocalizedStrings.info, LocalizedStrings.file]
    let titles = [[LocalizedStrings.title, LocalizedStrings.creationDate, LocalizedStrings.articleCount, LocalizedStrings.mediaCount],
                  [LocalizedStrings.size, LocalizedStrings.fileName]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = book?.title
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.isToolbarHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.isToolbarHidden = false
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return book == nil ? 0 : sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return titles[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.text = titles[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        cell.detailTextLabel?.text = "placehold"

        return cell
    }
}

extension LocalizedStrings {
    class var info: String {return NSLocalizedString("Info", comment: "Book Detail")}
    class var title: String {return NSLocalizedString("Title", comment: "Book Detail")}
    class var creationDate: String {return NSLocalizedString("Creation Date", comment: "Book Detail")}
    class var articleCount: String {return NSLocalizedString("Article Count", comment: "Book Detail")}
    class var mediaCount: String {return NSLocalizedString("Media Count", comment: "Book Detail")}
    
    class var file: String {return NSLocalizedString("File", comment: "Book Detail")}
    class var size: String {return NSLocalizedString("size", comment: "Book Detail")}
    class var fileName: String {return NSLocalizedString("File Name", comment: "Book Detail")}
}

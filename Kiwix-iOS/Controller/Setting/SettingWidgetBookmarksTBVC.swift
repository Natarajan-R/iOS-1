//
//  SettingWidgetBookmarksTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 7/26/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SettingWidgetBookmarksTBVC: UITableViewController {
    // widget row count
    private var rowCount = 1 {
        didSet {
            let defaults = UserDefaults(suiteName: "group.kiwix")
            defaults?.set(rowCount ?? 1, forKey: "BookmarkWidgetMaxRowCount")
        }
    }
    
    let options = [NSLocalizedString("One Row", comment: "Setting: Bookmark Widget"),
                   NSLocalizedString("Two Rows", comment: "Setting: Bookmark Widget"),
                   NSLocalizedString("Three Rows", comment: "Setting: Bookmark Widget")]
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        title = LocalizedStrings.bookmarks
        if let defaults = UserDefaults(suiteName: "group.kiwix") {
            rowCount = max(1, min(defaults.integer(forKey: "BookmarkWidgetMaxRowCount"), 3))
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = options[(indexPath as NSIndexPath).row]
        cell.accessoryType = (indexPath as NSIndexPath).row == (rowCount - 1) ? .checkmark : .none
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("Set the maximum number of rows displayed in Bookmarks Today Widget.", comment: "Setting: Bookmark Widget")
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let oldIndexPath = IndexPath(item: rowCount - 1, section: 0)
        guard let oldCell = tableView.cellForRow(at: oldIndexPath),
            let newCell = tableView.cellForRow(at: indexPath) else {return}
        oldCell.accessoryType = .none
        newCell.accessoryType = .checkmark
        rowCount = (indexPath as NSIndexPath).row + 1
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == 0 else {return}
        guard let view = view as? UITableViewHeaderFooterView else {return}
        view.textLabel?.textAlignment = .center
    }
}

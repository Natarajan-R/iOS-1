//
//  SettingSearchHistoryTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 7/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class SettingSearchHistoryTBVC: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Search History", comment: "Setting: Search History")
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = NSLocalizedString("Clear Search History", comment: "Setting: Search History")
        return cell
    }
 
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let delete = UIAlertAction(title: LocalizedStrings.delete, style: .destructive) { (action) in
            Preference.recentSearchTerms = []
            let ok = UIAlertAction(title: LocalizedStrings.ok, style: .default, handler: nil)
            let alert = UIAlertController(title: NSLocalizedString("Your search history has been cleared.", comment: "Setting: Search History"), message: "", actions: [ok])
            self.present(alert, animated: true, completion: nil)
        }
        let cancel = UIAlertAction(title: LocalizedStrings.cancel, style: .cancel, handler: nil)
        let alert = UIAlertController(title: NSLocalizedString("Are you sure?", comment: "Setting: Search History"),
                                      message: NSLocalizedString("This action is not recoverable.", comment: "Setting: Search History"),
                                      actions: [delete, cancel])
        present(alert, animated: true, completion: nil)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == tableView.numberOfSections - 1 else {return nil}
        return NSLocalizedString("Kiwix does not collect your search history data.", comment: "Setting: Search History")
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == tableView.numberOfSections - 1 else {return}
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textAlignment = .center
        }
    }
}

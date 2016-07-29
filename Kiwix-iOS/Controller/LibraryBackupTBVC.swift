//
//  LibraryBackupTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 6/14/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class LibraryBackupTBVC: UITableViewController {

    let toggle = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Backup", comment: "Setting: Backup local files title")
        toggle.addTarget(self, action: #selector(LibraryBackupTBVC.switcherValueChanged(_:)), for: .valueChanged)
        toggle.isOn = !(FileManager.getSkipBackupAttribute(item: FileManager.docDirURL) ?? false)
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
        
        cell.textLabel?.text = LocalizedStrings.libraryBackup
        cell.accessoryView = toggle
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return NSLocalizedString("When turned off, iOS will not backup zim files and index folders to iCloud or iTunes.",
                                 comment: "Setting: Backup local files comment") + "\n\n" +
               NSLocalizedString("Note: Large zim file collection can take up a lot of space in backup. You may want to turn this off if you use iCloud for backup.", comment: "Setting: Backup local files comment")
    }
    
    // MARK: - Actions
    
    func switcherValueChanged(_ switcher: UISwitch) {
        guard switcher == toggle else {return}
        FileManager.setSkipBackupAttribute(!switcher.isOn, url: FileManager.docDirURL)
    }

}

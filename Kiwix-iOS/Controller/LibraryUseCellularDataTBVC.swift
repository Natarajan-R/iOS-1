//
//  LibraryUseCellularDataTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/24/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class LibraryUseCellularDataTBVC: UITableViewController {

    var libraryRefreshAllowCellularData = Preference.libraryRefreshAllowCellularData
    let libraryrefreshAllowCellularDataSwitch = UISwitch()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.libraryUseCellularData
        libraryrefreshAllowCellularDataSwitch.addTarget(self, action: #selector(LibraryUseCellularDataTBVC.switcherValueChanged(_:)), for: .valueChanged)
        libraryrefreshAllowCellularDataSwitch.isOn = libraryRefreshAllowCellularData
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.libraryRefreshAllowCellularData = libraryRefreshAllowCellularData
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
        
        cell.textLabel?.text = LocalizedStrings.libraryUseCellularData
        cell.accessoryView = libraryrefreshAllowCellularDataSwitch
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Refresh Library"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return LocalizedStrings.cellularLibraryRefreshMessage1 + "\n\n" + LocalizedStrings.cellularLibraryRefreshMessage2
    }
    
    // MARK: - Actions
    
    func switcherValueChanged(_ switcher: UISwitch) {
        if switcher == libraryrefreshAllowCellularDataSwitch {
            libraryRefreshAllowCellularData = switcher.isOn
        }
    }

}

extension LocalizedStrings {
    class var refreshLibraryUsingCellularData: String {return NSLocalizedString("Refresh Library Using Cellular Data", comment: "Setting: Use Cellular Data")}
    class var cellularLibraryRefreshMessage1: String {return NSLocalizedString("When enabled, library refresh will use cellular data.", comment: "Setting: Use Cellular Data")}
    class var cellularLibraryRefreshMessage2: String {return NSLocalizedString("Note: a 5-6MB database is downloaded every time the library refreshes.", comment: "Setting: Use Cellular Data")}
}

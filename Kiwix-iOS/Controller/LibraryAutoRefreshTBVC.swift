//
//  LibraryAutoRefreshTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 8/15/15.
//  Copyright © 2015 Chris Li. All rights reserved.
//

import UIKit

class LibraryAutoRefreshTBVC: UITableViewController {
    let sectionHeader = ["day", "week", "month"]
    let sectionHeaderLocalized = [LocalizedStrings.day, LocalizedStrings.week, LocalizedStrings.month]
    let enableAutoRefreshSwitch = UISwitch()
    var checkedRowIndexPath: IndexPath?
    var libraryAutoRefreshDisabled = Preference.libraryAutoRefreshDisabled
    var libraryRefreshInterval = Preference.libraryRefreshInterval
    let timeIntervals: [String: [Double]] = {
        let hour = 3600.0
        let day = 24.0 * hour
        let week = 7.0 * day
        
        let timeIntervals = ["day": [day, 3*day, 5*day], "week": [week, 2*week, 4*week]]
        return timeIntervals
    }()
    
    let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = DateComponentsFormatter.UnitsStyle.full
        formatter.maximumUnitCount = 1
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.libraryAutoRefresh
        enableAutoRefreshSwitch.addTarget(self, action: #selector(LibraryAutoRefreshTBVC.switcherValueChanged(_:)), for: .valueChanged)
        enableAutoRefreshSwitch.isOn = !libraryAutoRefreshDisabled
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Preference.libraryAutoRefreshDisabled = libraryAutoRefreshDisabled
        Preference.libraryRefreshInterval = libraryRefreshInterval
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if libraryAutoRefreshDisabled {
            return 1
        } else {
            return timeIntervals.keys.count + 1
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            let sectionHeader = self.sectionHeader[section-1]
            return timeIntervals[sectionHeader]!.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if (indexPath as NSIndexPath).section == 0 {
            cell.textLabel?.text = LocalizedStrings.enableAutoRefresh
            cell.accessoryView = enableAutoRefreshSwitch
        } else {
            let sectionHeader = self.sectionHeader[(indexPath as NSIndexPath).section-1]
            let interval = timeIntervals[sectionHeader]![(indexPath as NSIndexPath).row]
            cell.textLabel?.text = dateComponentsFormatter.string(from: interval)
            if interval == libraryRefreshInterval {
                cell.accessoryType = .checkmark
                checkedRowIndexPath = indexPath
            } else {
                cell.accessoryType = .none
            }
            cell.accessoryView = nil
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return LocalizedStrings.autoRefreshHelpMessage
        } else {
            return sectionHeaderLocalized[section-1]
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).section >= 1 {
            if let checkedRowIndexPath = checkedRowIndexPath, let cell = tableView.cellForRow(at: checkedRowIndexPath) {
                cell.accessoryType = .none
            }
            
            if let cell = tableView.cellForRow(at: indexPath) {
                cell.accessoryType = .checkmark
            }
            
            checkedRowIndexPath = indexPath
            let sectionHeader = self.sectionHeader[(indexPath as NSIndexPath).section-1]
            libraryRefreshInterval = timeIntervals[sectionHeader]![(indexPath as NSIndexPath).row]
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        if section == 0 {
            if let view = view as? UITableViewHeaderFooterView {
                view.textLabel?.text = LocalizedStrings.autoRefreshHelpMessage
            }
        }
    }
    
    // MARK: - Action
    
    func switcherValueChanged(_ switcher: UISwitch) {
        libraryAutoRefreshDisabled = !switcher.isOn
        if libraryAutoRefreshDisabled {
            tableView.deleteSections(IndexSet(integersIn: NSMakeRange(1, sectionHeader.count-1).toRange()!), with: UITableViewRowAnimation.fade)
        } else {
            tableView.insertSections(IndexSet(integersIn: NSMakeRange(1, sectionHeader.count-1).toRange()!), with: .fade)
        }
    }
}

extension LocalizedStrings {
    class var day: String {return NSLocalizedString("day", comment: "Setting: Library Auto Refresh Page section title")}
    class var week: String {return NSLocalizedString("week", comment: "Setting: Library Auto Refresh Page section title")}
    class var month: String {return NSLocalizedString("month", comment: "Setting: Library Auto Refresh Page section title")}
    class var enableAutoRefresh: String {return NSLocalizedString("Enable Auto Refresh", comment: "Setting: Library Auto Refresh Page")}
    class var autoRefreshHelpMessage: String {return NSLocalizedString("When enabled, your library will refresh automatically according to the selected interval when you open the app.", comment: "Setting: Library Auto Refresh Page")}
}

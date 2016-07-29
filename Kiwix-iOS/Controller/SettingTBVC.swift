//
//  SettingTBVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class SettingTBVC: UITableViewController {
    private(set) var sectionHeader = [LocalizedStrings.library, LocalizedStrings.reading, LocalizedStrings.search, LocalizedStrings.widget, LocalizedStrings.misc]
    private(set) var cellTextlabels = [[LocalizedStrings.libraryAutoRefresh, LocalizedStrings.libraryUseCellularData, LocalizedStrings.libraryBackup],
                          [LocalizedStrings.fontSize, LocalizedStrings.adjustLayout],
                          [LocalizedStrings.history],
                          [LocalizedStrings.bookmarks],
                          [LocalizedStrings.rateKiwix, LocalizedStrings.about]]
    
    let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = DateComponentsFormatter.UnitsStyle.full
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = LocalizedStrings.settings
        clearsSelectionOnViewWillAppear = true
        showRateKiwixIfNeeded()
        
        if UIApplication.buildStatus == .alpha {
            cellTextlabels[2].append("Boost Factor 🚀")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "MiscAbout" {
            guard let controller = segue.destinationViewController as? WebViewController else {return}
            controller.page = .About
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionHeader.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellTextlabels[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        cell.textLabel?.text = cellTextlabels[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        cell.detailTextLabel?.text = {
            switch indexPath {
            case IndexPath(row: 0, section: 0):
                return Preference.libraryAutoRefreshDisabled ? LocalizedStrings.disabled :
                    dateComponentsFormatter.string(from: Preference.libraryRefreshInterval)
            case IndexPath(row: 1, section: 0):
                return Preference.libraryRefreshAllowCellularData ? LocalizedStrings.on : LocalizedStrings.off
            case IndexPath(row: 2, section: 0):
                guard let skipBackup = FileManager.getSkipBackupAttribute(item: FileManager.docDirURL) else {return ""}
                return skipBackup ? LocalizedStrings.off: LocalizedStrings.on
            case IndexPath(row: 0, section: 1):
                return String.formattedPercentString(Preference.webViewZoomScale / 100)
            case IndexPath(row: 1, section: 1):
                return Preference.webViewInjectJavascriptToAdjustPageLayout ? LocalizedStrings.on : LocalizedStrings.off
            default:
                return nil
            }
        }()
        
        return cell
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionHeader[section]
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard section == tableView.numberOfSections - 1 else {return nil}
        var footnote = String(format: LocalizedStrings.versionString, Bundle.appShortVersion)
        switch UIApplication.buildStatus {
        case .alpha, .beta:
            footnote += (UIApplication.buildStatus == .alpha ? " Alpha" : " Beta")
            footnote += "\n"
            footnote += "Build " + Bundle.buildVersion
            return footnote
        case .release:
            return footnote
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView, forSection section: Int) {
        guard section == tableView.numberOfSections - 1 else {return}
        if let view = view as? UITableViewHeaderFooterView {
            view.textLabel?.textAlignment = .center
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer {tableView.deselectRow(at: indexPath, animated: true)}
        let cell = tableView.cellForRow(at: indexPath)
        guard let text = cell?.textLabel?.text else {return}
        switch text {
        case LocalizedStrings.libraryAutoRefresh:
            performSegue(withIdentifier: "LibraryAutoRefresh", sender: self)
        case LocalizedStrings.libraryUseCellularData:
            performSegue(withIdentifier: "LibraryUseCellularData", sender: self)
        case LocalizedStrings.libraryBackup:
            performSegue(withIdentifier: "LibraryBackup", sender: self)
        case LocalizedStrings.fontSize:
            performSegue(withIdentifier: "ReadingFontSize", sender: self)
        case LocalizedStrings.adjustLayout:
            performSegue(withIdentifier: "AdjustLayout", sender: self)
        case LocalizedStrings.history:
            performSegue(withIdentifier: "SearchHistory", sender: self)
        case LocalizedStrings.bookmarks:
            performSegue(withIdentifier: "SettingWidgetBookmarksTBVC", sender: self)
        case "Boost Factor 🚀":
            performSegue(withIdentifier: "SearchTune", sender: self)
        case LocalizedStrings.rateKiwix:
            showRateKiwixAlert(showRemindLater: false)
        case LocalizedStrings.about:
            performSegue(withIdentifier: "MiscAbout", sender: self)
        default:
            break
        }
    }
    
    // MARK: - Rate Kiwix
    
    func showRateKiwixIfNeeded() {
        guard Preference.haveRateKiwix == false else {return}
        guard let firstActiveDate = Preference.activeUseHistory.first else {return}
        let installtionIsOldEnough = Date().timeIntervalSince(firstActiveDate as Date) > 3600.0 * 24 * 7
        let hasActivelyUsed = Preference.activeUseHistory.count > 10
        if installtionIsOldEnough && hasActivelyUsed {
            showRateKiwixAlert(showRemindLater: true)
        }
    }
    
    func showRateKiwixAlert(showRemindLater: Bool) {
        let alert = UIAlertController(title: LocalizedStrings.rateKiwixTitle, message: LocalizedStrings.rateKiwixMessage, preferredStyle: .alert)
        let remindLater = UIAlertAction(title: LocalizedStrings.rateLater, style: .default) { (action) -> Void in
            Preference.activeUseHistory.removeAll()
        }
        let remindNever = UIAlertAction(title: LocalizedStrings.rateNever, style: .default) { (action) -> Void in
            Preference.haveRateKiwix = true
        }
        let rateNow = UIAlertAction(title: LocalizedStrings.rateNow, style: .cancel) { (action) -> Void in
            self.goRateInAppStore()
            Preference.haveRateKiwix = true
        }
        let cancel = UIAlertAction(title: LocalizedStrings.cancel, style: .default, handler: nil)
        
        if showRemindLater {
            alert.addAction(remindLater)
            alert.addAction(remindNever)
            alert.addAction(rateNow)
        } else {
            alert.addAction(rateNow)
            alert.addAction(cancel)
        }
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func goRateInAppStore() {
        let url = URL(string: "http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=997079563&pageNumber=0&sortOrdering=2&type=Purple+Software&mt=8")!
        UIApplication.shared().openURL(url)
    }
    
    // MARK: - Actions
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }

}

extension LocalizedStrings {
    class var settings: String {return NSLocalizedString("Settings", comment: "Setting: Title")}
    class var versionString: String {return NSLocalizedString("Kiwix for iOS v%@", comment: "Version footnote (please translate 'v' as version)")}
    
    //MARK: -  Table Header Text
    class var library: String {return NSLocalizedString("Library ", comment: "Setting: Section Header")}
    class var reading: String {return NSLocalizedString("Reading", comment: "Setting: Section Header")}
    class var search: String {return NSLocalizedString("Search", comment: "Setting: Section Header")}
    class var widget: String {return NSLocalizedString("Widget", comment: "Setting: Section Header")}
    class var misc: String {return NSLocalizedString("Misc", comment: "Setting: Section Header")}
    
    //MARK: -  Table Cell Text
    class var libraryAutoRefresh: String {return NSLocalizedString("Auto Refresh", comment: "Setting: Library Auto Refresh")}
    class var libraryUseCellularData: String {return NSLocalizedString("Refresh Using Cellular Data", comment: "Setting: Library Use Cellular Data")}
    class var libraryBackup: String {return NSLocalizedString("Backup Local Files", comment: "Setting: Backup Local Files")}
    class var fontSize: String {return NSLocalizedString("Font Size", comment: "Setting: Font Size")}
    class var adjustLayout: String {return NSLocalizedString("Adjust Layout", comment: "Setting: Adjust Layout")}
    class var rateKiwix: String {return NSLocalizedString("Please Rate Kiwix", comment: "Setting: Others")}
    class var emailFeedback: String {return NSLocalizedString("Send Email Feedback", comment: "Setting: Others")}
    class var about: String {return NSLocalizedString("About", comment: "Setting: Others")}
    
    //MARK: -  Rate Kiwix
    class var rateKiwixTitle: String {return NSLocalizedString("Give Kiwix a rate!", comment: "Rate Kiwix in App Store Alert Title")}
    class var rateNow: String {return NSLocalizedString("Rate Now", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateLater: String {return NSLocalizedString("Remind me later", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateNever: String {return NSLocalizedString("Never remind me again", comment: "Rate Kiwix in App Store Alert Action")}
    class var rateKiwixMessage: String {return NSLocalizedString("We hope you enjoyed using Kiwix so far. Would you like to give us a rate in App Store?", comment: "Rate Kiwix in App Store Alert Message")}
}

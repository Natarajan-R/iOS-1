//
//  LanguageTBVC.swift
//  Kiwix
//
//  Created by Chris on 12/12/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit
import CoreData

class LanguageTBVC: UITableViewController, NSFetchedResultsControllerDelegate {
    
    let managedObjectContext = NSManagedObjectContext.mainQueueContext
    var showLanguageSet = Set<Language>()
    var showLanguages = [Language]()
    var hideLanguages = [Language]()
    var messageBarButtonItem = MessageBarButtonItem()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Languages", comment: "Language selection: Title")
        
        showLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        hideLanguages = Language.fetch(displayed: false, context: managedObjectContext)
        showLanguages = sortByCountDesc(showLanguages)
        hideLanguages = sortByCountDesc(hideLanguages)
        showLanguageSet = Set(showLanguages)
        
        configureToolBar()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        let hasChange = showLanguageSet != Set(showLanguages)
        guard hasChange else {return}
        guard let libraryOnlineTBVC = self.navigationController?.topViewController as? LibraryOnlineTBVC else {return}
        libraryOnlineTBVC.refreshFetchedResultController()
    }
    
    func configureToolBar() {
        let spaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace)
        setToolbarItems([spaceBarButtonItem, messageBarButtonItem, spaceBarButtonItem], animated: false)
        messageBarButtonItem.text = messageLabelText
    }
    
    var messageLabelText: String? {
        switch showLanguages.count {
        case 0:
            return LocalizedStrings.noLangSelected
        case 1:
            guard let name = showLanguages.first?.name else {return nil}
            return String(format: LocalizedStrings.oneLangSelected, name)
        case 2:
            guard let name1 = showLanguages[0].name else {return nil}
            guard let name2 = showLanguages[1].name else {return nil}
            return String(format: LocalizedStrings.twoLangSelected, name1, name2)
        default:
            return String(format: LocalizedStrings.someLangSelected, showLanguages.count)
        }
    }
    
    func sortByCountDesc(_ languages: [Language]) -> [Language] {
        return languages.sorted { (language1, language2) -> Bool in
            guard let count1 = language1.books?.count else {return false}
            guard let count2 = language2.books?.count else {return false}
            if count1 == count2 {
                guard let name1 = language1.name else {return false}
                guard let name2 = language2.name else {return false}
                return name1.compare(name2) == .orderedAscending
            } else {
                return count1 > count2
            }
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? showLanguages.count : hideLanguages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if (indexPath as NSIndexPath).section == 0 {
            cell.textLabel?.text = showLanguages[(indexPath as NSIndexPath).row].name
            cell.detailTextLabel?.text = showLanguages[(indexPath as NSIndexPath).row].books?.count.description
        } else {
            cell.textLabel?.text = hideLanguages[(indexPath as NSIndexPath).row].name
            cell.detailTextLabel?.text = hideLanguages[(indexPath as NSIndexPath).row].books?.count.description
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showLanguages.count == 0 {
            return section == 0 ? "" : NSLocalizedString("ALL", comment: "Language selection: table section title") + "       "
        } else {
            return section == 0 ? NSLocalizedString("SHOWING", comment: "Language selection: table section title") : NSLocalizedString("HIDING", comment: "Language selection: table section title")
        }
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        func animateUpdates(_ originalIndexPath: IndexPath, destinationIndexPath: IndexPath) {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .right)
            tableView.insertRows(at: [destinationIndexPath], with: .right)
            tableView.headerView(forSection: 0)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 0)
            tableView.headerView(forSection: 1)?.textLabel?.text = self.tableView(tableView, titleForHeaderInSection: 1)
            tableView.endUpdates()
        }
        
        if (indexPath as NSIndexPath).section == 0 {
            let language = showLanguages[(indexPath as NSIndexPath).row]
            language.isDisplayed = false
            hideLanguages.append(language)
            showLanguages.remove(at: (indexPath as NSIndexPath).row)
            hideLanguages = sortByCountDesc(hideLanguages)
            
            guard let row = hideLanguages.index(of: language) else {tableView.reloadData(); return}
            let destinationIndexPath = IndexPath(row: row, section: 1)
            animateUpdates(indexPath, destinationIndexPath: destinationIndexPath)
        } else {
            let language = hideLanguages[(indexPath as NSIndexPath).row]
            language.isDisplayed = true
            showLanguages.append(language)
            hideLanguages.remove(at: (indexPath as NSIndexPath).row)
            showLanguages = sortByCountDesc(showLanguages)
            
            guard let row = showLanguages.index(of: language) else {tableView.reloadData(); return}
            let destinationIndexPath = IndexPath(row: row, section: 0)
            animateUpdates(indexPath, destinationIndexPath: destinationIndexPath)
        }
        
        messageBarButtonItem.text = messageLabelText
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if showLanguages.count == 0 && section == 0 {return CGFloat.leastNormalMagnitude}
        return tableView.sectionHeaderHeight
    }

}

extension LocalizedStrings {
    class var noLangSelected: String {return NSLocalizedString("All languages will be shown", comment: "")}
    class var oneLangSelected: String {return NSLocalizedString("%@ is selected", comment: "")}
    class var twoLangSelected: String {return NSLocalizedString("%@ and %@ are selected", comment: "")}
    class var someLangSelected: String {return NSLocalizedString("%d languages are selected", comment: "")}
}

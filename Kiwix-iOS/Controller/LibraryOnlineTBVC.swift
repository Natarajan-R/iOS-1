//
//  LibraryOnlineTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 2/8/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet
import DateTools

class LibraryOnlineTBVC: UITableViewController, NSFetchedResultsControllerDelegate, TableCellDelegate, LTBarButtonItemDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    var booksShowingDetail = Set<Book>()
    var messsageLabelRefreshTimer: Foundation.Timer?
    var refreshing = false
    
    // MARK: - Override
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 44.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.tableFooterView = UIView()
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
        configureToolBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startRefresh(invokedAutomatically: true)
        segmentedControl.selectedSegmentIndex = 0
        messsageLabelRefreshTimer = Foundation.Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(configureMessage), userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        messsageLabelRefreshTimer?.invalidate()
    }
    
    
    // MARK: - TableCellDelegate
    
    func didTapOnAccessoryViewForCell(_ cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell),
              let book = fetchedResultController.object(at: indexPath) as? Book else {return}
        switch book.spaceState {
        case .enough:
            Network.sharedInstance.download(book)
        case .caution:
            // TODO: - Switch to a global op queue
            Network.sharedInstance.operationQueue.addOperation(SpaceCautionAlert(book: book, presentationContext: self))
        case .notEnough:
            // TODO: - Switch to a global op queue
            Network.sharedInstance.operationQueue.addOperation(SpaceNotEnoughAlert(book: book, presentationContext: self))
        }
    }
    
    // MARK: - LTBarButtonItemDelegate
    
    func barButtonTapped(_ sender: LTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        guard sender === refreshLibButton else {return}
        startRefresh(invokedAutomatically: false)
    }
    
    // MARK: - Others
    
    func refreshLibraryForTheFirstTime() {
        guard Preference.libraryLastRefreshTime == nil else {return}
        startRefresh(invokedAutomatically: true)
    }
    
    func startRefresh(invokedAutomatically: Bool) {
        if invokedAutomatically {
            let libraryIsOld: Bool = {
                guard let lastLibraryRefreshTime = Preference.libraryLastRefreshTime else {return true}
                return -lastLibraryRefreshTime.timeIntervalSinceNow > Preference.libraryRefreshInterval
            }()
            guard libraryIsOld else {return}
        }
        
        let refreshOperation = RefreshLibraryOperation(invokedAutomatically: invokedAutomatically) { (errors) in
            defer {
                OperationQueue.main.addOperation({
                    self.refreshing = false
                    self.configureMessage()
                    self.configureRotatingStatus()
                    self.configureEmptyTableBackground()
                })
            }
            if errors.count > 0 {
                let codes = errors.map() {$0.code}
                if codes.contains(OperationErrorCode.networkError.rawValue) {
                    let alertOperation = RefreshLibraryInternetRequiredAlert(presentationContext: self)
                    GlobalOperationQueue.sharedInstance.addOperation(alertOperation)
                }
            } else {
                guard !Preference.libraryHasShownPreferredLanguagePrompt else {return}
                let operation = RefreshLibraryLanguageFilterAlert(libraryOnlineTBVC: self)
                GlobalOperationQueue.sharedInstance.addOperation(operation)
            }
        }
        
        refreshing = true
        configureMessage()
        configureRotatingStatus()
        configureEmptyTableBackground()
        GlobalOperationQueue.sharedInstance.addOperation(refreshOperation)
    }
    
    // MARK: - ToolBar Button
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        tabBarController?.selectedIndex = sender.selectedSegmentIndex
    }
    @IBAction func dismissSelf(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    lazy var refreshLibButton: LTBarButtonItem = LTBarButtonItem(configure: BarButtonConfig(imageName: "Refresh", delegate: self))
    var messageButton = MessageBarButtonItem()
    
    func configureToolBar() {
        guard var toolBarItems = self.toolbarItems else {return}
        toolBarItems[0] = refreshLibButton
        toolBarItems[2] = messageButton
        
        let negativeSpace = UIBarButtonItem(barButtonSystemItem: .fixedSpace)
        negativeSpace.width = -10
        toolBarItems.insert(negativeSpace, at: 0)
        setToolbarItems(toolBarItems, animated: false)
        
        configureToolBarVisibility(animated: false)
        configureMessage()
    }
    
    func configureMessage() {
        if refreshing {
            messageButton.text = LocalizedStrings.refreshing
        } else {
            guard let sectionInfos = fetchedResultController.sections else {messageButton.text = nil; return}
            let count = sectionInfos.reduce(0) {$0 + $1.numberOfObjects}
            let localizedBookCountString = String.localizedStringWithFormat(NSLocalizedString("%d book(s) available for download", comment: "Book Library, online book catalogue message"), count)
            guard count > 0 else {messageButton.text = localizedBookCountString; return}
            guard let lastRefreshTime = Preference.libraryLastRefreshTime else {messageButton.text = localizedBookCountString; return}
            let localizedRefreshTimeString: String = {
                var string = NSLocalizedString("Last Refresh: ", comment: "Book Library, online book catalogue refresh time")
                if Date().timeIntervalSince(lastRefreshTime as Date) > 60.0 {
                    string += lastRefreshTime.timeAgoSinceNow()
                } else {
                    string += NSLocalizedString("just now", comment: "Book Library, online book catalogue refresh time")
                }
                return string
            }()
            messageButton.text = localizedBookCountString + "\n" + localizedRefreshTimeString
        }
    }
    
    func configureToolBarVisibility(animated: Bool) {
        navigationController?.setToolbarHidden(fetchedResultController.fetchedObjects?.count == 0, animated: animated)
    }
    
    func configureRotatingStatus() {
        refreshing ? refreshLibButton.startRotating() : refreshLibButton.stopRotating()
    }
    
    func configureEmptyTableBackground() {
        tableView.reloadEmptyDataSet()
    }
    
    // MARK: - Empty table datasource & delegate
    
    func imageForEmptyDataSet(_ scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "CloudColor")
    }
    
    func titleForEmptyDataSet(_ scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("There are some books in the cloud", comment: "Book Library, book online catalogue, no book center title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
                          NSForegroundColorAttributeName: UIColor.darkGray()]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func descriptionForEmptyDataSet(_ scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("Refresh the library to show all books available for download.", comment: "Book Library, book online catalogue, no book center description")
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.alignment = .center
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0),
                          NSForegroundColorAttributeName: UIColor.lightGray(),
                          NSParagraphStyleAttributeName: style]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func buttonTitleForEmptyDataSet(_ scrollView: UIScrollView!, forState state: UIControlState) -> AttributedString! {
        if refreshing == true {
            let text = NSLocalizedString("Refreshing...", comment: "Book Library, book downloader, refreshing button text")
            let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0), NSForegroundColorAttributeName: UIColor.darkGray()]
            return AttributedString(string: text, attributes: attributes)
        } else {
            let text = NSLocalizedString("Refresh Now", comment: "Book Library, book downloader, refresh now button text")
            let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0), NSForegroundColorAttributeName: segmentedControl.tintColor]
            return AttributedString(string: text, attributes: attributes)
        }
    }
    
    func verticalOffsetForEmptyDataSet(_ scrollView: UIScrollView!) -> CGFloat {
        return -64.0
    }
    
    func spaceHeightForEmptyDataSet(_ scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        guard !refreshing else {return}
        startRefresh(invokedAutomatically: false)
    }
    
    // MARK: - TableView Data Source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let book = fetchedResultController.object(at: indexPath) as? Book else {return}
        guard let cell = cell as? CloudBookCell else {return}
        
        cell.titleLabel.text = book.title
        cell.hasPicIndicator.backgroundColor = book.hasPic ? UIColor.havePicTintColor : UIColor.lightGray()
        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.delegate = self
        cell.subtitleLabel.text = booksShowingDetail.contains(book) ? book.detailedDescription2 : book.detailedDescription
        
        switch book.spaceState {
        case .enough:
            cell.accessoryImageTintColor = UIColor.green().withAlphaComponent(0.75)
        case .caution:
            cell.accessoryImageTintColor = UIColor.orange().withAlphaComponent(0.75)
        case .notEnough:
            cell.accessoryImageTintColor = UIColor.gray().withAlphaComponent(0.75)
        }
    }
    
    // MARK: Other Data Source
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard tableView.numberOfSections > 1 else {return nil}
        guard let languageName = fetchedResultController.sections?[section].name else {return nil}
        return languageName
    }
    
    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        let sectionIndexTitles = fetchedResultController.sectionIndexTitles
        guard sectionIndexTitles.count > 2 else {return nil}
        return sectionIndexTitles
    }
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        return fetchedResultController.section(forSectionIndexTitle: title, at: index)
    }
    
    // MARK: - Table View Delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let book = fetchedResultController.object(at: indexPath) as? Book else {return}
        if booksShowingDetail.contains(book) {
            booksShowingDetail.remove(book)
        } else {
            booksShowingDetail.insert(book)
        }
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard tableView.numberOfSections > 1 else {return 0.0}
        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
        guard headerText != "" else {return 0.0}
        return 20.0
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {return}
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Book")
        let langDescriptor = SortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = SortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = self.onlineCompoundPredicate
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "OnlineFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    func refreshFetchedResultController() {
        fetchedResultController.fetchRequest.predicate = onlineCompoundPredicate
        fetchedResultController.performFetch(deleteCache: true)
        tableView.reloadData()
        configureMessage()
    }
    
    private var langPredicate: Predicate {
        let displayedLanguages = Language.fetch(displayed: true, context: managedObjectContext)
        if displayedLanguages.count > 0 {
            return Predicate(format: "language IN %@", displayedLanguages)
        } else {
            return Predicate(format: "language.name != nil")
        }
    }
    
    private var onlineCompoundPredicate: CompoundPredicate {
        let isCloudPredicate = Predicate(format: "isLocal == false")
        return CompoundPredicate(andPredicateWithSubpredicates: [langPredicate, isCloudPredicate])
    }
    
    // MARK: - Fetched Result Controller Delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .fade)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .fade)
        default:
            return
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: AnyObject, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else {return}
            tableView.insertRows(at: [newIndexPath], with: .fade)
        case .delete:
            guard let indexPath = indexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
        case .update:
            guard let indexPath = indexPath, let cell = tableView.cellForRow(at: indexPath) else {return}
            configureCell(cell, atIndexPath: indexPath)
        case .move:
            guard let indexPath = indexPath, let newIndexPath = newIndexPath else {return}
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [newIndexPath], with: .fade)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        configureToolBarVisibility(animated: true)
        configureMessage()
    }
}

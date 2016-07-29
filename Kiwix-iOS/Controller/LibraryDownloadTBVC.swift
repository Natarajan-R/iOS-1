//
//  LibraryDownloadTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 2/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class LibraryDownloadTBVC: UITableViewController, NSFetchedResultsControllerDelegate, TableCellDelegate, DownloadProgressReporting, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
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
        segmentedControl.selectedSegmentIndex = 1
        Network.sharedInstance.delegate = self
        refreshProgress(animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        Network.sharedInstance.delegate = nil
    }
    
    // MARK: - TableCellDelegate
    
    func didTapOnAccessoryViewForCell(_ cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell),
            let downloadTask = fetchedResultController.object(at: indexPath) as? DownloadTask,
            let book = downloadTask.book else {return}
        switch downloadTask.state {
        case .downloading, .queued:
            Network.sharedInstance.pause(book)
        case .paused, .error:
            Network.sharedInstance.resume(book)
        }
    }
    
    // MARK: -  DownloadProgressReporting
    
    func refreshProgress() {
        refreshProgress(animated: true)
    }
    
    private func refreshProgress(animated: Bool) {
        guard let downloadTasks = fetchedResultController.fetchedObjects else {return}
        for downloadTask in downloadTasks {
            guard let id = downloadTask.book?.id,
                let indexPath = fetchedResultController.indexPath(forObject: downloadTask),
                let cell = tableView.cellForRow(at: indexPath) as? DownloadBookCell,
                let progress = Network.sharedInstance.progresses[id] else {return}
            cell.progressView.setProgress(Float(progress.fractionCompleted), animated: animated)
            cell.subtitleLabel.text = progress.description
        }
    }
    
    // MARK: - ToolBar Button
    
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        tabBarController?.selectedIndex = sender.selectedSegmentIndex
    }
    @IBAction func dismissSelf(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    var messageButton = MessageBarButtonItem()
    
    func configureToolBar() {
        guard var toolBarItems = self.toolbarItems else {return}
        toolBarItems[1] = messageButton
        setToolbarItems(toolBarItems, animated: false)
        
        configureToolBarVisibility(animated: false)
        configureMessage()
    }
    
    func configureToolBarVisibility(animated: Bool) {
        navigationController?.setToolbarHidden(fetchedResultController.fetchedObjects?.count == 0, animated: animated)
    }
    
    func configureMessage() {
        guard let sectionInfos = fetchedResultController.sections else {messageButton.text = nil; return}
        let count = sectionInfos.reduce(0) {$0 + $1.numberOfObjects}
        let localizedString = String.localizedStringWithFormat(NSLocalizedString("%d download tasks", comment: "Book Library, book downloader message"), count)
        messageButton.text = localizedString
    }
    
    // MARK: - Empty table datasource & delegate
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "DownloadColor")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("No Download Task", comment: "Book Library, book downloader, no book center title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
                          NSForegroundColorAttributeName: UIColor.darkGray()]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("After starting a download task, minimize the app to continue the task in the background.", comment: "Book Library, book downloader, no book center description")
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.alignment = .center
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0),
                          NSForegroundColorAttributeName: UIColor.lightGray(),
                          NSParagraphStyleAttributeName: style]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> AttributedString! {
        let text = NSLocalizedString("Learn more", comment: "Book Library, book downloader, learn more button text")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0), NSForegroundColorAttributeName: segmentedControl.tintColor]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 0.0
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        let operation = ShowHelpPageOperation(type: .DownloaderLearnMore, presentationContext: self)
        GlobalOperationQueue.sharedInstance.addOperation(operation)
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let downloadTask = fetchedResultController.object(at: indexPath) as? DownloadTask,
              let book = downloadTask.book, let id = book.id,
              let cell = cell as? DownloadBookCell else {return}
        
        cell.titleLabel.text = book.title
        cell.hasPicIndicator.backgroundColor = book.hasPic ? UIColor.havePicTintColor : UIColor.lightGray()
        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.dateLabel.text = book.dateFormatted
        cell.articleCountLabel.text = book.articleCountFormatted
        cell.delegate = self
        
        guard let progress = Network.sharedInstance.progresses[id] else {return}
        cell.progressView.progress = Float(progress.fractionCompleted)
        
        switch downloadTask.state {
        case .queued, .downloading:
            cell.accessoryImageView.isHighlighted = false
            cell.accessoryImageTintColor = UIColor.orange().withAlphaComponent(0.75)
        case .paused, .error:
            cell.accessoryImageView.isHighlighted = true
            cell.accessoryHighlightedImageTintColor = UIColor.green().withAlphaComponent(0.75)
        }
        cell.subtitleLabel.text = progress.description
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
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: UITableViewRowActionStyle(), title: LocalizedStrings.remove) { (action, indexPath) -> Void in
            guard let downloadTask = self.fetchedResultController.object(at: indexPath) as? DownloadTask else {return}
            let context = UIApplication.appDelegate.managedObjectContext
            if let book = downloadTask.book {
                Network.sharedInstance.cancel(book)
                FileManager.removeResumeData(book)
            }
            context.performAndWait({ () -> Void in
                downloadTask.book?.isLocal = false
                context.delete(downloadTask)
            })
        }
        return [remove]
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController<DownloadTask> = {
        let fetchRequest = NSFetchRequest<DownloadTask>(entityName: "DownloadTask")
        let creationTimeDescriptor = SortDescriptor(key: "creationTime", ascending: true)
        fetchRequest.sortDescriptors = [creationTimeDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "DownloadFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
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

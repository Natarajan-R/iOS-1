//
//  LibraryLocalTBVC.swift
//  Kiwix
//
//  Created by Chris Li on 2/11/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class LibraryLocalTBVC: UITableViewController, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
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
        segmentedControl.selectedSegmentIndex = 2
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        guard segue.identifier == "showBookDetail" else {return}
        guard let controller = segue.destinationViewController as? LibraryLocalBookDetailTBVC,
              let cell = sender as? UITableViewCell,
              let indexPath = tableView.indexPath(for: cell) else {return}
        let book = fetchedResultController.object(at: indexPath)
        controller.book = book
    }
    
    // MARK: - ToolBar Button Actions
    
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
        guard let books = fetchedResultController.fetchedObjects else {return}
        let totalSize = books.reduce(0) {$0 + ($1.fileSize)}
        let spaceString = String.formattedFileSizeString(totalSize)
        let localizedString = String.localizedStringWithFormat(NSLocalizedString("Taking up %@ in total", comment: "Book Library, local book message"), spaceString)
        messageButton.text = localizedString
    }
    
    // MARK: - Empty table datasource & delegate
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "FolderColor")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("No Book on Device", comment: "Book Library, book local, no book center title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
                          NSForegroundColorAttributeName: UIColor.darkGray()]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("Download a book or import using iTunes File Sharing. They will show up here automatically", comment: "Book Library, book local, no book center description")
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.alignment = .center
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0),
                          NSForegroundColorAttributeName: UIColor.lightGray(),
                          NSParagraphStyleAttributeName: style]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> AttributedString! {
        let text = NSLocalizedString("Learn more about importing books", comment: "Book Library, book downloader, learn more button text")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0), NSForegroundColorAttributeName: segmentedControl.tintColor]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -64.0
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        let operation = ShowHelpPageOperation(type: .ImportBookLearnMore, presentationContext: self)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? BasicBookCell else {return}
        let book = fetchedResultController.object(at: indexPath)
        
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = book.detailedDescription1

        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.hasPic = book.hasPic
        cell.hasIndex = book.hasIndex
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
        let delete = UITableViewRowAction(style: .destructive, title: LocalizedStrings.delete) { (action, indexPath) -> Void in
            let book = self.fetchedResultController.object(at: indexPath)
            self.managedObjectContext.perform({ () -> Void in
                if let id = book.id, let zimURL = ZimMultiReader.sharedInstance.readers[id]?.fileURL {
                    _ = FileManager.removeItem(atURL: zimURL)
                    
                    let indexFolderURL = try! zimURL.appendingPathExtension("idx")
                    _ = FileManager.removeItem(atURL: indexFolderURL)
                }
                
                if let _ = book.url {
                    book.isLocal = false
                } else {
                    self.managedObjectContext.delete(book)
                }
            })
        }
        return [delete]
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        let langDescriptor = SortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = SortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = Predicate(format: "isLocal == true")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "LocalFRC")
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

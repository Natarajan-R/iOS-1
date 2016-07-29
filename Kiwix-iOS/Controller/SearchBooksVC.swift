//
//  SearchBooksVC.swift
//  Kiwix
//
//  Created by Chris Li on 4/7/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class SearchBooksVC: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, TableCellDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var toolBar: UIToolbar!
    @IBOutlet weak var recentSearchContainer: DropShadowView!
    @IBOutlet weak var recentSearchBarHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
//        tableView.emptyDataSetSource = self
//        tableView.emptyDataSetDelegate = self
        tableView.tableHeaderView = UIView()
        tableView.tableFooterView = UIView()
        tableView.keyboardDismissMode = .onDrag
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        configureRecentSearchBarHeight()
    }
    
    func configureRecentSearchBarHeight() {
        let previousHeight = recentSearchBarHeight.constant
        let newHeight: CGFloat = Preference.recentSearchTerms.count == 0 ? 0.0 : 44.0
        guard previousHeight != newHeight else {return}
        recentSearchBarHeight.constant = newHeight
        recentSearchContainer.setNeedsDisplay()
    }
    
    // MARK: - Empty table datasource & delegate
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("No Book Available", comment: "Book Library, book downloader, no book center title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
                          NSForegroundColorAttributeName: UIColor.darkGray()]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> AttributedString! {
        let text = NSLocalizedString("Download A Book", comment: "Book Library, book downloader, learn more button text")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 17.0), NSForegroundColorAttributeName: UIButton().tintColor]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return -64.0
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 0.0
    }
    
    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
    }
    
    // MARK: - Fetched Results Controller
    
    let managedObjectContext = NSManagedObjectContext.mainQueueContext
    lazy var fetchedResultController: NSFetchedResultsController<Book> = {
        let fetchRequest = NSFetchRequest<Book>(entityName: "Book")
        let langDescriptor = SortDescriptor(key: "language.name", ascending: true)
        let titleDescriptor = SortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [langDescriptor, titleDescriptor]
        fetchRequest.predicate = Predicate(format: "isLocal == true")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: "language.name", cacheName: "ScopeFRC")
        fetchedResultsController.delegate = self
        fetchedResultsController.performFetch(deleteCache: false)
        return fetchedResultsController
    }()
    
    // MARK: - Table Cell Delegate
    
    func didTapOnAccessoryViewForCell(_ cell: UITableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell),
            let book = fetchedResultController.object(at: indexPath) as? Book else {return}
        book.includeInSearch = !book.includeInSearch
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CheckMarkBookCell", for: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let book = fetchedResultController.object(at: indexPath) as? Book else {return}
        guard let cell = cell as? CheckMarkBookCell else {return}
        
        cell.delegate = self
        cell.titleLabel.text = book.title
        cell.subtitleLabel.text = book.detailedDescription

        cell.favIcon.image = UIImage(data: book.favIcon ?? Data())
        cell.hasPic = book.hasPic
        cell.hasIndex = book.hasIndex
        cell.isChecked = book.includeInSearch
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard tableView.numberOfSections > 1 else {return nil}
        guard let languageName = fetchedResultController.sections?[section].name else {return nil}
        return languageName
    }
    
    // MARK: Table view delegate
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard let headerText = self.tableView(tableView, titleForHeaderInSection: section) else {return 0.0}
        guard headerText != "" else {return 0.0}
        return 20.0
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else {return}
        header.textLabel?.font = UIFont.boldSystemFont(ofSize: 14)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let mainVC = parent?.parent as? MainController,
            let book = fetchedResultController.object(at: indexPath) as? Book,
            let bookID = book.id else {return}
        mainVC.hideSearch(animated: true)
        mainVC.loadMainPage(bookID)
        tableView.deselectRow(at: indexPath, animated: true)
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
    }
}

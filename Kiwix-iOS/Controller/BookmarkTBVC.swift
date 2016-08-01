//
//  BookmarkTBVC.swift
//  Kiwix
//
//  Created by Chris on 1/10/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import CoreData
import DZNEmptyDataSet

class BookmarkTBVC: UITableViewController, NSFetchedResultsControllerDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearsSelectionOnViewWillAppear = true
        title = LocalizedStrings.bookmarks
        tableView.estimatedRowHeight = 66.0
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.allowsMultipleSelectionDuringEditing = true
        
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setEditing(false, animated: false)
        navigationController?.setToolbarHidden(true, animated: true)
    }
    
    func updateWidgetData() {
        let operation = UpdateWidgetDataSourceOperation()
        GlobalOperationQueue.sharedInstance.addOperation(operation)
    }
    
    // MARK: - Empty table datasource & delegate
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "BookmarkColor")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("Bookmarks", comment: "Bookmarks view title")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
                          NSForegroundColorAttributeName: UIColor.darkGray()]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("To add a bookmark, long press the star button when reading an article", comment: "Bookmarks view message")
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byWordWrapping
        style.alignment = .center
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 14.0),
                          NSForegroundColorAttributeName: UIColor.lightGray(),
                          NSParagraphStyleAttributeName: style]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sectionInfo = fetchedResultController.sections?[section] else {return 0}
        return sectionInfo.numberOfObjects
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let article = fetchedResultController.object(at: indexPath) as? Article
        if let _ = article?.snippet {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkSnippetCell", for: indexPath)
            configureSnippetCell(cell, atIndexPath: indexPath)
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BookmarkCell", for: indexPath)
            configureCell(cell, atIndexPath: indexPath)
            return cell
        }
    }
    
    func configureCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        guard let cell = cell as? BookmarkCell else {return}
        guard let article = fetchedResultController.object(at: indexPath) as? Article else {return}
        
        cell.thumbImageView.image = {
            guard let data = article.thumbImageData else {return nil}
            return UIImage(data: data)
        }()
        cell.titleLabel.text = article.title
        cell.subtitleLabel.text = article.book?.title
    }
    
    func configureSnippetCell(_ cell: UITableViewCell, atIndexPath indexPath: IndexPath) {
        configureCell(cell, atIndexPath: indexPath)
        
        guard let cell = cell as? BookmarkSnippetCell else {return}
        guard let article = fetchedResultController.object(at: indexPath) as? Article else {return}
        cell.snippetLabel.text = article.snippet
    }
    
    // MARK: - Table view delegate
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !tableView.isEditing else {return}
        defer {dismiss(animated: true, completion: nil)}
        guard let navigationController = navigationController?.presentingViewController as? UINavigationController else {return}
        guard let mainVC = navigationController.topViewController as? MainController else {return}
        guard let article = fetchedResultController.object(at: indexPath) as? Article else {return}
        mainVC.load(article.url)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {}
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let remove = UITableViewRowAction(style: .destructive, title: LocalizedStrings.remove) { (action, indexPath) -> Void in
            guard let article = self.fetchedResultController.object(at: indexPath) as? Article else {return}
            let context = NSManagedObjectContext.mainQueueContext
            context.performAndWait({ () -> Void in
                article.isBookmarked = false
            })
            self.updateWidgetData()
        }
        return [remove]
    }
    
    // MARK: - Fetched Result Controller Delegate
    
    let managedObjectContext = UIApplication.appDelegate.managedObjectContext
    
    lazy var fetchedResultController: NSFetchedResultsController<Article> = {
        let fetchRequest = NSFetchRequest<Article>(entityName: "Article")
        let dateDescriptor = SortDescriptor(key: "bookmarkDate", ascending: false)
        let titleDescriptor = SortDescriptor(key: "title", ascending: true)
        fetchRequest.sortDescriptors = [dateDescriptor, titleDescriptor]
        fetchRequest.predicate = Predicate(format: "isBookmarked == true")
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.managedObjectContext, sectionNameKeyPath: nil, cacheName: "BookmarksFRC" + Bundle.appShortVersion)
        fetchedResultsController.delegate = self
        _ = try? fetchedResultsController.performFetch()
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
    }

    // MARK: - Action
    
    @IBAction func editingButtonTapped(_ sender: UIBarButtonItem) {
        setEditing(!isEditing, animated: true)
        navigationController?.setToolbarHidden(!isEditing, animated: true)
    }
    
    @IBAction func removeBookmarkButtonTapped(_ sender: UIBarButtonItem) {
        guard isEditing else {return}
        guard let selectedIndexPathes = tableView.indexPathsForSelectedRows else {return}
        let artiicles = selectedIndexPathes.flatMap() {fetchedResultController.object(at: $0) as? Article}
        
        if artiicles.count > 0 {
            updateWidgetData()
        }
        
        let context = NSManagedObjectContext.mainQueueContext
        context.perform { 
            artiicles.forEach() {
                $0.isBookmarked = false
                $0.bookmarkDate = nil
            }
        }
    }
    
    @IBAction func dismissButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}

extension LocalizedStrings {
    class var bookmarks: String {return NSLocalizedString("Bookmarks", comment: "")}
    class var bookmarkAddGuide: String {return NSLocalizedString("To add a bookmark, long press the star button when reading an article", comment: "")}
}

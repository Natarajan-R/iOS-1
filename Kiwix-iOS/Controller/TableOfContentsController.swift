//
//  TableOfContentsController.swift
//  Kiwix
//
//  Created by Chris Li on 6/26/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit
import DZNEmptyDataSet

class TableOfContentsController: UIViewController, UITableViewDelegate, UITableViewDataSource, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    weak var delegate: TableOfContentsDelegate?
    private var headinglevelMin = 0
    
    var headings = [HTMLHeading]() {
        didSet {
            configurePreferredContentSize()
            headinglevelMin = headings.map({$0.level}).min() ?? 0
            tableView.reloadData()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        tableView.tableFooterView = UIView()
    }
    
    func configurePreferredContentSize() {
        let count = headings.count
        let width = traitCollection.horizontalSizeClass == .regular ? 300 : (UIScreen.main().bounds.width)
        preferredContentSize = CGSize(width: width, height: count == 0 ? 350 : min(CGFloat(count) * 44.0, UIScreen.main().bounds.height * 0.8))
    }

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = headings[(indexPath as NSIndexPath).row].textContent
        cell.indentationLevel = (headings[(indexPath as NSIndexPath).row].level - headinglevelMin) * 2
        return cell
    }
    
    // MARK: - Table view delegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        delegate?.scrollTo(headings[(indexPath as NSIndexPath).row])
    }
    
    // MARK: - Empty table datasource & delegate
    
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Compass")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> AttributedString! {
        let text = NSLocalizedString("Table Of Contents Not Available", comment: "Table Of Content, empty text")
        let attributes = [NSFontAttributeName: UIFont.boldSystemFont(ofSize: 18.0),
                          NSForegroundColorAttributeName: UIColor.darkGray()]
        return AttributedString(string: text, attributes: attributes)
    }
    
    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 0.0
    }
    
    func spaceHeight(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        return 30.0
    }
    
}

protocol TableOfContentsDelegate: class {
    func scrollTo(_ heading: HTMLHeading)
}

//
//  BookCell.swift
//  Kiwix
//
//  Created by Chris on 12/13/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

// MARK: - Book Cells

/* Book Cell With P & I indicator */
class BasicBookCell: UITableViewCell {
    private let hasPicIndicatorOrange = UIColor(red: 1, green: 0.5, blue: 0, alpha: 1)
    private let hasIndexIndicatorBlue = UIColor(red: 0.304706, green: 0.47158, blue: 1, alpha: 1)
    
    override func awakeFromNib() {
        hasPicIndicator.layer.cornerRadius = 2.0
        hasIndexIndicator.layer.cornerRadius = 2.0
        hasPicIndicator.layer.masksToBounds = true
        hasIndexIndicator.layer.masksToBounds = true
    }
    
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var hasPicIndicator: UILabel!
    @IBOutlet weak var hasIndexIndicator: UILabel!
    
    var hasPic: Bool = false {
        didSet {
            hasPicIndicator.backgroundColor = hasPic ? hasPicIndicatorOrange : UIColor.lightGray()
        }
    }
    
    var hasIndex: Bool = false {
        didSet {
            hasIndexIndicator.backgroundColor = hasIndex ? hasIndexIndicatorBlue : UIColor.lightGray()
        }
    }
}

/* Book Cell With P & I indicator, a check mark on the right */
class CheckMarkBookCell: BasicBookCell {
    @IBOutlet weak var accessoryImageView: LargeHitZoneImageView!
    weak var delegate: TableCellDelegate?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(CheckMarkBookCell.handleTap))
        accessoryImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    var isChecked: Bool = false {
        didSet {
            accessoryImageView.isHighlighted = isChecked
        }
    }
    
    func handleTap() {
        self.delegate?.didTapOnAccessoryViewForCell(self)
    }
}

class LocalBookCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var hasPicIndicator: UIView!
}

// MARK:- Book Table Cells

class CloudBookCell: BookTableCell {
    
}

class DownloadBookCell: BookTableCell {
    @IBOutlet weak var articleCountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        articleCountLabel.text = nil
        dateLabel.text = nil
        progressView.progress = 0.0
    }
}

class BookTableCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var hasPicIndicator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var accessoryImageView: LargeHitZoneImageView!
    weak var delegate: TableCellDelegate?
    
    var accessoryImageTintColor: UIColor? {
        didSet {
            guard let imageRenderingMode = accessoryImageView.image?.renderingMode else {return}
            if imageRenderingMode != .alwaysTemplate {
                accessoryImageView.image = accessoryImageView.image?.withRenderingMode(.alwaysTemplate)
            }
            accessoryImageView.tintColor = accessoryImageTintColor
        }
    }
    
    var accessoryHighlightedImageTintColor: UIColor? {
        didSet {
            guard let imageRenderingMode = accessoryImageView.highlightedImage?.renderingMode else {return}
            if imageRenderingMode != .alwaysTemplate {
                accessoryImageView.highlightedImage = accessoryImageView.highlightedImage?.withRenderingMode(.alwaysTemplate)
            }
            accessoryImageView.tintColor = accessoryHighlightedImageTintColor
        }
    }
    
    override func awakeFromNib() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(BookTableCell.handleTap))
        accessoryImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    func handleTap() {
        self.delegate?.didTapOnAccessoryViewForCell(self)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        favIcon.image = nil
        hasPicIndicator.backgroundColor = UIColor.lightGray()
        titleLabel.text = nil
        subtitleLabel.text = nil
        accessoryImageView.isHighlighted = false
    }
}

// MARK: - Article Cell

class ArticleCell: UITableViewCell {
    @IBOutlet weak var favIcon: UIImageView!
    @IBOutlet weak var hasPicIndicator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
}

class ArticleSnippetCell: ArticleCell {
    @IBOutlet weak var snippetLabel: UILabel!
}

// MARK: - Bookmark Cell

class BookmarkCell: UITableViewCell {
    override func awakeFromNib() {
        thumbImageView.layer.cornerRadius = 4.0
        thumbImageView.clipsToBounds = true
    }
    
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
}

class BookmarkSnippetCell: BookmarkCell {
    @IBOutlet weak var snippetLabel: UILabel!
}

// MARK: - Protocol

protocol TableCellDelegate: class {
    func didTapOnAccessoryViewForCell(_ cell: UITableViewCell)
}

//
//  SearchBar.swift
//  Kiwix
//
//  Created by Chris Li on 1/22/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class CustomSearchBar: UISearchBar, UITextFieldDelegate {

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.searchBarStyle = .minimal
        setImage(UIImage(named: "BlankImage"), for: .search, state: UIControlState())
    }
    
    override func layoutSubviews() {
        configure()
        super.layoutSubviews()
    }
    
    override var text: String? {
        get{return customSearchField.text}
        set{customSearchField.text = newValue}
    }
    
    // MARK: - vars
    
    let customSearchField = UITextField()
    let leftImageView = UIImageView(image: UIImage(named: "Wiki")?.withRenderingMode(.alwaysTemplate))
    let rightImageView = UIImageView(image: UIImage(named: "StarHighlighted"))
    
    // MARK: - Configure
    
    func configure() {
        let originalSearchField: UITextField? = {
            for view in subviews {
                for view in view.subviews {
                    guard let searchField = view as? UITextField else {continue}
                    searchField.isUserInteractionEnabled = false
                    return searchField
                }
            }
            return nil
        }()
        
        customSearchField.clearButtonMode = .whileEditing
        customSearchField.translatesAutoresizingMaskIntoConstraints = false
        customSearchField.font = originalSearchField?.font
        customSearchField.textColor = originalSearchField?.textColor
        customSearchField.placeholder = placeholder
        customSearchField.textAlignment = customSearchField.isEditing ? .left : .center
        customSearchField.autocapitalizationType = .none
        customSearchField.autocorrectionType = .no
        customSearchField.spellCheckingType = .no
        customSearchField.delegate = self
        customSearchField.addTarget(self, action: #selector(CustomSearchBar.textFieldDidChange(_:)), for: .editingChanged)
        addSubview(customSearchField)
        
        placeholder = nil
        showsCancelButton = false
        
        let views = ["searchField": customSearchField]
        let metrics = ["rightInset": -2]
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[searchField]-(rightInset)-|", options: .alignAllCenterY, metrics: metrics, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[searchField]-|", options: .alignAllCenterX, metrics: metrics, views: views))
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        customSearchField.textAlignment = .left
        delegate?.searchBarTextDidBeginEditing?(self)
    }
    
    func textFieldDidChange(_ textField: UITextField) {
        guard let text = textField.text else {return}
        delegate?.searchBar?(self, textDidChange: text)
    }
}


// Used in v1.4
class SearchBar: UISearchBar {
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
        self.searchBarStyle = .minimal
        self.autocapitalizationType = .none
        self.placeholder = LocalizedStrings.search
        self.returnKeyType = .go
    }
}

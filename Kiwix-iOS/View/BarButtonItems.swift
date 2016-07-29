//
//  UIBarButtonItemExtention.swift
//  Grid
//
//  Created by Chris on 12/9/15.
//  Copyright © 2015 Chris. All rights reserved.
//

import UIKit

class MessageBarButtonItem: UIBarButtonItem {
    var text: String? {
        get {return label.text}
        set {label.text = newValue}
    }
    
    let label: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 220, height: 40))
        label.textAlignment = .center
        label.numberOfLines = 2
        label.font = UIFont.preferredFont(forTextStyle: UIFontTextStyleCaption2)
        return label
    }()
    
    override init() {
        super.init()
        self.customView = label
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(labelText text: String?) {
        self.init()
        self.customView = label
        self.label.text = text
    }
    
    func setText(_ text: String?, animated: Bool) {
        if animated {
            let animation = CATransition()
            animation.duration = 0.2
            animation.type = kCATransitionFade
            animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            label.layer.add(animation, forKey: "changeTextTransition")
            label.text = ""
            label.text = text
        } else {
            label.text = text
        }
    }
}

// MARK: - Long Press & Tap BarButtonItem
class LPTBarButtonItem: UIBarButtonItem {
    
    // MARK: - init
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(image: UIImage?, highlightedImage: UIImage?, target: AnyObject?, longPressAction: Selector, tapAction: Selector) {
        let customImageView = LargeHitZoneImageView(image: image?.withRenderingMode(.alwaysTemplate),
                                                    highlightedImage: highlightedImage?.withRenderingMode(.alwaysTemplate))
        customImageView.contentMode = UIViewContentMode.scaleAspectFit
        customImageView.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        customImageView.tintColor = UIColor.gray()
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 52, height: 30))
        customImageView.center = containerView.center
        containerView.addSubview(customImageView)
        self.init(customView: containerView)
        
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: target, action: longPressAction)
        let tapGestureRecognizer = UITapGestureRecognizer(target: target, action: tapAction)
        containerView.addGestureRecognizer(longPressGestureRecognizer)
        containerView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    convenience init(imageName: String?, highlightedImageName: String? = nil, grayed: Bool = true, delegate: LPTBarButtonItemDelegate) {
        let image: UIImage? = {
            guard let imageName = imageName else {return nil}
            return UIImage(named: imageName)
        }()
        let highlightedImage: UIImage? = {
            guard let highlightedImageName = highlightedImageName else {return nil}
            return UIImage(named: highlightedImageName)
        }()
        
        let customImageView = LargeHitZoneImageView(image: image, highlightedImage: highlightedImage)
        customImageView.contentMode = UIViewContentMode.scaleAspectFit
        customImageView.frame = CGRect(x: 0, y: 0, width: 26, height: 26)
        customImageView.tintColor = grayed ? UIColor.gray() : nil
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 30)) // on ipad may be 52, 44 is value on iP6s+, to be investigated
        customImageView.center = containerView.center
        containerView.addSubview(customImageView)
        self.init(customView: containerView)

        self.delegate = delegate
        self.customImageView = customImageView
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(LPTBarButtonItem.handleLongPressGesture(_:)))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LPTBarButtonItem.handleTapGesture(_:)))
        containerView.addGestureRecognizer(longPressGestureRecognizer)
        containerView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - properties
    
    weak var delegate: LPTBarButtonItemDelegate?
    var customImageView: LargeHitZoneImageView?
    var isRotating = false
    
    // MARK: - handle gesture
    
    func handleTapGesture(_ gestureRecognizer: UIGestureRecognizer) {
        delegate?.barButtonTapped(self, gestureRecognizer: gestureRecognizer)
    }
    
    func handleLongPressGesture(_ gestureRecognizer: UIGestureRecognizer) {
        guard gestureRecognizer.state == .began else {return}
        delegate?.barButtonLongPressedStart(self, gestureRecognizer: gestureRecognizer)
    }
    
    // MARK: - rotate
    
    func startRotating() {
        guard !isRotating else {return}
        isRotating = true
        rotateImage(1.0, angle: CGFloat(M_PI * 2))
    }
    
    func stopRotating() {
        isRotating = false
    }
    
    private func rotateImage(_ duration: CFTimeInterval, angle: CGFloat) {
        CATransaction.begin()
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.byValue = angle
        rotationAnimation.duration = duration
        rotationAnimation.isRemovedOnCompletion = true
        
        CATransaction.setCompletionBlock { () -> Void in
            guard self.isRotating else {return}
            self.rotateImage(duration, angle: angle)
        }
        customImageView?.layer.add(rotationAnimation, forKey: "rotationAnimation")
        CATransaction.commit()
    }
}

protocol LPTBarButtonItemDelegate: class {
    func barButtonTapped(_ sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer)
    func barButtonLongPressedStart(_ sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer)
}

extension LPTBarButtonItemDelegate {
    func barButtonTapped(_ sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        return
    }
    func barButtonLongPressedStart(_ sender: LPTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        return
    }
}

// MARK: - Helper Class

class LargeHitZoneImageView: UIImageView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let frame = self.bounds.insetBy(dx: -9, dy: -9)
        return frame.contains(point) ? self : nil
    }
}

extension UIBarButtonItem {
    convenience init(barButtonSystemItem systemItem: UIBarButtonSystemItem) {
        self.init(barButtonSystemItem: systemItem, target: nil, action: nil)
    }
    
    convenience init(imageNamed name: String, target: AnyObject?, action: Selector) {
        let image = UIImage(named: name)?.withRenderingMode(.alwaysTemplate)
        self.init(image: image, style: .plain, target: target, action: action)
    }
}

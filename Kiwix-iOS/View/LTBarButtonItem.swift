//
//  LTBarButtonItem.swift
//  UIControls
//
//  Created by Chris Li on 2/12/16.
//  Copyright © 2016 Chris Li. All rights reserved.
//

import UIKit

class LTBarButtonItem: UIBarButtonItem {
    
    weak var delegate: LTBarButtonItemDelegate?
    var customImageView: LargeHitZoneImageView?
    
    // MARK: - init
    
    override init() {
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    convenience init(configure: BarButtonConfig) {
        let image: UIImage? = {
            guard let imageName = configure.imageName else {return nil}
            return UIImage(named: imageName)?.withRenderingMode(configure.renderingMode)
        }()
        let highlightedImage: UIImage? = {
            guard let highlightedImageName = configure.highlightedImageName else {return nil}
            return UIImage(named: highlightedImageName)?.withRenderingMode(configure.highlightedrenderingMode)
        }()
        
        let customImageView = LargeHitZoneImageView(image: image, highlightedImage: highlightedImage)
        customImageView.contentMode = UIViewContentMode.scaleAspectFit
        customImageView.frame = CGRect(x: 0, y: 0, width: 22, height: 22)
        customImageView.tintColor = configure.tintColor
        let containerView = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 30))
        customImageView.center = containerView.center
        containerView.addSubview(customImageView)
        self.init(customView: containerView)
        
        self.delegate = configure.delegate
        self.customImageView = customImageView
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(LTBarButtonItem.handleLongPressGesture(_:)))
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(LTBarButtonItem.handleTapGesture(_:)))
        containerView.addGestureRecognizer(longPressGestureRecognizer)
        containerView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    // MARK: - rotate
    
    var isRotating = false
    
    func startRotating() {
        guard !isRotating else {return}
        isRotating = true
        self.customView?.tintColor = UIColor.gray()
        rotateImage(1.5, angle: CGFloat(M_PI * 2))
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
            guard self.isRotating else {
                self.customView?.tintColor = nil
                return
            }
            self.rotateImage(duration, angle: angle)
        }
        self.customView?.layer.add(rotationAnimation, forKey: "rotationAnimation")
        CATransaction.commit()
    }
    
    // MARK: - handle gesture
    
    func handleTapGesture(_ gestureRecognizer: UIGestureRecognizer) {
        guard !isRotating else {return}
        delegate?.barButtonTapped(self, gestureRecognizer: gestureRecognizer)
    }
    
    func handleLongPressGesture(_ gestureRecognizer: UIGestureRecognizer) {
        guard gestureRecognizer.state == .began else {return}
        guard !isRotating else {return}
        delegate?.barButtonLongPressedStart(self, gestureRecognizer: gestureRecognizer)
    }
}

protocol LTBarButtonItemDelegate: class {
    func barButtonTapped(_ sender: LTBarButtonItem, gestureRecognizer: UIGestureRecognizer)
    func barButtonLongPressedStart(_ sender: LTBarButtonItem, gestureRecognizer: UIGestureRecognizer)
}

extension LTBarButtonItemDelegate {
    func barButtonTapped(_ sender: LTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        return
    }
    func barButtonLongPressedStart(_ sender: LTBarButtonItem, gestureRecognizer: UIGestureRecognizer) {
        return
    }
}

struct BarButtonConfig {
    var imageName: String?
    var highlightedImageName: String?
    var renderingMode: UIImageRenderingMode = .alwaysTemplate
    var highlightedrenderingMode: UIImageRenderingMode = .alwaysTemplate
    var tintColor: UIColor?
    
    weak var delegate: LTBarButtonItemDelegate?
    
    init(imageName: String) {
        self.imageName = imageName
    }
    
    init(imageName: String, delegate: LTBarButtonItemDelegate?) {
        self.imageName = imageName
        self.delegate = delegate
    }
}

//
//  BookmarkControllerAnimator.swift
//  Kiwix
//
//  Created by Chris Li on 7/15/16.
//  Copyright © 2016 Chris. All rights reserved.
//

import UIKit

class BookmarkControllerAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    private let animateIn: Bool
    
    init(animateIn: Bool) {
        self.animateIn = animateIn
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        if animateIn {
            animateInTransition(transitionContext)
        } else {
            animateOutTransition(transitionContext)
        }
    }
    
    private func animateInTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let toController = transitionContext.viewController(forKey: UITransitionContextToViewControllerKey) as? BookmarkController,
            let toView = transitionContext.view(forKey: UITransitionContextToViewKey) else {return}
        let containerView = transitionContext.containerView()
        let duration = transitionDuration(using: transitionContext)
        
        containerView.addSubview(toView)
        toView.frame = containerView.frame
        toView.alpha = 0.0
        
        let halfHeight = containerView.frame.height / 2
        toController.centerViewYOffset.constant = toController.bookmarkAdded ? -(halfHeight + toController.bottomHalfHeight) : (halfHeight + toController.topHalfHeight)
        toController.view.layoutIfNeeded()
        
        UIView.animate(withDuration: duration * 0.5, delay: 0.0, options: .curveLinear, animations: {
            toView.alpha = 1.0
            }, completion: nil)
        
        UIView.animate(withDuration: duration * 0.9, delay: duration * 0.1, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.0, options: UIViewAnimationOptions.curveEaseOut, animations: {
            toController.centerViewYOffset.constant = 0.0
            toController.view.layoutIfNeeded()
        }) { (completed) in
            transitionContext.completeTransition(completed)
        }
    }
    
    private func animateOutTransition(_ transitionContext: UIViewControllerContextTransitioning) {
        guard let fromController = transitionContext.viewController(forKey: UITransitionContextFromViewControllerKey) as? BookmarkController,
            let fromView = transitionContext.view(forKey: UITransitionContextFromViewKey) else {return}
        let containerView = transitionContext.containerView()
        let duration = transitionDuration(using: transitionContext)
        
        let halfHeight = containerView.frame.height / 2
        fromController.view.layoutIfNeeded()
        
        UIView.animate(withDuration: duration * 0.7, delay: duration * 0.3, options: .curveLinear, animations: {
            fromView.alpha = 0.0
            }) { (completed) in
                transitionContext.completeTransition(completed)
        }
        
        UIView.animate(withDuration: duration * 0.4, delay: 0.0, options: .curveEaseIn, animations: {
            fromController.centerViewYOffset.constant = fromController.bookmarkAdded ? halfHeight + fromController.topHalfHeight : -(halfHeight + fromController.bottomHalfHeight)
            fromController.view.layoutIfNeeded()
            }, completion: nil)
        
        if fromController.bookmarkAdded {
            UIView.animate(withDuration: duration * 0.3, delay: 0.0, options: .curveLinear, animations: {
                fromController.messageLabel.alpha = 0.0
                }, completion: nil)
        }
        
    }
    
    func animationEnded(_ transitionCompleted: Bool) {
        
    }
}

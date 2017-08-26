//
//  Transition.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Foundation

extension CameraViewController {
    internal final class _PresentationAnimator: NSObject {
        var isDismissal: Bool = false
        var previewOriginFrame: CGRect = .zero
        
        class var presentation: _PresentationAnimator { return _PresentationAnimator() }
        class var dismissal: _PresentationAnimator {
            let dismissal = _PresentationAnimator()
            dismissal.isDismissal = true
            return dismissal
        }
    }
}

extension CameraViewController._PresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isDismissal ? 0.35 : 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        let containerView = transitionContext.containerView
        let view = transitionContext.view(forKey: isDismissal ? .from : .to)!
        let viewController = transitionContext.viewController(forKey: isDismissal ? .from : .to)! as! CameraViewController
        let imagePicker = transitionContext.viewController(forKey: isDismissal ? .to: .from) as! TabNavigationImagePickerController
        let finalFrame = transitionContext.finalFrame(for: viewController)
        
        containerView.addSubview(view)
        let scale = CGPoint(x: previewOriginFrame.width / finalFrame.width, y: previewOriginFrame.height / finalFrame.height)
        let translation = CGPoint(x: previewOriginFrame.midX - finalFrame.midX, y: previewOriginFrame.midY - finalFrame.midY)
        
        if isDismissal {
            containerView.insertSubview(transitionContext.view(forKey: .to)!, at: 0)
            let displayView = CameraViewController.DisplayView()
            displayView.frame = view.bounds
            containerView.insertSubview(displayView, belowSubview: view)
            imagePicker._captureDisplayViews.update(with: displayView)
            let backgroundColor = view.backgroundColor
            view.backgroundColor = .clear
            
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.0, options: [], animations: {
                view.transform = CGAffineTransform(scaleX: scale.x, y: scale.y).translatedBy(x: translation.x / scale.x, y: translation.y / scale.y)
                displayView.frame = self.previewOriginFrame
                viewController.topBar.alpha = 0.0
                viewController.previewView.alpha = 0.0
                viewController.bottomBar.alpha = 0.0
            }) { (_) in
                if let index = imagePicker._captureDisplayViews.index(of: displayView) {
                    imagePicker._captureDisplayViews.remove(at: index)
                }
                view.backgroundColor = backgroundColor
                viewController.previewView.alpha = 1.0
                transitionContext.completeTransition(true)
            }
            /* UIView.animate(withDuration: duration * 0.8, delay: duration * 0.2, options: [], animations: {
             viewController._previewView.alpha = 0.0
             }) { (_) in
             viewController._previewView.alpha = 1.0
             } */
        } else {
            view.transform = CGAffineTransform(scaleX: scale.x, y: scale.y).translatedBy(x: translation.x / scale.x, y: translation.y / scale.y)
            viewController.topBar.alpha = 0.0
            viewController.bottomBar.alpha = 0.0
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
                view.transform = .identity
                viewController.topBar.alpha = 1.0
                viewController.bottomBar.alpha = 1.0
            }) { (_) in
                transitionContext.completeTransition(true)
            }
        }
    }
}

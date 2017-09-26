//
//  _ScrollViewDelegates.swift
//  AxReminder
//
//  Created by devedbox on 2017/9/19.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

// MARK: - _ScrollViewDelegateQueue.

/// A type representing the managing queue of the delegates of one UIScrollView.
/// The delegates is managed with the NSHashTable as the storage.
internal class _ScrollViewDelegatesQueue: NSObject {
    /// Delegates storage.
    fileprivate let _hashTable = NSHashTable<UIScrollViewDelegate>.weakObjects()
    /// A closure to get the view for scroll view's zooming.
    var viewForZooming: ((UIScrollView) -> UIView?)? = nil
    /// A closure decides whether the scroll view should scroll to top.
    var scrollViewShouldScrollToTop: ((UIScrollView) -> Bool)? = nil
}
// Confirming to UIScrollViewDelegate.
extension _ScrollViewDelegatesQueue: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _hashTable.allObjects.forEach{ $0.scrollViewDidScroll?(scrollView) }
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        _hashTable.allObjects.forEach{ $0.scrollViewDidZoom?(scrollView) }
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _hashTable.allObjects.forEach{ $0.scrollViewWillBeginDragging?(scrollView) }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        _hashTable.allObjects.forEach{ $0.scrollViewWillEndDragging?(scrollView, withVelocity: velocity, targetContentOffset: targetContentOffset) }
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        _hashTable.allObjects.forEach{ $0.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate) }
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        _hashTable.allObjects.forEach{ $0.scrollViewWillBeginDecelerating?(scrollView) }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        _hashTable.allObjects.forEach{ $0.scrollViewDidEndDecelerating?(scrollView) }
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        _hashTable.allObjects.forEach{ $0.scrollViewDidEndScrollingAnimation?(scrollView) }
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        _hashTable.allObjects.forEach{ $0.scrollViewWillBeginZooming?(scrollView, with: view) }
    }
    
    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        _hashTable.allObjects.forEach{ $0.scrollViewDidEndZooming?(scrollView, with: view, atScale: scale) }
    }
    
    @available(iOS 11.0, *)
    func scrollViewDidChangeAdjustedContentInset(_ scrollView: UIScrollView) {
        _hashTable.allObjects.forEach{ $0.scrollViewDidChangeAdjustedContentInset?(scrollView) }
    }
}

extension _ScrollViewDelegatesQueue {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return viewForZooming?(scrollView)
    }
    
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        return scrollViewShouldScrollToTop?(scrollView) ?? false
    }
}

extension _ScrollViewDelegatesQueue {
    /// Add a new UIScrollViewDelegate object to the managed queue.
    /// - Parameter delegate: A UIScrollViewDelegate to be added and managed.
    func add(_ delegate: UIScrollViewDelegate?)    { _hashTable.add(delegate)     }
    /// Remove a existing UIScrollViewDelegate object from the managed queue.
    /// - Parameter delegate: The existing delegate the be removed.
    func remove(_ delegate: UIScrollViewDelegate?) { _hashTable.remove(delegate)  }
    /// Remove all the managed UIScrollViewDelegate objects.
    func removeAll()                              { _hashTable.removeAllObjects() }
}

// MARK: - _ScrollViewDidEndScrollingAnimation.

/// A type reresenting the a hook of UIScrollViewDelegate to set as the temporary
/// delegate and to get the call back of the `setContentOffset(:animated:)` if the
/// transition is animated.
internal class _ScrollViewDidEndScrollingAnimation: NSObject {
    fileprivate var _completion: ((UIScrollView)->Void)
    /// Creates a _ScrollViewDidEndScrollingAnimation object with the call back closure.
    ///
    /// - Parameter completion: A closure will be triggered when the `scrollViewDidEndScrollingAnimation(:)` is called.
    /// - Returns: A _ScrollViewDidEndScrollingAnimation with the call back closure.
    internal init(_ completion: @escaping (UIScrollView)->Void) {
        _completion = completion
        super.init()
    }
}
// Confirming of UIScrollViewDelegate.
extension _ScrollViewDidEndScrollingAnimation: UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        _completion(scrollView)
    }
}

// MARK: - _ScrollViewDidScroll.

/// A type reresenting the a hook of UIScrollViewDelegate to set as the temporary
/// delegate and to get the call back when scroll view did scroll.
internal class _ScrollViewDidScroll: NSObject {
    fileprivate var _didScroll: ((UIScrollView) -> Void)
    /// Creates a _ScrollViewDidScroll object with the call back closure.
    ///
    /// - Parameter completion: A closure will be triggered when the `scrollViewDidScroll(:)` is called.
    /// - Returns: A _ScrollViewDidScroll with the call back closure.
    internal init(_ didScroll: @escaping ((UIScrollView) -> Void)) {
        _didScroll = didScroll
    }
}
// Confirming of UIScrollViewDelegate.
extension _ScrollViewDidScroll: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _didScroll(scrollView)
    }
}

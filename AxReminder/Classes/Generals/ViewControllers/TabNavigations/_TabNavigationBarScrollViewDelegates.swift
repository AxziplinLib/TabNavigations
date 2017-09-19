//
//  _TabNavigationBarScrollViewDelegates.swift
//  AxReminder
//
//  Created by devedbox on 2017/9/19.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

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

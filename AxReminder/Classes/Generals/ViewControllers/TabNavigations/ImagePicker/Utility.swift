//
//  Utility.swift
//  TabNavigations/ImagePicker
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

public extension UIEdgeInsets {
    /// A value indicate the horizontal length of the edge insets.
    ///
    /// - Returns: `.left` + `.right`.
    public var width: CGFloat { return left + right }
    /// A value indicate the vertical length of the edge insets.
    ///
    /// - Returns: `.top` + `.bottom`.
    public var height: CGFloat { return top + bottom }
    /// Initialize a new `UIEdgeInsets` instance with horizontal length.
    /// The values of `.left` and `.right` will both be `width * 0.5`.
    ///
    /// - Parameter width: The hotizontal length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` both `.left` and `.right` are width * 0.5.
    public init(width : CGFloat) { self.init(top: 0.0, left: width * 0.5, bottom: 0.0, right: width * 0.5) }
    /// Initialize a new `UIEdgeInsets` instance with vertical length.
    /// The values of `.top` and `.bottom` will both be `width * 0.5`.
    ///
    /// - Parameter height: The vertical length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` both `.top` and `.bottom` are height * 0.5.
    public init(height: CGFloat) { self.init(top: height * 0.5, left: 0.0, bottom: height * 0.5, right: 0.0) }
    /// Initialize a new `UIEdgeInsets` instance with left length.
    ///
    /// - Parameter left: The left length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` with only left length.
    public init(left  : CGFloat) { self.init(top: 0.0, left: left, bottom: 0.0, right: 0.0) }
    /// Initialize a new `UIEdgeInsets` instance with right length.
    ///
    /// - Parameter right: The right length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` with only right length.
    public init(right : CGFloat) { self.init(top: 0.0, left: 0.0, bottom: 0.0, right: right) }
    /// Initialize a new `UIEdgeInsets` instance with top length.
    ///
    /// - Parameter top: The top length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` with only top length.
    public init(top   : CGFloat) { self.init(top: top, left: 0.0, bottom: 0.0, right: 0.0) }
    /// Initialize a new `UIEdgeInsets` instance with bottom length.
    ///
    /// - Parameter bottom: The bottom length of the edge insets.
    /// - Returns: A new instance of `UIEdgeInsets` with only bottom length.
    public init(bottom: CGFloat) { self.init(top: 0.0, left: 0.0, bottom: bottom, right: 0.0) }
}

internal extension UIView {
    /// Remove the specified constraint from the receiver if the constraint is not nil.
    /// And do nothing if the constraint is nil.
    ///
    /// - Parameter constraint: The target constraint to be removed if any.
    ///
    func removeConstraintIfNotNil(_ constraint: NSLayoutConstraint?) { if let const_ = constraint { removeConstraint(const_) } }
}

//
//  TabNavigationUtility.swift
//  TabNavigations
//
//  Created by devedbox on 2017/8/14.
//  Copyright © 2017年 devedbox. All rights reserved.
//

/// Return true if the index is in the bounds, otherwise false.
/// 
/// - Parameter index: The index to be checked.
/// - Parameter bounds: The bounds where the index lay in.
///
/// - Returns: Indicate the index is in the bounds or not.
///
internal func _earlyCheckingBounds<T>(_ index: Array<T>.Index, `in` bounds: Array<T>) -> Swift.Bool { return index >= bounds.startIndex && index < bounds.endIndex }

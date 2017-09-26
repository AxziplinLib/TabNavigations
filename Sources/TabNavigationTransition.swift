//
//  TabNavigationTransition.swift
//  AxReminder
//
//  Created by devedbox on 2017/9/19.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Foundation

internal class TabNavigationTitleItemTransition: NSObject {
    fileprivate var _transitionQueue = DispatchQueue(label: "com.transition.tabnavigationbar")
    /// Indicates the transition is interactive or animated.
    fileprivate var animated: Bool = false
    /// The referenced tab navigation bar.
    weak var tabNavigationBar: TabNavigationBar?
    /// A closure triggered when the index reached the threshold.
    var didUpdateSelectedIndex: ((Array<TabNavigationTitleItem>.Index) -> Void)?
    /// Animation did finished call back.
    var animationDidFinished: ((UIScrollView) -> Void)?
}

extension TabNavigationTitleItemTransition {
    /// Returns a animated transition delegate.
    class var animated: TabNavigationTitleItemTransition {
        let transition = TabNavigationTitleItemTransition()
        transition.animated = true
        return transition
    }
}

extension TabNavigationTitleItemTransition {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        animationDidFinished?(scrollView)
    }
}

extension TabNavigationTitleItemTransition: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !scrollView.isDragging, !scrollView.isTracking, !scrollView.isDecelerating else { return }
        guard let  titleItems                  = tabNavigationBar?.navigationTitleItems,
              let _offsetPositionsUpToEndIndex = tabNavigationBar?._offsetPositionsUpToEndIndex
        else { return }
        let   offsetx  = scrollView.contentOffset.x
        // print("Transition offset: \(offsetx)")
        guard !_offsetPositionsUpToEndIndex.isEmpty && !titleItems.isEmpty else { return }
        guard offsetx >= 0 && offsetx <= _offsetPositionsUpToEndIndex[titleItems.lastIndex] else { return }
        
        for (index, titleItem) in titleItems.enumerated() {
            let offsetPosition      = _offsetPositionsUpToEndIndex[index]
            let selected            = (offsetPosition >= offsetx)
            
            if  selected { guard index > titleItems.startIndex else { continue } } else {
                guard index < titleItems.index(before: titleItems.endIndex) else { continue }
            }
            
            let offsetPositionDelta = selected
                ? (offsetPosition - _offsetPositionsUpToEndIndex[titleItems.index(before: index)])
                : (_offsetPositionsUpToEndIndex[titleItems.index(after: index)] - offsetPosition)
            
            guard fabs(offsetPosition - offsetx) <= offsetPositionDelta else {
                titleItem.selected = false; continue
            }
            
            let relativeOffsetX = selected
                ? (offsetx - _offsetPositionsUpToEndIndex[titleItems.index(before: index)])
                : (offsetx -  offsetPosition)
            let transitionPercent = relativeOffsetX / offsetPositionDelta
            
            let color = UIColor.color(from: titleItem.titleColor(whenSelected: !selected),
                                      to  : titleItem.titleColor(whenSelected:  selected),
                                      percent: transitionPercent)
            let font  = UIFont.font(from: titleItem.titleFont(whenSelected: !selected),
                                    to  : titleItem.titleFont(whenSelected:  selected),
                                    percent: transitionPercent)!
            
            if  let range     = titleItem.selectedRange {
                let _ns_range = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)
                let
                attributedTitle = NSMutableAttributedString(attributedString: titleItem.underlyingButton.attributedTitle(for: .normal)!)
                attributedTitle.addAttributes([NSFontAttributeName: font], range: _ns_range)
                attributedTitle.addAttributes([NSForegroundColorAttributeName: color], range: _ns_range)
                
                titleItem.underlyingButton.setAttributedTitle(attributedTitle, for: .normal)
            } else {
                titleItem.underlyingButton.titleLabel?.font = font
                titleItem.underlyingButton.setTitleColor(color, for: .normal)
                titleItem.underlyingButton.tintColor = color
            }
            
            self.didUpdateSelectedIndex?(transitionPercent > 0.5 ? (selected ? index : titleItems.index(after: index)) : (selected ? titleItems.index(before: index) : index))
        }
    }
}

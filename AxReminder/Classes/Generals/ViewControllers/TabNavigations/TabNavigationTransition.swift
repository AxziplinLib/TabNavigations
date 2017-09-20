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
        guard let titleItems = tabNavigationBar?.navigationTitleItems, let _offsetPositionsUpToEndIndex = tabNavigationBar?._offsetPositionsUpToEndIndex else { return }
        guard !scrollView.isDragging, !scrollView.isTracking, !scrollView.isDecelerating else { return }
        let offsetX = scrollView.contentOffset.x
        
        autoreleasepool { _transitionQueue.async { autoreleasepool { [unowned self] in
            for (index, titleItem) in titleItems.enumerated() {
                let offsetPosition      = _offsetPositionsUpToEndIndex[index]
                let selected            = (offsetPosition >= offsetX)
                
                if  selected { guard index > titleItems.startIndex else { continue } } else {
                    guard index < titleItems.index(before: titleItems.endIndex) else { continue }
                }
                
                let offsetPositionDelta = selected
                    ? (offsetPosition - _offsetPositionsUpToEndIndex[titleItems.index(before: index)])
                    : (_offsetPositionsUpToEndIndex[titleItems.index(after: index)] - offsetPosition)
                
                guard fabs(offsetPosition - offsetX) <= offsetPositionDelta else {
                    DispatchQueue.main.async { titleItem.selected = false }; continue
                }
                
                let relativeOffsetX = selected
                    ? (offsetX - _offsetPositionsUpToEndIndex[titleItems.index(before: index)])
                    : (offsetX -  offsetPosition)
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
                    attributedTitle = NSMutableAttributedString(attributedString: titleItem._button.attributedTitle(for: .normal)!)
                    attributedTitle.addAttributes([NSFontAttributeName: font], range: _ns_range)
                    attributedTitle.addAttributes([NSForegroundColorAttributeName: color], range: _ns_range)
                    
                    DispatchQueue.main.async {
                        titleItem._button.setAttributedTitle(attributedTitle, for: .normal)
                    }
                } else {
                    DispatchQueue.main.async {
                        titleItem._button.titleLabel?.font = font
                        titleItem._button.setTitleColor(color, for: .normal)
                        titleItem._button.tintColor = color
                    }
                }
                
                self.didUpdateSelectedIndex?(transitionPercent > 0.5 ? (selected ? index : titleItems.index(after: index)) : (selected ? titleItems.index(before: index) : index))
            }
        } } }
    }
}

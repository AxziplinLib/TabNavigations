//
//  NavigationBar.swift
//  TabNavigations
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

private let DefaultTitleFontSize: CGFloat = 36.0
private let DefaultTitleUnselectedFontSize: CGFloat = 16.0
private let DefaultTabNavigationItemFontSize: CGFloat = 14.0
private let DefaultTabNavigationTitleItemPadding: CGFloat = 15.0
private let DefaultTabNavigationItemEdgeMargin: CGFloat = 8.0
private let DefaultTabNavigationItemHeight: CGFloat = 44.0
private let DefaultTabNavigationItemWidthThreshold: CGFloat = 30.0

extension TabNavigationBar {
    public class var paddingOfTitleItems: CGFloat { return DefaultTabNavigationTitleItemPadding }
}

extension TabNavigationBar {
    fileprivate class _TabNavigaitonTitleContentAlignmentView: UIView {}
}

@objc
public protocol TabNavigationBarDelegate {
    @objc
    optional func tabNavigationBar(_ tabNavigationBar: TabNavigationBar, willSelectTitleItemAt index: Int, animated: Bool) -> Void
    @objc
    optional func tabNavigationBar(_ tabNavigationBar: TabNavigationBar, didSelectTitleItemAt index: Int) -> Void
    @objc
    optional func tabNavigationBarDidTouchNavigatiomBackItem(_ tabNavigationBar: TabNavigationBar) -> Void
}

private func _createGeneralContainerView<T>() -> T where T: UIView {
    let view = T()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.clipsToBounds = true
    return view
}

private func _createGeneralScrollView<T>(alwaysBounceHorizontal: Bool = true) -> T where T: UIScrollView {
    let scrollView = T()
    scrollView.clipsToBounds = true
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.scrollsToTop = false
    scrollView.backgroundColor = UIColor.clear
    scrollView.decelerationRate = UIScrollViewDecelerationRateFast
    scrollView.alwaysBounceHorizontal = alwaysBounceHorizontal
    scrollView.delaysContentTouches = false
    return scrollView
}

private func _createGeneralAlignmentLabel<T>(font: UIFont? = nil) -> T where T: UILabel {
    let label = T()
    label.text = "AL"
    label.translatesAutoresizingMaskIntoConstraints = false
    label.font = font ?? /*UIFont(name: "PingFangSC-Semibold", size: DefaultTitleFontSize)*/UIFont.boldSystemFont(ofSize: DefaultTitleFontSize)
    label.textColor = .clear
    label.backgroundColor = .clear
    return label
}

private func _createGenetalEffectView(style: TabNavigationBar.TranslucentStyle = .light) -> UIVisualEffectView {
    if style == .light {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .extraLight))
        effectView.translatesAutoresizingMaskIntoConstraints = false
        return effectView
    } else {
        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        effectView.translatesAutoresizingMaskIntoConstraints = false
        return effectView
    }
}

extension TabNavigationBar {
    public enum TranslucentStyle {
        case light
        case dark
    }
}

extension TabNavigationBar {
    public typealias TabNavigationItemViews = (itemsContainerView: UIView, itemsScrollView: UIScrollView, itemsView: UIView)
    public typealias TabNavigationItemAnimationContext = (fromItemViews: TabNavigationItemViews, toItemViews: TabNavigationItemViews)
    public typealias TabNavigationTitleItemViews = (itemsScrollView: UIScrollView, itemsView: UIView, fixSpacing: UILayoutGuide)
    public typealias TabNavigationTitleItemAnimationContext = (containerView: UIView, fromItemViews: TabNavigationTitleItemViews, toItemViews: TabNavigationTitleItemViews)
    public typealias TabNavigationTransitionContext = (backItem: TabNavigationItem, titleViews: TabNavigationTitleItemAnimationContext, itemViews: TabNavigationItemAnimationContext)
}

public class TabNavigationBar: UIView, UIBarPositioning {
    // MARK: - Public Properties.
    public weak var delegate: TabNavigationBarDelegate?
    public var isTranslucent: Bool = false {
        didSet {
            if isTranslucent {
                _setupEffectView()
            } else {
                _effectView.removeFromSuperview()
                backgroundColor = _normalBackgroundColor
                _normalBackgroundColor = nil
            }
        }
    }
    public var translucentStyle: TranslucentStyle = .light {
        didSet {
            if isTranslucent {
                _setupEffectView()
            }
        }
    }
    /// The height of the content area of the tab navigation bar ignoring the top edge of the safe area.
    ///
    /// You typically use this property to set the height of the tab navigation bar instead of the setting
    /// the frame or constraint of the tab navigation bar.
    ///
    /// Default value: 64.0.
    public var height: CGFloat = 64.0 {
        didSet {
            _heightConstraint?.constant = height
            _heightConstraintOfContainerView?.constant = height
            setNeedsLayout()
        }
    }
    // MARK: - Private Properties.
    fileprivate var _normalBackgroundColor: UIColor?
    /// The container view contains the title-items and navigation-items views.
    fileprivate lazy var _containerView: UIView = _createGeneralContainerView()
    fileprivate lazy var __titleAlignmentLabel: UILabel = _createGeneralAlignmentLabel()
    fileprivate lazy var _titleItemsContainerView: UIView = _createGeneralContainerView()
    fileprivate lazy var _itemsContainerView: UIView = _createGeneralContainerView()
    fileprivate lazy var _titleItemsScrollView: UIScrollView = _createGeneralScrollView()
    fileprivate lazy var _itemsScrollView: UIScrollView = _createGeneralScrollView(alwaysBounceHorizontal: false)
    fileprivate lazy var _navigationTitleItemView: UIView = _createGeneralContainerView()
    fileprivate lazy var _navigationItemView: UIView = _createGeneralContainerView()
    fileprivate lazy var _effectView: UIVisualEffectView = _createGenetalEffectView()
    internal    var _offsetPositionsUpToEndIndex: [CGFloat] = []
    fileprivate let _positionQueue = DispatchQueue(label: "com.tabnavigationbar.position")
    
    private var _titleItemsPreviewPanGesture: UIPanGestureRecognizer!
    
    fileprivate var _navigationBackItem: _TabNavigationBackItem = _TabNavigationBackItem(image:UIImage(named: "Resources.bundle/navigation_back", in: Bundle(for: TabNavigationBar.self), compatibleWith: nil))
    fileprivate var _navigationItems: [TabNavigationItem] = []
    fileprivate var _navigationTitleItems: [TabNavigationTitleItem] = [] { didSet { _offsetPositionsUpToEndIndex = _horizontalOffsetsUptoEachIndexs() } }
    fileprivate var _navigationTitleActionItems: [TabNavigationTitleActionItem] = []
    
    fileprivate var _selectedTitleItemIndex: Int = 0 {
        didSet {
            if _selectedTitleItemIndex > _navigationTitleItems.startIndex {
                _titleItemsPreviewPanGesture.isEnabled = true
            } else {
                _titleItemsPreviewPanGesture.isEnabled = false
            }
        }
    }
    // MARK: Delegates.
    fileprivate let _delegatesQueue = _ScrollViewDelegatesQueue()
    fileprivate var _didEndScrollingAnimation: _ScrollViewDidEndScrollingAnimation!
    fileprivate let _interactiveTransition = TabNavigationTitleItemTransition()
    fileprivate let _animatedTransition    = TabNavigationTitleItemTransition.animated
    // MARK: Constraints.
    private weak var _heightConstraint: NSLayoutConstraint?
    private weak var _heightConstraintOfContainerView: NSLayoutConstraint?
    private weak var _horizontalConstraintOfBackItem: NSLayoutConstraint?
    fileprivate weak var _leadingConstraintOfLastItemView: NSLayoutConstraint?
    fileprivate weak var _leadingConstraintOfLastTransitionItemView: NSLayoutConstraint?
    private weak var _trailingConstraintOfLastTitleItemLabel: NSLayoutConstraint?
    private weak var _trailingConstraintOfLastTransitionTitleItemLabel: NSLayoutConstraint?
    private weak var _trailingConstraintOfLastTitleActionItemLabel: NSLayoutConstraint?
    private weak var _trailingConstraintOfLastTransitionTitleActionItemLabel: NSLayoutConstraint?
    fileprivate weak var _widthOfNavigationItemViewForZeroContent: NSLayoutConstraint?
    fileprivate weak var _widthOfTransitionNavigationItemViewForZeroContent: NSLayoutConstraint?
    fileprivate weak var _constraintBetweenTitlesAndItems: NSLayoutConstraint?
    fileprivate weak var _constraintBetweenTransitionTitlesAndItems: NSLayoutConstraint?
    @available(*, unavailable)
    fileprivate lazy var _titleItemContentAlignmentView: _TabNavigaitonTitleContentAlignmentView = _createGeneralContainerView()
    fileprivate lazy var _titleItemFixSpacingLayoutGuide: UILayoutGuide = UILayoutGuide()
    fileprivate weak var _widthOfTitleItemContentAlignmentView: NSLayoutConstraint?
    fileprivate weak var _widthOfTransitionTitleItemContentAlignmentView: NSLayoutConstraint?
    
    // MARK: - `NSCoding` supporting.
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        _initializer()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        _initializer()
    }
    
    convenience init() {
        self.init(frame: .zero)
    }
    
    // Initializer:
    private func _initializer() {
        // Set up the height of the tab navigation bar.
        _constraintHeight()
        // Set up container views:
        _constraintContainerViews()
        _setupPreviewGesture()
        
        _constraintViewsOfTitleItems()
        _constraintViewsOfNavigationItems()
        
        _setupDelegates()
        _navigationBackItem.underlyingButton.addTarget(self, action: #selector(_handleNavigationBack(_:)), for: .touchUpInside)
    }
    
    // MARK: - Actions.
    
    @objc
    private func _handleDidSelectTitleItem(_ sender: _TabNavigationTitleItemButton) {
        guard let _titleItem = sender._titleItem else { return }
        
        if let index = _navigationTitleItems.index(of: _titleItem), index != _selectedTitleItemIndex {
            // setSelectedTitle(at: index, animated: true)
            _setSelectedTitle(at: index, in: _navigationTitleItems, animated: true)
            // Cancel the scheduled scrolling animation if exists.
            NSObject.cancelPreviousPerformRequests(withTarget: self,
                                                   selector  : #selector(_scrollToSelectedTitleItemWithAnimation),
                                                   object    : nil)
            // Set up the animated transition delegate:
            _delegatesQueue.remove(_interactiveTransition)
            _delegatesQueue.add(_animatedTransition)
            // Set to the selected offset.
            let offsetx = _horizontalOffset(upto: _selectedTitleItemIndex, in: _navigationTitleItems)
            _titleItemsScrollView.setContentOffset(CGPoint(x: offsetx, y: 0.0), animated: true)
        }
    }
    
    @objc
    private func _handleTitleActionItemDidTouchDown(_ sender: _TabNavigationTitleItemButton) {
        // Cancel the scheduled scrolling animation if exists.
        NSObject.cancelPreviousPerformRequests(withTarget: self,
                                               selector  : #selector(_scrollToSelectedTitleItemWithAnimation),
                                               object    : nil)
    }
    
    @objc
    private func _handleTitleItemsPreview(_ panGesture: UIPanGestureRecognizer) {
        var position: CGPoint = .zero
        
        switch panGesture.state {
        case .began: fallthrough
        case .possible:
            position = panGesture.location(in: _titleItemsContainerView)
            break
        case .changed:
            let _changedPosition = panGesture.location(in: _titleItemsContainerView)
            if _changedPosition.x - position.x >= 20 {
                // Begin preview animation.
                /*
                _titleItemsScrollView.delegate = _titleItemsScrollViewDelegate
                _titleItemsScrollView.setContentOffset(CGPoint(x: _horizontalOffset(upto: _navigationTitleItems.index(before: _selectedTitleItemIndex)), y: 0.0), animated: true)
                _titleItemsScrollView.isScrollEnabled = true
                panGesture.isEnabled = false */
            }
            break
        default: break
        }
    }
    @objc
    private func _handleNavigationBack(_ sender: UIButton) {
        delegate?.tabNavigationBarDidTouchNavigatiomBackItem?(self)
    }
    
    // MARK: - Private.
    private func _setupEffectView() {
        if _normalBackgroundColor == nil {
            _normalBackgroundColor = backgroundColor
            backgroundColor = .clear
        }
        _effectView.removeFromSuperview()
        _effectView = _createGenetalEffectView(style: translucentStyle)
        insertSubview(_effectView, at: 0)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[effectView]|", options: [], metrics: nil, views: ["effectView": _effectView]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[effectView]|", options: [], metrics: nil, views: ["effectView": _effectView]))
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    /// Constraint height of self to the safe area.
    private func _constraintHeight() {
        var heightc: NSLayoutConstraint
        if #available(iOS 11.0, *) {
            heightc = heightAnchor.constraint(equalTo: topAnchor.anchorWithOffset(to: safeAreaLayoutGuide.topAnchor), multiplier: 1.0, constant: height)
        } else {
            heightc = heightAnchor.constraint(equalToConstant: height)
        }
        heightc.isActive = true
        _heightConstraint = heightc
    }
    /// Constraint container views of the title(navigation) items.
    private func _constraintContainerViews() {
        _navigationBackItem.underlyingView.isHidden = true
        // Add the container view.
        addSubview(_containerView)
        let heightConstraint = _containerView.heightAnchor.constraint(equalToConstant: height)
        heightConstraint.isActive = true
        _heightConstraintOfContainerView = heightConstraint
        if #available(iOS 11.0, *) {
            _containerView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor).isActive = true
            _containerView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor).isActive = true
            _containerView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor).isActive = true
        } else {
            _containerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            _containerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            _containerView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        }
        _containerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        _containerView.addSubview(_navigationBackItem.underlyingView)
        _navigationBackItem.underlyingView.centerYAnchor.constraint(equalTo: _containerView.centerYAnchor).isActive = true
        let _horizontal = _navigationBackItem.underlyingView.trailingAnchor.constraint(equalTo: _containerView.leadingAnchor)
        _horizontal.isActive = true
        _horizontalConstraintOfBackItem = _horizontal
        _constraintContainerViewOfTitleItems(_titleItemsContainerView)
        _constraintContainerViewOfNavigationItems(_itemsContainerView)
    }
    /// Constraint container view for the title items view.
    private func _constraintContainerViewOfTitleItems(_ itemsContainerView: UIView) {
        _containerView.addSubview(itemsContainerView)
        
        _navigationBackItem.underlyingView.trailingAnchor.constraint(equalTo: itemsContainerView.leadingAnchor).isActive = true
        itemsContainerView.topAnchor.constraint(equalTo: _containerView.topAnchor).isActive = true
        itemsContainerView.bottomAnchor.constraint(equalTo: _containerView.bottomAnchor).isActive = true
    }
    /// Constraint container view for the navigation items view.
    private func _constraintContainerViewOfNavigationItems(_ itemsContainerView: UIView, transition: Bool = false) {
        _containerView.addSubview(itemsContainerView)
        
        let constraint = _titleItemsContainerView.trailingAnchor.constraint(equalTo : itemsContainerView.leadingAnchor,
                                                                            constant: -_TabNavigationConfig.default.itemEdgeMargin)
        if transition {
            if let c = _constraintBetweenTitlesAndItems { _containerView.removeConstraint(c) }
            _constraintBetweenTransitionTitlesAndItems = constraint
        } else {
            _constraintBetweenTitlesAndItems = constraint
        }
        constraint.isActive = true
        
        itemsContainerView.trailingAnchor.constraint(equalTo: _containerView.trailingAnchor).isActive = true
        itemsContainerView.topAnchor.constraint(equalTo     : _containerView.topAnchor).isActive      = true
        itemsContainerView.bottomAnchor.constraint(equalTo  : _containerView.bottomAnchor).isActive   = true
        itemsContainerView.widthAnchor.constraint(lessThanOrEqualTo: _containerView.widthAnchor,
                                                  multiplier       : 0.5,
                                                  constant         : 0.0).isActive = true
    }
    
    private func _setupPreviewGesture() {
        _titleItemsPreviewPanGesture = UIPanGestureRecognizer(target: self, action: #selector(_handleTitleItemsPreview(_:)))
        _titleItemsContainerView.addGestureRecognizer(_titleItemsPreviewPanGesture)
    }
    /// Constraint views of title items.
    private func _constraintViewsOfTitleItems(_ itemsScrollView: UIScrollView? = nil, itemsView: UIView? = nil, fixSpacing: UILayoutGuide? = nil, transition: Bool = false) {
        let titleItemsScrollView    =   itemsScrollView ?? _titleItemsScrollView
        let navigationTitleItemView =   itemsView       ?? _navigationTitleItemView
        let titleAlignmentLabel     = __titleAlignmentLabel
        let fixSpacingLayoutGuide   =   fixSpacing      ?? _titleItemFixSpacingLayoutGuide
        
        _titleItemsContainerView.addSubview(titleItemsScrollView)
        titleItemsScrollView.delegate = _delegatesQueue
        titleItemsScrollView.addSubview(navigationTitleItemView)
        
        titleItemsScrollView.leadingAnchor.constraint(equalTo : _titleItemsContainerView.leadingAnchor).isActive  = true
        titleItemsScrollView.trailingAnchor.constraint(equalTo: _titleItemsContainerView.trailingAnchor).isActive = true
        titleItemsScrollView.topAnchor.constraint(equalTo     : _titleItemsContainerView.topAnchor).isActive      = true
        titleItemsScrollView.bottomAnchor.constraint(equalTo  : _titleItemsContainerView.bottomAnchor).isActive   = true
        titleItemsScrollView.widthAnchor.constraint(equalTo   : _titleItemsContainerView.widthAnchor).isActive    = true
        titleItemsScrollView.heightAnchor.constraint(equalTo  : _titleItemsContainerView.heightAnchor).isActive   = true
        
        navigationTitleItemView.leadingAnchor.constraint(equalTo : titleItemsScrollView.leadingAnchor).isActive   = true
        navigationTitleItemView.trailingAnchor.constraint(equalTo: titleItemsScrollView.trailingAnchor).isActive  = true
        navigationTitleItemView.topAnchor.constraint(equalTo     : titleItemsScrollView.topAnchor).isActive       = true
        navigationTitleItemView.bottomAnchor.constraint(equalTo  : titleItemsScrollView.bottomAnchor).isActive    = true
        
        _titleItemsContainerView.heightAnchor.constraint(equalTo: navigationTitleItemView.heightAnchor).isActive = true
        _titleItemsContainerView.addSubview(titleAlignmentLabel)
        _titleItemsContainerView.leadingAnchor.constraint(equalTo: titleAlignmentLabel.leadingAnchor).isActive = true
        _titleItemsContainerView.centerYAnchor.constraint(equalTo: titleAlignmentLabel.centerYAnchor).isActive = true
        
        navigationTitleItemView.addLayoutGuide(fixSpacingLayoutGuide)
        fixSpacingLayoutGuide.trailingAnchor.constraint(equalTo: navigationTitleItemView.trailingAnchor).isActive = true
        fixSpacingLayoutGuide.heightAnchor.constraint(equalTo  : navigationTitleItemView.heightAnchor).isActive   = true
        fixSpacingLayoutGuide.topAnchor.constraint(equalTo     : navigationTitleItemView.topAnchor).isActive      = true
        fixSpacingLayoutGuide.bottomAnchor.constraint(equalTo  : navigationTitleItemView.bottomAnchor).isActive   = true
        fixSpacingLayoutGuide.widthAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive                    = true
        
        let leading = navigationTitleItemView.leadingAnchor.constraint(equalTo: fixSpacingLayoutGuide.leadingAnchor)
        leading.isActive = true
        if transition { _trailingConstraintOfLastTransitionTitleItemLabel = leading } else {
            _trailingConstraintOfLastTitleItemLabel = leading
        }
        
        let width = fixSpacingLayoutGuide.widthAnchor.constraint(equalTo: titleItemsScrollView.widthAnchor, constant: 0)
        width.isActive = true
        if transition { _widthOfTransitionTitleItemContentAlignmentView = width } else {
            _widthOfTitleItemContentAlignmentView = width
        }
    }
    
    internal func _toggleShowingOfNavigationBackItem(shows: Bool, duration: TimeInterval = 0.5, animated: Bool) {
        if let _horizontal = _horizontalConstraintOfBackItem {
            _containerView.removeConstraint(_horizontal)
        }
        var _horizontal: NSLayoutConstraint
        if shows {
            _horizontal = _navigationBackItem.underlyingView.leadingAnchor.constraint(equalTo: _containerView.leadingAnchor)
        } else {
            _horizontal = _navigationBackItem.underlyingView.trailingAnchor.constraint(equalTo: _containerView.leadingAnchor)
        }
        _horizontal.isActive = true
        _horizontalConstraintOfBackItem = _horizontal
        
        if shows {
            _navigationBackItem.underlyingView.isHidden = false
        }
        if animated {
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [], animations: { [unowned self] in
                self.layoutIfNeeded()
                }, completion: { [unowned self] finished in
                if finished && !shows {
                    self._navigationBackItem.underlyingView.isHidden = true
                    self._navigationBackItem.underlyingView.transform = .identity
                }
            })
        }
    }
    /// Constraint views of navigation items.
    private func _constraintViewsOfNavigationItems(containerView: UIView? = nil, scrollView: UIScrollView? = nil, itemView: UIView? = nil, transition: Bool = false) {
        let itemsContainerView = containerView ?? _itemsContainerView
        let itemsScrollView    = scrollView    ?? _itemsScrollView
        let navigationItemView = itemView      ?? _navigationItemView
        
        itemsContainerView.addSubview(itemsScrollView)
        itemsScrollView.addSubview(navigationItemView)
        
        itemsScrollView.leadingAnchor.constraint(equalTo : itemsContainerView.leadingAnchor).isActive  = true
        itemsScrollView.trailingAnchor.constraint(equalTo: itemsContainerView.trailingAnchor).isActive = true
        itemsScrollView.topAnchor.constraint(equalTo     : itemsContainerView.topAnchor).isActive      = true
        itemsScrollView.bottomAnchor.constraint(equalTo  : itemsContainerView.bottomAnchor).isActive   = true
        itemsScrollView.widthAnchor.constraint(equalTo   : itemsContainerView.widthAnchor).isActive    = true
        itemsScrollView.heightAnchor.constraint(equalTo  : itemsContainerView.heightAnchor).isActive   = true
        
        navigationItemView.leadingAnchor.constraint(equalTo : itemsScrollView.leadingAnchor).isActive  = true
        navigationItemView.trailingAnchor.constraint(equalTo: itemsScrollView.trailingAnchor).isActive = true
        navigationItemView.topAnchor.constraint(equalTo     : itemsScrollView.topAnchor).isActive      = true
        navigationItemView.bottomAnchor.constraint(equalTo  : itemsScrollView.bottomAnchor).isActive   = true
        
        navigationItemView.heightAnchor.constraint(equalTo : itemsContainerView.heightAnchor).isActive = true
        
        let widthz = navigationItemView.widthAnchor.constraint(equalToConstant: 0.0)
        widthz.isActive = true
        if transition { _widthOfTransitionNavigationItemViewForZeroContent = widthz } else {
            _widthOfNavigationItemViewForZeroContent = widthz
        }
        
        let widthc = itemsContainerView.widthAnchor.constraint(equalTo: navigationItemView.widthAnchor)
        widthc.priority = UILayoutPriorityDefaultHigh
        widthc.isActive = true
    }
    
    private func _setupDelegates() {
        _interactiveTransition.tabNavigationBar = self
        _animatedTransition.tabNavigationBar    = self
        _interactiveTransition.didUpdateSelectedIndex = { [weak self] selectedIndex in
            self?._selectedTitleItemIndex = selectedIndex
        }
        _animatedTransition.animationDidFinished      = { [weak self] scrollView    in
            // When the animation transition finished, remove the animation transition and add the interactive:
            self?._delegatesQueue.remove(self?._animatedTransition)
            self?._delegatesQueue.add(self?._interactiveTransition)
            if let sself = self {
                sself.delegate?.tabNavigationBar?(sself, didSelectTitleItemAt: sself._selectedTitleItemIndex)
            }
        }
        _didEndScrollingAnimation = _ScrollViewDidEndScrollingAnimation({ [weak self] scrollView in
            self?._delegatesQueue.remove(self?._didEndScrollingAnimation)
            self?._delegatesQueue.add(self?._interactiveTransition)
        })
        _delegatesQueue.add(self)
        _delegatesQueue.add(_interactiveTransition)
    }
    
    fileprivate func _addNavigationItemView(_ item: TabNavigationItem,`in` items: [TabNavigationItem]? = nil, to itemsView: UIView? = nil, transition: Bool = false) {
        let navigationItems = items ?? _navigationItems
        let navigationItemView = itemsView ?? _navigationItemView
        
        let itemView = item.underlyingView
        itemView.translatesAutoresizingMaskIntoConstraints = false

        if let width = _widthOfNavigationItemViewForZeroContent(transition) {
            navigationItemView.removeConstraint(width)
        }
        
        itemView.removeFromSuperview()
        navigationItemView.addSubview(itemView)
        
        item.underlyingButton.lastBaselineAnchor.constraint(equalTo: __titleAlignmentLabel.lastBaselineAnchor).isActive = true
        itemView.trailingAnchor.constraint(equalTo
            :  navigationItems.last?.underlyingView.leadingAnchor
            ?? navigationItemView.trailingAnchor, constant: !navigationItems.isEmpty
                ? 0.0
                : -DefaultTabNavigationItemEdgeMargin).isActive
        = true
        itemView.topAnchor.constraint(greaterThanOrEqualTo: navigationItemView.topAnchor).isActive    = true
        itemView.bottomAnchor.constraint(lessThanOrEqualTo: navigationItemView.bottomAnchor).isActive = true
        // itemView.topAnchor.constraint(equalTo: navigationItemView.topAnchor).isActive = true
        // itemView.bottomAnchor.constraint(equalTo: navigationItemView.bottomAnchor).isActive = true
        
        if let leading = _leadingConstraintOfLastItemView(transition) {
            navigationItemView.removeConstraint(leading)
        }
        
        let leading = itemView.leadingAnchor.constraint(equalTo: navigationItemView.leadingAnchor)
            leading.isActive = true
        if  transition { _leadingConstraintOfLastTransitionItemView = leading } else {
            _leadingConstraintOfLastItemView = leading
        }
    }
    
    fileprivate func _createAndSetupNavigationItemViews() -> TabNavigationItemViews {
        let itemsContailerView = _createGeneralContainerView()
        let itemsScrollView    = _createGeneralScrollView(alwaysBounceHorizontal: false)
        let navigationItemView = _createGeneralContainerView()
        
        _constraintContainerViewOfNavigationItems(itemsContailerView, transition: true)
        _constraintViewsOfNavigationItems(containerView: itemsContailerView, scrollView: itemsScrollView, itemView: navigationItemView, transition: true)
        
        return (itemsContailerView, itemsScrollView, navigationItemView)
    }
    
    fileprivate func _setNavigationItems(_ items: [TabNavigationItem], animated: Bool = false) {
        guard animated else {
            while !_navigationItems.isEmpty {
                removeLastNavigationItem()
            }
            navigationItems = items
            return
        }
        
        // Get the container views.
        let navigationItemViews = _createAndSetupNavigationItemViews()
        
        // Add item to the navigatiom item view.
        var _transitionItems: [TabNavigationItem] = []
        for item in items {
            _addNavigationItemView(item, in: _transitionItems, to: navigationItemViews.itemsView, transition: true)
            _transitionItems.append(item)
        }
        
        navigationItemViews.itemsView.alpha = 0.0
        // Animate the trainsition:
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [], animations: { [unowned self] in
            self._navigationItemView.alpha = 0.0
            navigationItemViews.itemsView.alpha = 1.0
        }) { [unowned self] finished in
            if finished {
                self._commitTransitionNavigationItemViews(navigationItemViews, navigationItems: items)
            }
        }
    }
    
    fileprivate func _commitTransitionNavigationItemViews(_ navigationItemViews: TabNavigationItemViews, navigationItems: [TabNavigationItem]) {
        guard navigationItemViews.itemsContainerView !== _itemsContainerView else { return }
        
        navigationItemViews.itemsView.alpha = 1.0
        
        _itemsContainerView.removeFromSuperview()
        
        _leadingConstraintOfLastItemView = _leadingConstraintOfLastTransitionItemView
        _widthOfNavigationItemViewForZeroContent = _widthOfTransitionNavigationItemViewForZeroContent
        _constraintBetweenTitlesAndItems = _constraintBetweenTransitionTitlesAndItems
        
        _itemsContainerView = navigationItemViews.itemsContainerView
        _itemsScrollView = navigationItemViews.itemsScrollView
        _navigationItemView = navigationItemViews.itemsView
        
        _navigationItems = navigationItems
    }
    
    fileprivate func _addNavigationTitleItemButton(_ item: TabNavigationTitleItem, `in` items: [TabNavigationTitleItem]? = nil, possibleActions actions: [TabNavigationTitleActionItem]? = nil, to itemContainerView: UIView? = nil, fixSpacing: UILayoutGuide? = nil, transition: Bool = false) {
        let navigationTitleItems       =   items ?? _navigationTitleItems
        let navigationTitleActionItems =   actions ?? _navigationTitleActionItems
        let navigationTitleItemView    =   itemContainerView ?? _navigationTitleItemView
        let titleAlignmentLabel        = __titleAlignmentLabel
        let fixSpacingLayoutGudie      =   fixSpacing ?? _titleItemFixSpacingLayoutGuide
        
        let itemButton = item.underlyingButton
        if item is TabNavigationTitleActionItem {
            itemButton.addTarget(self, action: #selector(_handleTitleActionItemDidTouchDown(_:)), for: .touchDown)
        } else {
            itemButton.addTarget(self, action: #selector(_handleDidSelectTitleItem(_:)),          for: .touchUpInside)
        }
        itemButton.translatesAutoresizingMaskIntoConstraints = false
        
        itemButton.removeFromSuperview()
        navigationTitleItemView.addSubview(itemButton)
        
        itemButton.lastBaselineAnchor.constraint(equalTo: titleAlignmentLabel.lastBaselineAnchor).isActive = true
        if item is TabNavigationTitleActionItem {
            let _trailingAnchor = navigationTitleActionItems.last?.underlyingButton.trailingAnchor ?? (navigationTitleItems.last?.underlyingButton.trailingAnchor ?? navigationTitleItemView.leadingAnchor)
            let _trailing = itemButton.leadingAnchor.constraint(equalTo: _trailingAnchor, constant: DefaultTabNavigationTitleItemPadding)
            
            if navigationTitleActionItems.isEmpty {
                if let _trailingOfTitleItems = transition ? _trailingConstraintOfLastTransitionTitleItemLabel : _trailingConstraintOfLastTitleItemLabel {
                    navigationTitleItemView.removeConstraint(_trailingOfTitleItems)
                }
                _trailing.isActive = true
                if transition {
                    _trailingConstraintOfLastTransitionTitleItemLabel = _trailing
                } else {
                    _trailingConstraintOfLastTitleItemLabel = _trailing
                }
            } else {
                _trailing.isActive = true
            }
            
            if let _trailingOfTitleActionItems = transition ? _trailingConstraintOfLastTransitionTitleActionItemLabel : _trailingConstraintOfLastTitleActionItemLabel {
                navigationTitleItemView.removeConstraint(_trailingOfTitleActionItems)
            }
            
            let _trailingOfTitleActionItems = itemButton.trailingAnchor.constraint(equalTo: fixSpacingLayoutGudie.leadingAnchor, constant: -DefaultTabNavigationTitleItemPadding)
            _trailingOfTitleActionItems.isActive = true
            if transition {
                _trailingConstraintOfLastTransitionTitleActionItemLabel = _trailingOfTitleActionItems
            } else {
                _trailingConstraintOfLastTitleActionItemLabel = _trailingOfTitleActionItems
            }
        } else {
            let _trailingAnchor = navigationTitleItems.last?.underlyingButton.trailingAnchor ?? navigationTitleItemView.leadingAnchor
            itemButton.leadingAnchor.constraint(equalTo: _trailingAnchor, constant: DefaultTabNavigationTitleItemPadding).isActive = true
            
            if let _trailing = transition ? _trailingConstraintOfLastTransitionTitleItemLabel : _trailingConstraintOfLastTitleItemLabel {
                navigationTitleItemView.removeConstraint(_trailing)
            }
            
            let _trailing = NSLayoutConstraint(item: navigationTitleActionItems.first?.underlyingButton ?? fixSpacingLayoutGudie, attribute: .leading, relatedBy: .equal, toItem: itemButton, attribute: .trailing, multiplier: 1.0, constant: DefaultTabNavigationTitleItemPadding)
            navigationTitleItemView.addConstraint(_trailing)
            if transition {
                _trailingConstraintOfLastTransitionTitleItemLabel = _trailing
            } else {
                _trailingConstraintOfLastTitleItemLabel = _trailing
            }
        }
    }
    
    fileprivate func _createAndSetupTitleItemViews() -> TabNavigationTitleItemViews {
        let itemsScrollView = _createGeneralScrollView()
        let itemsView = _createGeneralContainerView()
        let fixSpacing = UILayoutGuide()
        
        _constraintViewsOfTitleItems(itemsScrollView, itemsView: itemsView, fixSpacing: fixSpacing, transition: true)
        
        return (itemsScrollView, itemsView, fixSpacing)
    }
    
    fileprivate func _setNavigationTitleItems(_ items: [TabNavigationTitleItem], animated: Bool = false, selectedIndex index: Array<TabNavigationTitleItem>.Index = 0, actionConfig: (ignore: Bool, actions: [TabNavigationTitleActionItem]?) = (false, nil), animation: ((TabNavigationTitleItemAnimationContext) -> Void)? = nil) {
        guard animated else {
            // Remove all the former title items.
            while _navigationTitleItems.last != nil {
                removeLastNavigaitonTitleItem()
            }
            // Set new items to the view.
            navigationTitleItems = items
            if !_navigationTitleItems.isEmpty {
                // setSelectedTitle(at: index, animated: animated)
                _setSelectedTitle(at: index, in: _navigationTitleItems, animated: true)
                // _scrollToSelectedTitleItem(animated: animated)
                // Set up the animated transition delegate:
                _delegatesQueue.remove(_interactiveTransition)
                _delegatesQueue.add(_animatedTransition)
                // Set to the selected offset.
                let _offsetX = _horizontalOffset(upto: _selectedTitleItemIndex, in: _navigationTitleItems)
                _titleItemsScrollView.setContentOffset(CGPoint(x: _offsetX, y: 0.0), animated: true)
            }
            return
        }
        
        // Create container views.
        let titleItemViews = _createAndSetupTitleItemViews()
        
        var navigationTitleActionItems: [TabNavigationTitleActionItem] = []
        if !actionConfig.ignore {
            if let actions = actionConfig.actions {
                navigationTitleActionItems = actions
            } else {
                // Make a deep copy of the navigation title action items.
                for item in _navigationTitleActionItems {
                    let _deepCpItem = TabNavigationTitleActionItem(title: item.underlyingButton.title(for: .normal)!)
                    _deepCpItem.setTitleFont(item.titleFont(whenSelected: false), whenSelected: false)
                    _deepCpItem.setTitleColor(item.titleColor(whenSelected: false), whenSelected: false)
                    if let action = item._action, let target = item._target {
                        _deepCpItem.underlyingButton.addTarget(target, action: action, for: .touchUpInside)
                    }
                    _deepCpItem.tintColor = item.tintColor
                    navigationTitleActionItems.append(_deepCpItem)
                }
            }
            
            // Add title action item first.
            var _transitionActionItems: [TabNavigationTitleActionItem] = []
            for item in navigationTitleActionItems {
                _addNavigationTitleItemButton(item, in: _transitionActionItems, possibleActions: _transitionActionItems, to: titleItemViews.itemsView, fixSpacing: titleItemViews.fixSpacing, transition: true)
                _transitionActionItems.append(item)
            }
        }
        // Add item to the navigatiom item view.
        var _transitionItems: [TabNavigationTitleItem] = []
        for item in items {
            _addNavigationTitleItemButton(item, in: _transitionItems, possibleActions: navigationTitleActionItems, to: titleItemViews.itemsView, fixSpacing: titleItemViews.fixSpacing, transition: true)
            _transitionItems.append(item)
        }
        
        _updateWidthConstantOfContentAlignmentView(in: items, possibleActions: navigationTitleActionItems, transition: true)
        
        setNeedsLayout()
        layoutIfNeeded()
        if !items.isEmpty {
            _setSelectedTitle(at: index, in: items, possibleActions: navigationTitleActionItems, animated: false)
            _scrollToSelectedTitleItem(items: items, in: titleItemViews.itemsScrollView, animated: false)
        }
        
        if let animationBlock = animation {
            let itemViews: TabNavigationTitleItemViews = (_titleItemsScrollView, _navigationTitleItemView, _titleItemFixSpacingLayoutGuide)
            let parameters = (_titleItemsContainerView, itemViews, titleItemViews)
            animationBlock(parameters)
        } else {
            titleItemViews.itemsView.alpha = 0.0
            // Animate the trainsition:
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [.curveEaseOut], animations: { [unowned self] in
                self._navigationTitleItemView.alpha = 0.0
                titleItemViews.itemsView.alpha = 1.0
            }) { [unowned self] finished in
                if finished {
                    self._commitTransitionTitleItemViews(titleItemViews, titleItems: items)
                }
            }
        }
    }
    
    fileprivate func _commitTransitionTitleItemViews(_ itemViews: TabNavigationTitleItemViews, titleItems: [TabNavigationTitleItem]) {
        guard itemViews.itemsScrollView !== _titleItemsScrollView else {
            return
        }
        
        itemViews.itemsView.alpha = 1.0
        
        _titleItemsScrollView.removeFromSuperview()
        
        _trailingConstraintOfLastTitleItemLabel = _trailingConstraintOfLastTransitionTitleItemLabel
        _widthOfTitleItemContentAlignmentView = _widthOfTransitionTitleItemContentAlignmentView
        _trailingConstraintOfLastTitleActionItemLabel = _trailingConstraintOfLastTransitionTitleActionItemLabel
        
        _titleItemsScrollView = itemViews.itemsScrollView
        _navigationTitleItemView = itemViews.itemsView
        _titleItemFixSpacingLayoutGuide = itemViews.fixSpacing
        
        _navigationTitleItems = titleItems
    }
    
    fileprivate func _removeNavitationItemView(at index: Array<TabNavigationItem>.Index) -> (Bool, TabNavigationItem?) {
        guard _earlyCheckingBounds(index, in: _navigationItems) else { return (false, nil) }
        
        let item = _navigationItems[index]
        item.underlyingView.removeFromSuperview()
        
        if _navigationItems.count == 1 {// Handle zero content.
            let width = _navigationItemView.widthAnchor.constraint(equalToConstant: 0.0)
            width.isActive = true
            _widthOfNavigationItemViewForZeroContent = width
        } else {
            let _formerTrailingAnchor = index == _navigationItems.index(before: _navigationItems.endIndex) ? _navigationItemView.leadingAnchor : _navigationItems[_navigationItems.index(after: index)].underlyingView.trailingAnchor
            let _latterLeadingAnchor = index == _navigationItems.startIndex ? _navigationItemView.trailingAnchor : _navigationItems[_navigationItems.index(before: index)].underlyingView.leadingAnchor
            
            let leading = _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor)
            if index == _navigationItems.startIndex {
                leading.constant = -DefaultTabNavigationItemEdgeMargin
            }
            leading.isActive = true
            if index == _navigationItems.index(before: _navigationItems.endIndex) {
                _leadingConstraintOfLastItemView = leading
            }
        }
        
        _navigationItems.remove(at: index)
        
        return (true, item)
    }
    
    fileprivate func _removeNavigationTitleItemButton(at index: Array<TabNavigationTitleItem>.Index) -> (Bool, TabNavigationTitleItem?) {
        guard _earlyCheckingBounds(index, in: _navigationTitleItems) else { return (false, nil) }
        
        let item = _navigationTitleItems[index]
        item.underlyingButton.removeFromSuperview()
        item.underlyingButton.removeTarget(self, action: #selector(_handleDidSelectTitleItem(_:)), for: .touchUpInside)
        
        let _formerTrailingAnchor = index == _navigationTitleItems.startIndex ? _navigationTitleItemView.leadingAnchor : _navigationTitleItems[_navigationTitleItems.index(before: index)].underlyingButton.trailingAnchor
        
        if index == _navigationTitleItems.index(before: _navigationTitleItems.endIndex) {
            if let _firstTitleActionItem = _navigationTitleActionItems.first {
                let _latterLeadingAnchor = _firstTitleActionItem.underlyingButton.leadingAnchor
                _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor, constant: -DefaultTabNavigationTitleItemPadding).isActive = true
            } else {
                let _latterLeadingAnchor = _titleItemFixSpacingLayoutGuide.leadingAnchor
                
                let trailing = _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor, constant: -DefaultTabNavigationTitleItemPadding)
                trailing.isActive = true
                _trailingConstraintOfLastTitleItemLabel = trailing
            }
        } else {
            let _latterLeadingAnchor = _navigationTitleItems[_navigationTitleItems.index(after: index)].underlyingButton.leadingAnchor
            _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor, constant: -DefaultTabNavigationTitleItemPadding).isActive = true
        }
        
        _navigationTitleItems.remove(at: index)
        
        if index == _selectedTitleItemIndex, !_navigationTitleItems.isEmpty {
            if _selectedTitleItemIndex >= _navigationTitleItems.endIndex {
                _selectedTitleItemIndex = _navigationTitleItems.index(before: _navigationTitleItems.endIndex)
            }
            setSelectedTitle(at: _selectedTitleItemIndex, animated: true)
        }
        
        _updateWidthConstantOfContentAlignmentView()
        _offsetPositionsUpToEndIndex = _horizontalOffsetsUptoEachIndexs()
        
        return (true, item)
    }
    
    fileprivate func _removeNavigationTitleActionItemButton(at index: Array<TabNavigationTitleActionItem>.Index) -> (Bool, TabNavigationTitleActionItem?) {
        guard _earlyCheckingBounds(index, in: _navigationTitleActionItems) else { return (false, nil) }
        
        let item = _navigationTitleActionItems[index]
        item.underlyingButton.removeFromSuperview()
        
        let _formerTrailingAnchor = index == _navigationTitleActionItems.startIndex ? (_navigationTitleItems.isEmpty ? _navigationTitleItemView.leadingAnchor : _navigationTitleItems.last!.underlyingButton.trailingAnchor) : _navigationTitleActionItems[_navigationTitleActionItems.index(before: index)].underlyingButton.trailingAnchor
        let _latterLeadingAnchor = index == _navigationTitleActionItems.index(before: _navigationTitleActionItems.endIndex) ? _titleItemFixSpacingLayoutGuide.leadingAnchor : _navigationTitleActionItems[_navigationTitleActionItems.index(after: index)].underlyingButton.leadingAnchor
        _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor, constant: -DefaultTabNavigationTitleItemPadding).isActive = true
        
        _navigationTitleActionItems.remove(at: index)
        _updateWidthConstantOfContentAlignmentView()
        
        return (true, item)
    }
    
    fileprivate func _setSelectedTitle(at index: Array<TabNavigationTitleItem>.Index, `in` items: [TabNavigationTitleItem], possibleActions: [TabNavigationTitleActionItem]? = nil, animated: Bool) {
        guard _earlyCheckingBounds(index, in: items) else { return }
        
        _selectedTitleItemIndex = index
        let navigationTitleActionItems = possibleActions ?? _navigationTitleActionItems
        
        navigationTitleActionItems.forEach({ $0.selected = false })
        delegate?.tabNavigationBar?(self, willSelectTitleItemAt: index, animated: animated)
        if !animated {
            items.enumerated().forEach({ [unowned self] (idx, item) in
                if idx == index {
                    self.delegate?.tabNavigationBar?(self, didSelectTitleItemAt: index)
                    item.selected = true
                } else {
                    item.selected = false
                }
            })
        }
    }
    
    @objc
    fileprivate func _scrollToSelectedTitleItem(items: [TabNavigationTitleItem]? = nil, `in` scrollView: UIScrollView? = nil, animated: Bool = true) {
        let offsetx = _horizontalOffset(upto: _selectedTitleItemIndex, in: items)
        let titleItemScrollView = scrollView ?? _titleItemsScrollView
        
        // guard titleItemScrollView.contentOffset.x != offsetx else { return }
        
        if animated && titleItemScrollView === _titleItemsScrollView {
            // Remove the interactive transition delegate and animated transition delegate.
            _delegatesQueue.remove(_interactiveTransition)
            _delegatesQueue.remove(_animatedTransition)
            // Add did end scrolling animation call back delegate.
            _delegatesQueue.add(_didEndScrollingAnimation)
        }
        
        if titleItemScrollView.contentOffset.x == offsetx {
            // Make sample offsets.
            titleItemScrollView.setContentOffset(CGPoint(x: offsetx - 1.0, y: 0.0), animated: false)
            // Move to the target content offset.
        };  titleItemScrollView.setContentOffset(CGPoint(x: offsetx, y: 0.0), animated: animated)
    }
    @objc
    fileprivate func _scrollToSelectedTitleItemWithAnimation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
        _scrollToSelectedTitleItem()
    }
    
    // MARK: Calculation.
    
    fileprivate func _updateWidthConstantOfContentAlignmentView(`in` titleItems: [TabNavigationTitleItem]? = nil, possibleActions actionItems: [TabNavigationTitleActionItem]? = nil, transition: Bool = false) {
        let items = titleItems  ?? _navigationTitleItems
        /*
        guard !items.isEmpty else {
            _widthOfTitleItemContentAlignmentView(transition)?.constant = 0.0; return
        } */
        
        // _widthOfTitleItemContentAlignmentView(transition)?.constant = -_horizontalSpace(for: items.last!)
        let actions = actionItems ?? _navigationTitleActionItems
        
        guard !items.isEmpty || !actions.isEmpty else {
            _widthOfTitleItemContentAlignmentView(transition)?.constant = 0.0; return
        }
        
        if items.isEmpty {
            _widthOfTitleItemContentAlignmentView(transition)?.constant = -_horizontalOffset(upto: actions.endIndex, in: actions)
        } else if actions.isEmpty {
            _widthOfTitleItemContentAlignmentView(transition)?.constant = -_horizontalSpace(for: items.last!)
        } else {
            _widthOfTitleItemContentAlignmentView(transition)?.constant = -_horizontalSpace(for: items.last!) - _horizontalOffset(upto: actions.endIndex, in: actions)
        }
    }
    
    fileprivate func _horizontalOffset(upto index: Int = 0, `in` titleItems: [TabNavigationTitleItem]? = nil) -> CGFloat {
        let    items = titleItems ?? _navigationTitleItems
        guard !items.isEmpty, index <= items.endIndex else { return 0.0 }
        var    positionx: CGFloat = 0.0
        
        for index in 0...index {
            guard index > items.startIndex else { continue }
            
            positionx += _TabNavigationConfig.default.titleItemPadding
            positionx += ceil(_boundingSize(for: items[items.index(before: index)]).width)
        }
        
        return positionx
    }
    
    fileprivate func _horizontalOffsetsUptoEachIndexs(in titleItems: [TabNavigationTitleItem]? = nil) -> [CGFloat] {
        let items = titleItems ?? _navigationTitleItems
        
        var positions: [CGFloat]         = []
        var accumulatedPosition: CGFloat = 0.0
        
        let calculate: (Int) -> Void = { [unowned self] _index in
            accumulatedPosition += _TabNavigationConfig.default.titleItemPadding
            accumulatedPosition += ceil(self._boundingSize(for: items[items.index(before: _index)]).width)
            positions.append(accumulatedPosition)
        }
        
        for (index, _) in items.enumerated() {
            // Handle start index.
            if index == items.startIndex { positions.append(0.0) } else {
                calculate(index)
            }
        }
        if !items.isEmpty { calculate(items.endIndex) }
        
        return positions
    }
    /// Calculate the horizontal space consists of width and left margin of the underlying button of the title item.
    fileprivate func _horizontalSpace(`for` lastItem: TabNavigationTitleItem, selected: Bool = true) -> CGFloat {
        return ceil(_boundingSize(for: lastItem, selected: selected).width) + _TabNavigationConfig.default.titleItemPadding
    }
    /// Calculate the bounding size for the TabNavigationTitleItem by bounding the underlying title of the button
    /// the button's bounds.
    func _boundingSize(`for` item: TabNavigationTitleItem, selected: Bool = false) -> CGSize {
        let size = { () -> CGSize in
            var s: CGSize = .zero
            // Using the attributed string to bounding size if the selected range is not nil and the title item is selected.
            if selected && item.selectedRange != nil && item.underlyingButton.currentAttributedTitle != nil {
                let range = item.selectedRange!
                let attributedString = NSMutableAttributedString(string: item.underlyingButton.currentAttributedTitle!.string, attributes: [NSFontAttributeName: item.titleFont(whenSelected: false)])
                attributedString.addAttributes([NSFontAttributeName: item.titleFont(whenSelected: true)], range: NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound))
                s = attributedString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bounds.height), options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).size
            } else {
                var titleString = item.underlyingButton.currentTitle
                if  item.selectedRange != nil {
                    titleString = item.underlyingButton.currentAttributedTitle?.string
                }
                s = (titleString as NSString?)?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bounds.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSFontAttributeName:item.titleFont(whenSelected: false)], context: nil).size ?? .zero
            }
            return s
        }()
        
        return size
    }
}

// MARK: Transition Supportings.

extension TabNavigationBar {
    /// Returns the width constrait of the title item content alignment view.
    fileprivate func _widthOfTitleItemContentAlignmentView(_ transition: Bool) -> NSLayoutConstraint? {
        return transition ? _widthOfTransitionTitleItemContentAlignmentView : _widthOfTitleItemContentAlignmentView
    }
    /// Returns the width constraint of the navigation item view for zero content.
    fileprivate func _widthOfNavigationItemViewForZeroContent(_ transition: Bool) -> NSLayoutConstraint? {
        return transition ? _widthOfTransitionNavigationItemViewForZeroContent : _widthOfNavigationItemViewForZeroContent
    }
    /// Returns the leading constraint of the last navigation item view.s
    fileprivate func _leadingConstraintOfLastItemView(_ transition: Bool) -> NSLayoutConstraint? {
        return transition ? _leadingConstraintOfLastTransitionItemView : _leadingConstraintOfLastItemView
    }
}

extension TabNavigationBar: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _offsetPositionsUpToEndIndex = _horizontalOffsetsUptoEachIndexs()
        // Schedule the scroll animation:
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
        self.perform(#selector(_scrollToSelectedTitleItemWithAnimation), with: nil, afterDelay: 2.0, inModes: [.commonModes])
    }
}

// MARK: - Layout support.

extension TabNavigationBar {
    public var firstBaseLineAnchor: NSLayoutYAxisAnchor { return __titleAlignmentLabel.firstBaselineAnchor }
    override public var lastBaselineAnchor: NSLayoutYAxisAnchor { return __titleAlignmentLabel.lastBaselineAnchor }
}

extension TabNavigationBar {
    // MARK: - Public Property.
    
    public var selectedIndex: Array<TabNavigationTitleItem>.Index { return _selectedTitleItemIndex }
    /// Get the selected title item of the tab-navigation bar.
    public var selectedTitleItem: TabNavigationTitleItem? {
        guard _earlyCheckingBounds(_selectedTitleItemIndex, in: _navigationTitleItems) else {
            return nil
        }
        return _navigationTitleItems[_selectedTitleItemIndex]
    }
    /// Get all the current navigation items of the tab-navigation bar.
    public var navigationBackItem: TabNavigationItem { return _navigationBackItem }
    
    public var navigationItems: [TabNavigationItem] {
        set(items) {
            for item in items {
                addNavigationItem(item)
            }
        }
        get { return _navigationItems }
    }
    
    public var navigationTitleItems: [TabNavigationTitleItem] {
        set(items) {
            for item in items {
                addNavigationTitleItem(item)
            }
        }
        get { return _navigationTitleItems }
    }
    
    public var navigationTitleActionItems: [TabNavigationTitleActionItem] {
        set(items) {
            for item in items {
                addNavigationTitleActionItem(item)
            }
        }
        
        get { return _navigationTitleActionItems }
    }
    
    // MARK: - Navigation Back Item
    
    public func showNavigationBackItem(_ animated: Bool) {
        _toggleShowingOfNavigationBackItem(shows: true, animated: animated)
    }
    
    public func hideNavigationBackItem(_ animated: Bool) {
        _toggleShowingOfNavigationBackItem(shows: false, animated: animated)
    }
    
    // MARK: - Add, Set, Remove Items.
    // MARK: Navigagtion Item
    
    public func addNavigationItem(_ item: TabNavigationItem) {
        _addNavigationItemView(item)
        
        _navigationItems.append(item)
    }
    
    public func setNavigationItems(_ items: [TabNavigationItem], animated: Bool = false) {
        _setNavigationItems(items, animated: animated)
    }
    @discardableResult
    public func removeNavigationItem(_ item: TabNavigationItem) -> (Bool, TabNavigationItem?) {
        guard let index = _navigationItems.index(of: item) else {
            return (false, nil)
        }
        
        return removeNavigationItem(at: index)
    }
    @discardableResult
    public func removeNavigationItem(at index: Array<TabNavigationItem>.Index) -> (Bool, TabNavigationItem?) {
        guard !_navigationItems.isEmpty else {
            return (false, nil)
        }
        
        return _removeNavitationItemView(at:index)
    }
    @discardableResult
    public func removeFirstNavigationItem() -> (Bool, TabNavigationItem?) {
        guard !_navigationItems.isEmpty else {
            return (false, nil)
        }
        
        return removeNavigationItem(at: _navigationItems.startIndex)
    }
    @discardableResult
    public func removeLastNavigationItem() -> (Bool, TabNavigationItem?) {
        guard !_navigationItems.isEmpty else {
            return (false, nil)
        }
        
        return removeNavigationItem(at: _navigationItems.index(before: _navigationItems.endIndex))
    }
    
    // MARK: Navigation Title Item
    
    public func addNavigationTitleItem(_ item: TabNavigationTitleItem) {
        _addNavigationTitleItemButton(item)
        
        if item is TabNavigationTitleActionItem {
            _navigationTitleActionItems.append(item as! TabNavigationTitleActionItem)
        } else {
            _navigationTitleItems.append(item)
        }
        
        _updateWidthConstantOfContentAlignmentView()
        _offsetPositionsUpToEndIndex = _horizontalOffsetsUptoEachIndexs()
    }
    
    public func setNavigationTitleItems(_ items: [TabNavigationTitleItem], animated: Bool = false, selectedIndex index: Array<TabNavigationTitleItem>.Index = 0, actionsConfig: (() -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?))? = nil, animation: ((TabNavigationTitleItemAnimationContext) -> Void)? = nil) {
        _setNavigationTitleItems(items, animated: animated, selectedIndex: index, actionConfig: actionsConfig?() ?? (false, nil), animation: animation)
    }
    @discardableResult
    public func removeNavigationTitleItem(_ item: TabNavigationTitleItem) -> (Bool, TabNavigationTitleItem?) {
        guard let index = _navigationTitleItems.index(of: item) else {
            return (false, nil)
        }
        
        return removeNavigaitonTitleItem(at: index)
    }
    @discardableResult
    public func removeNavigaitonTitleItem(at index: Array<TabNavigationTitleItem>.Index) -> (Bool, TabNavigationTitleItem?) {
        guard !_navigationTitleItems.isEmpty else {
            return (false, nil)
        }
        return _removeNavigationTitleItemButton(at: index)
    }
    @discardableResult
    public func removeFirstNavigaitonTitleItem() -> (Bool, TabNavigationTitleItem?) {
        guard !_navigationTitleItems.isEmpty else {
            return (false, nil)
        }
        return _removeNavigationTitleItemButton(at: _navigationTitleItems.startIndex)
    }
    @discardableResult
    public func removeLastNavigaitonTitleItem() -> (Bool, TabNavigationTitleItem?) {
        guard !_navigationTitleItems.isEmpty else {
            return (false, nil)
        }
        return _removeNavigationTitleItemButton(at: _navigationTitleItems.index(before: _navigationTitleItems.endIndex))
    }
    
    // MARK: NavigationTitle Action Item
    
    public func addNavigationTitleActionItem(_ item: TabNavigationTitleActionItem) {
        addNavigationTitleItem(item)
    }
    
    @discardableResult
    public func removeNavigationTitleActionItem(_ item: TabNavigationTitleActionItem) -> (Bool, TabNavigationTitleActionItem?) {
        guard let index = _navigationTitleActionItems.index(of: item) else {
            return (false, nil)
        }
        
        return removeNavigationTitleActionItem(at: index)
    }
    @discardableResult
    public func removeNavigationTitleActionItem(at index: Array<TabNavigationTitleActionItem>.Index) -> (Bool, TabNavigationTitleActionItem?) {
        guard !_navigationTitleActionItems.isEmpty else {
            return (false, nil)
        }
        return _removeNavigationTitleActionItemButton(at:index)
    }
    @discardableResult
    public func removeFirstNavigationTitleActionItem() -> (Bool, TabNavigationTitleActionItem?) {
        guard !_navigationTitleActionItems.isEmpty else {
            return (false, nil)
        }
        return _removeNavigationTitleActionItemButton(at: _navigationTitleActionItems.startIndex)
    }
    @discardableResult
    public func removeLastNavigationTitleActionItem() -> (Bool, TabNavigationTitleActionItem?) {
        guard !_navigationTitleActionItems.isEmpty else {
            return (false, nil)
        }
        return _removeNavigationTitleActionItemButton(at: _navigationTitleActionItems.index(before: _navigationTitleActionItems.endIndex))
    }
    // MARK: - Selecte Title Item.
    public func setSelectedTitle(at index: Array<TabNavigationTitleItem>.Index, animated: Bool) {
        _setSelectedTitle(at: index, in: _navigationTitleItems, animated: animated)
        _scrollToSelectedTitleItem(items: _navigationTitleItems, in: _titleItemsScrollView, animated: animated)
    }
    
    // MARK: - Tab transitions.
    
    public func beginTransitionNavigationTitleItems(_ items: [TabNavigationTitleItem], selectedIndex index: Array<TabNavigationTitleItem>.Index = 0, actionsConfig: (() -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?))? = nil, navigationItems: [TabNavigationItem]) -> TabNavigationTransitionContext {
        // Create views.
        let itemViews = _createAndSetupTitleItemViews()
        let _itemViews: TabNavigationTitleItemViews = (_titleItemsScrollView, _navigationTitleItemView, _titleItemFixSpacingLayoutGuide)
        let animationParameters = (_titleItemsContainerView, _itemViews, itemViews)
        
        var navigationTitleActionItems: [TabNavigationTitleActionItem] = []
        let actionResults = actionsConfig?() ?? (ignore: false, actions: nil)
        if !actionResults.ignore {
            if let actions = actionResults.actions {
                navigationTitleActionItems = actions
            } else {
                // Make a deep copy of the navigation title action items.
                for item in _navigationTitleActionItems {
                    let _deepCpItem = TabNavigationTitleActionItem(title: item.underlyingButton.title(for: .normal)!)
                    _deepCpItem.setTitleFont(item.titleFont(whenSelected: false), whenSelected: false)
                    _deepCpItem.setTitleColor(item.titleColor(whenSelected: false), whenSelected: false)
                    if let action = item._action, let target = item._target {
                        _deepCpItem.underlyingButton.addTarget(target, action: action, for: .touchUpInside)
                    }
                    _deepCpItem.tintColor = item.tintColor
                    navigationTitleActionItems.append(_deepCpItem)
                }
            }
            
            // Add title action item first.
            var _transitionActionItems: [TabNavigationTitleActionItem] = []
            for item in navigationTitleActionItems {
                _addNavigationTitleItemButton(item, in: _transitionActionItems, possibleActions: _transitionActionItems, to: itemViews.itemsView, fixSpacing: itemViews.fixSpacing, transition: true)
                _transitionActionItems.append(item)
            }
        }
        // Add title items.
        var transitionItems: [TabNavigationTitleItem] = []
        for item in items {
            _addNavigationTitleItemButton(item, in: transitionItems, possibleActions: navigationTitleActionItems, to: itemViews.itemsView, fixSpacing: itemViews.fixSpacing, transition: true)
            transitionItems.append(item)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
        
        if !items.isEmpty {
            _setSelectedTitle(at: index, in: items, possibleActions: [], animated: false)
            _scrollToSelectedTitleItem(items: items, in: itemViews.itemsScrollView, animated: false)
        }
        
        let fromNavigationItemViews = (_itemsContainerView, _itemsScrollView, _navigationItemView)
        let toNavigationItemViews = beginTransitionNavigationItems(navigationItems)
        
        return (_navigationBackItem as TabNavigationItem, animationParameters, (fromNavigationItemViews, toNavigationItemViews))
    }
    
    public func beginTransitionNavigationItems(_ items: [TabNavigationItem], on navigatiomItems: [TabNavigationItem] = [], `in` itemViews: TabNavigationItemViews? = nil) -> TabNavigationItemViews {
        if !navigatiomItems.isEmpty {
            _setNavigationItems(navigatiomItems, animated: false)
        }
        // Get the container views.
        let navigationItemViews = itemViews ?? _createAndSetupNavigationItemViews()
        navigationItemViews.itemsView.subviews.forEach{ $0.removeFromSuperview() }
        if _widthOfTransitionNavigationItemViewForZeroContent == nil {
            let width = navigationItemViews.itemsView.widthAnchor.constraint(equalToConstant: 0.0)
            width.isActive = true
            _widthOfTransitionNavigationItemViewForZeroContent = width
        }
        
        // Add item to the navigatiom item view.
        var _transitionItems: [TabNavigationItem] = []
        for item in items {
            _addNavigationItemView(item, in: _transitionItems, to: navigationItemViews.itemsView, transition: true)
            _transitionItems.append(item)
        }
        
        navigationItemViews.itemsView.alpha = 0.0
        
        return navigationItemViews
    }
    
    public func commitTransitionNavigatiomItemViews(_ itemViews: TabNavigationItemViews?, navigationItems: [TabNavigationItem], success: Bool = true) {
        guard let navigationItemViews = itemViews else { return }
        
        if success {
            _commitTransitionNavigationItemViews(navigationItemViews, navigationItems: navigationItems)
        } else {
            _navigationItemView.alpha = 1.0
            if let _constraint = _constraintBetweenTransitionTitlesAndItems  {
                removeConstraint(_constraint)
            }
            let _constraint = _titleItemsContainerView.trailingAnchor.constraint(equalTo: _itemsContainerView.leadingAnchor, constant: -DefaultTabNavigationItemEdgeMargin)
            _constraint.isActive = true
            _constraintBetweenTitlesAndItems = _constraint
            navigationItemViews.itemsContainerView.removeFromSuperview()
        }
    }
    
    public func commitTransitionTitleItemViews(_ itemViews: TabNavigationTitleItemViews, items titleItems: [TabNavigationTitleItem]) {
        _commitTransitionTitleItemViews(itemViews, titleItems: titleItems)
    }
    
    public func setNestedScrollViewContentOffset(_ contentOffset: CGPoint, contentSize: CGSize, bounds: CGRect, transition itemViews: TabNavigationItemViews? = nil, updatingNavigationItems: Bool = true) {
        let offsetPositions = _offsetPositionsUpToEndIndex
        
        let index = Int(contentOffset.x / bounds.width)
        let beginsOffsetPosition = offsetPositions[index]
        
        var transitionOffsetDelta: CGFloat = 0.0
        if index == offsetPositions.index(before: offsetPositions.endIndex) {
            transitionOffsetDelta = offsetPositions[index] - offsetPositions[offsetPositions.index(before: index)]
        } else if index == offsetPositions.startIndex {
            transitionOffsetDelta = offsetPositions[offsetPositions.index(after: index)]
        } else {
            transitionOffsetDelta = offsetPositions[offsetPositions.index(after: index)] - offsetPositions[index]
        }
        
        let signedPercent = contentOffset.x.truncatingRemainder(dividingBy: bounds.width) / bounds.width
        let offsetXDelta  = transitionOffsetDelta * signedPercent
        let offsetx       = beginsOffsetPosition + offsetXDelta
        
        _titleItemsScrollView.setContentOffset(CGPoint(x: offsetx, y: 0.0), animated: false)
        
        //FIXME: Ignoring the edge.
        if signedPercent == 0.0 || !updatingNavigationItems { return }// Begins from or ends to the edge of the screen, ignoring.
        itemViews?.itemsView.alpha = signedPercent
        _navigationItemView.alpha  = 1 - signedPercent
    }
}

// MARK: - Conforming `NSCoding`.
extension TabNavigationBar {
    public override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
    }
}
// MARK: - Conforming `UIBarPositioning`.
extension TabNavigationBar {
    public var barPosition: UIBarPosition { return .top }
}

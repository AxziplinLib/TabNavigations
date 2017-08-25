//
//  NavigationBar.swift
//  TabNavigations
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import pop

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

private class _TabNavigationItemButton: UIButton { /* Custom view hooks. */ }
private class _TabNavigationTitleItemButton: UIButton { // Custom view hooks.
    weak var _titleItem: TabNavigationTitleItem?
}

private class _TabNavigationBarScrollViewHooks: NSObject {
    fileprivate var _completion: (()->Void)
    
    init(_ completion: @escaping ()->Void) {
        _completion = completion
        super.init()
    }
}

private class _TabNavigationItemView: UIView {
    var title: String? {
        didSet {
            _button.setTitle(title, for: .normal)
        }
    }
    var image: UIImage? {
        didSet {
            _button.setImage(image, for: .normal)
        }
    }
    
    
    // Button item.
    lazy var _button: _TabNavigationItemButton = { () -> _TabNavigationItemButton in
        let button = _TabNavigationItemButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.clear
        button.titleLabel?.font = UIFont(name: "PingFangSC-Semibold", size: DefaultTabNavigationItemFontSize)
        return button
    }()
    
    // Initialzier:
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        _initializer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        _initializer()
    }
    
    private func _initializer() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        // Set up button.
        _setupButton()
    }
    
    // Private:
    private func _setupButton() {
        heightAnchor.constraint(equalToConstant: DefaultTabNavigationItemHeight).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: DefaultTabNavigationItemWidthThreshold).isActive = true
        
        addSubview(_button)
        addConstraint(NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: _button, attribute: .centerX, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: _button, attribute: .centerY, multiplier: 1.0, constant: 0.0))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(==6)-[_button]-(==6)-|", options: [], metrics: nil, views: ["_button":_button]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=0)-[_button]-(>=0)-|", options: [], metrics: nil, views: ["_button":_button]))
    }
}

public class TabNavigationItem: NSObject {
    // MARK: - Properties.
    public var image: UIImage? {
        return _view.image
    }
    
    public var title: String? {
        return _view.title
    }
    
    public var tintColor: UIColor? {
        set { _view._button.tintColor = newValue }
        get { return _view._button.tintColor }
    }
    
    public var target: Any? {
        return _view._button.allTargets.first
    }
    
    public var selector: Selector? {
        guard let _selector = _view._button.actions(forTarget: target, forControlEvent: .touchUpInside)?.first else {
            return nil
        }
        return Selector(_selector)
    }
    
    internal var underlyingView: UIView { return _view }
    fileprivate var _view: _TabNavigationItemView = _TabNavigationItemView()
    
    public init(title: String?) {
        super.init()
        _view.title = title
    }
    
    public convenience init(image: UIImage? = nil, target: Any? = nil, selector: Selector? = nil) {
        self.init(title: nil)
        _view.image = image
        if selector != nil {
            _view._button.addTarget(target, action: selector!, for: .touchUpInside)
        }
    }
    
    public convenience init(title: String? = nil, target: Any? = nil, selector: Selector? = nil) {
        self.init(title: title)
        _view.title = title
        if selector != nil {
            _view._button.addTarget(target, action: selector!, for: .touchUpInside)
        }
    }
}

private class _TabNavigationBackItem: TabNavigationItem { /* Back navigation item*/ }

public class TabNavigationTitleItem: NSObject {
    public var selected: Bool {
        didSet {
            setSelected(selected, animated: false)
        }
    }
    
    public var selectedRange: CountableRange<Int>? {
        didSet {
            if let _ = selectedRange {
                let attributedTitle = NSMutableAttributedString(string: _button.title(for: .normal)!, attributes: [NSFontAttributeName: titleFont(whenSelected: false), NSForegroundColorAttributeName: titleColor(whenSelected: false)])
                self._button.setAttributedTitle(attributedTitle, for: .normal)
            } else {
                self._button.setAttributedTitle(nil, for: .normal)
            }
        }
    }
    
    public var currentTitleColor: UIColor {
        return _selectionTitleColors[selected]!
    }
    
    public var currentTitleFont: UIFont {
        return _selectionTitleFonts[selected]!
    }
    
    private var _selectionTitleColors: [Bool: UIColor] = [true: UIColor(hex: "4A4A4A"), false: UIColor(hex: "CCCCCC")]
    private var _selectionTitleFonts: [Bool: UIFont] = [true: UIFont(name: "PingFangSC-Semibold", size: DefaultTitleFontSize)!, false: UIFont(name: "PingFangSC-Semibold", size: DefaultTitleUnselectedFontSize)!]
    
    public func setTitleColor(_ titleColor: UIColor, whenSelected selected: Bool) {
        _selectionTitleColors[selected] = titleColor
    }
    public func titleColor(whenSelected selected: Bool) -> UIColor {
        return _selectionTitleColors[selected]!
    }
    
    public func setTitleFont(_ titleFont: UIFont, whenSelected selected: Bool) {
        _selectionTitleFonts[selected] = titleFont
        if _selectionTitleFonts[true]!.fontName != _selectionTitleFonts[false]!.fontName {
            fatalError("Font for selected state and font for unselected state must have the same font family and name.")
        }
    }
    public func titleFont(whenSelected selected: Bool) -> UIFont {
        return _selectionTitleFonts[selected]!
    }
    
    public func setSelected(_ selected: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            if let range = selectedRange {
                let _ns_range = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)
                
                let _fontSizeAnimation = POPSpringAnimation()
                _fontSizeAnimation.property = POPAnimatableProperty.attributedButtonFontSize(named: _selectionTitleFonts[selected]!.fontName, range: _ns_range, state: .normal)
                _fontSizeAnimation.toValue = titleFont(whenSelected: selected).pointSize
                _fontSizeAnimation.removedOnCompletion = true
                self._button.pop_add(_fontSizeAnimation, forKey: "ATTRIBUTEDFONT")
                
                let _titleColorAnimation = POPSpringAnimation()
                _titleColorAnimation.property = POPAnimatableProperty.attributedButtonTextColor(for: _ns_range, state: .normal)
                _titleColorAnimation.toValue = _selectionTitleColors[selected]
                _titleColorAnimation.removedOnCompletion = true
                _titleColorAnimation.completionBlock = { animation, finished in
                    completion?()
                }
                self._button.pop_add(_titleColorAnimation, forKey: "ATTRIBUTEDCOLOR")
            } else {
                let _fontSizeAnimation = POPSpringAnimation()
                _fontSizeAnimation.property = POPAnimatableProperty.labelFontSize(named: _selectionTitleFonts[selected]!.fontName)
                _fontSizeAnimation.toValue = selected ? DefaultTitleFontSize : DefaultTitleUnselectedFontSize
                _fontSizeAnimation.removedOnCompletion = true
                self._button.titleLabel?.pop_add(_fontSizeAnimation, forKey: "FONT")
                
                let _titleColorAnimation = POPSpringAnimation()
                _titleColorAnimation.property = POPAnimatableProperty.buttonTitleColor(for: . normal)
                _titleColorAnimation.toValue = _selectionTitleColors[selected]
                _titleColorAnimation.removedOnCompletion = true
                self._button.pop_add(_titleColorAnimation, forKey: "COLOR")
                
                let _tintColorAnimation = POPSpringAnimation(propertyNamed: kPOPViewTintColor)
                _tintColorAnimation?.toValue = _selectionTitleColors[selected]
                _tintColorAnimation?.removedOnCompletion = true
                _tintColorAnimation?.completionBlock = { animation, finished in
                    completion?()
                }
                self._button.pop_add(_tintColorAnimation, forKey: "TINTCOLOR")
            }
        } else {
            if let range = selectedRange {
                let attributedTitle = NSMutableAttributedString(attributedString: self._button.attributedTitle(for: .normal)!)
                let _ns_range = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)
                attributedTitle.addAttributes([NSFontAttributeName: titleFont(whenSelected: selected), NSForegroundColorAttributeName: titleColor(whenSelected: selected)], range: _ns_range)
                self._button.setAttributedTitle(attributedTitle, for: .normal)
            } else {
                self._button.titleLabel?.font = _selectionTitleFonts[selected]
                self._button.tintColor = _selectionTitleColors[selected]
                self._button.setTitleColor(_selectionTitleColors[selected], for: .normal)
            }
        }
    }
    
    fileprivate lazy var _button: _TabNavigationTitleItemButton = { () -> _TabNavigationTitleItemButton in
        let button = _TabNavigationTitleItemButton(type: .custom)
        button.titleLabel?.numberOfLines = 1
        button.adjustsImageWhenHighlighted = false
        return button
    }()
    
    public init(title: String) {
        selected = false
        super.init()
        _button.setTitle(title, for: .normal)
        _button._titleItem = self
    }
    
    public convenience init(title: String, selectedRange: CountableRange<Int>? = nil) {
        self.init(title: title)
        self.selectedRange = selectedRange
        if let _ = selectedRange {
            let attributedTitle = NSMutableAttributedString(string: _button.title(for: .normal)!, attributes: [NSFontAttributeName: titleFont(whenSelected: false), NSForegroundColorAttributeName: titleColor(whenSelected: false)])
            self._button.setAttributedTitle(attributedTitle, for: .normal)
        } else {
            self._button.setAttributedTitle(nil, for: .normal)
        }
    }
}

public class TabNavigationTitleActionItem: TabNavigationTitleItem {
    public override func setSelected(_ selected: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        super.setSelected(false, animated: false, completion: completion)
    }
    
    public override func titleFont(whenSelected selected: Bool) -> UIFont {
        return super.titleFont(whenSelected: false)
    }
    
    public override func titleColor(whenSelected selected: Bool) -> UIColor {
        return super.titleColor(whenSelected: false)
    }
    
    fileprivate var _target: Any?
    fileprivate var _action: Selector?
    
    public var tintColor: UIColor? {
        didSet {
            _button.tintColor = tintColor
            if let tint = tintColor {
                setTitleColor(tint, whenSelected: false)
            }
        }
    }
    
    public override init(title: String) {
        super.init(title: title)
        _button = _TabNavigationTitleItemButton(type: .system)
        _button.setTitle(title, for: .normal)
        _button._titleItem = self
    }
    
    public convenience init(title: String, target: Any?, selector: Selector) {
        self.init(title: title)
        _target = target
        _action = selector
        
        _button.addTarget(target, action: selector, for: .touchUpInside)
    }
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
    label.font = font ?? UIFont(name: "PingFangSC-Semibold", size: DefaultTitleFontSize)
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
    public typealias TabNavigationTitleItemViews = (itemsScrollView: UIScrollView, itemsView: UIView, alignmentContentView: UIView)
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
    // MARK: - Private Properties.
    fileprivate var _normalBackgroundColor: UIColor?
    fileprivate lazy var __titleAlignmentLabel: UILabel = _createGeneralAlignmentLabel()
    fileprivate lazy var _titleItemsContainerView: UIView = _createGeneralContainerView()
    fileprivate lazy var _itemsContainerView: UIView = _createGeneralContainerView()
    fileprivate lazy var _titleItemsScrollView: UIScrollView = _createGeneralScrollView()
    fileprivate lazy var _itemsScrollView: UIScrollView = _createGeneralScrollView(alwaysBounceHorizontal: false)
    fileprivate lazy var _navigationTitleItemView: UIView = _createGeneralContainerView()
    fileprivate lazy var _navigationItemView: UIView = _createGeneralContainerView()
    fileprivate lazy var _effectView: UIVisualEffectView = _createGenetalEffectView()
    fileprivate var _offsetPositionsUpToEndIndex: [CGFloat] = []
    fileprivate let _positionQueue = DispatchQueue(label: "com.tabnavigationbar.position")
    
    private var _titleItemsPreviewPanGesture: UIPanGestureRecognizer!
    
    fileprivate var _navigationBackItem: _TabNavigationBackItem = _TabNavigationBackItem(image:#imageLiteral(resourceName: "back_indicator"))
    fileprivate var _navigationItems: [TabNavigationItem] = []
    fileprivate var _navigationTitleItems: [TabNavigationTitleItem] = [] { didSet { _offsetPositionsUpToEndIndex = _calculatedPositionsUptoTitleItemAtEndIndex() } }
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
    
    fileprivate var _titleItemsScrollViewDelegate: _TabNavigationBarScrollViewHooks!
    
    private weak var _horizontalConstraintOfBackItem: NSLayoutConstraint?
    private weak var _leadingConstraintOfLastItemView: NSLayoutConstraint?
    private weak var _leadingConstraintOfLastTransitionItemView: NSLayoutConstraint?
    private weak var _trailingConstraintOfLastTitleItemLabel: NSLayoutConstraint?
    private weak var _trailingConstraintOfLastTransitionTitleItemLabel: NSLayoutConstraint?
    private weak var _trailingConstraintOfLastTitleActionItemLabel: NSLayoutConstraint?
    private weak var _trailingConstraintOfLastTransitionTitleActionItemLabel: NSLayoutConstraint?
    private weak var _widthOfNavigationItemViewForZeroContent: NSLayoutConstraint?
    fileprivate weak var _widthOfTransitionNavigationItemViewForZeroContent: NSLayoutConstraint?
    fileprivate weak var _constraintBetweenTitleContainerAndItemsContainer: NSLayoutConstraint?
    fileprivate weak var _constraintBetweenTransitionTitleContainerAndItemsContainer: NSLayoutConstraint?
    
    fileprivate lazy var _titleItemContentAlignmentView: _TabNavigaitonTitleContentAlignmentView = _createGeneralContainerView()
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
        // Set up container views:
        _setupContainerViews()
        _setupPreviewGesture()
        
        _setupTitleItemsScrollView()
        _setupNavigationItemView()
        
        _titleItemsScrollViewDelegate = _TabNavigationBarScrollViewHooks({ [unowned self] in
            self._titleItemsScrollView.delegate = self
        })
        _navigationBackItem._view._button.addTarget(self, action: #selector(_handleNavigationBack(_:)), for: .touchUpInside)
    }
    
    // MARK: - Actions.
    @objc
    private func _handleDidSelectTitleItem(_ sender: _TabNavigationTitleItemButton) {
        guard let _titleItem = sender._titleItem else {
            return
        }
        
        if let index = _navigationTitleItems.index(of: _titleItem), index != _selectedTitleItemIndex {
            setSelectedTitle(at: index, animated: true)
            
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
            
            _scrollToSelectedTitleItem()
        }
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
                _titleItemsScrollView.setContentOffset(CGPoint(x: _calculatedPositionUptoTitleItem(at: _navigationTitleItems.index(before: _selectedTitleItemIndex)), y: 0.0), animated: true)
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
    
    private func _setupContainerViews() {
        _navigationBackItem._view.isHidden = true
        addSubview(_navigationBackItem._view)
        _navigationBackItem._view.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        let _horizontal = _navigationBackItem._view.trailingAnchor.constraint(equalTo: leadingAnchor)
        _horizontal.isActive = true
        _horizontalConstraintOfBackItem = _horizontal
        _setupTitleItemsContainerView(_titleItemsContainerView)
        _setupNavigationItemsContainerView(_itemsContainerView)
    }
    
    private func _setupTitleItemsContainerView(_ itemsContainerView: UIView) {
        addSubview(itemsContainerView)
        
        _navigationBackItem._view.trailingAnchor.constraint(equalTo: itemsContainerView.leadingAnchor).isActive = true
        self.topAnchor.constraint(equalTo: itemsContainerView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: itemsContainerView.bottomAnchor).isActive = true
    }
    
    private func _setupNavigationItemsContainerView(_ itemsContainerView: UIView, transition: Bool = false) {
        addSubview(itemsContainerView)
        
        let _constraint = _titleItemsContainerView.trailingAnchor.constraint(equalTo: itemsContainerView.leadingAnchor, constant: -DefaultTabNavigationItemEdgeMargin)
        _constraint.isActive = true
        if transition {
            if let constraint = _constraintBetweenTitleContainerAndItemsContainer {
                removeConstraint(constraint)
            }
            _constraintBetweenTransitionTitleContainerAndItemsContainer = _constraint
        } else {
            _constraintBetweenTitleContainerAndItemsContainer = _constraint
        }
        
        self.trailingAnchor.constraint(equalTo: itemsContainerView.trailingAnchor).isActive = true
        self.topAnchor.constraint(equalTo: itemsContainerView.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: itemsContainerView.bottomAnchor).isActive = true
        itemsContainerView.widthAnchor.constraint(lessThanOrEqualTo: self.widthAnchor, multiplier: 0.5, constant: 0.0).isActive = true
    }
    
    private func _setupPreviewGesture() {
        _titleItemsPreviewPanGesture = UIPanGestureRecognizer(target: self, action: #selector(_handleTitleItemsPreview(_:)))
        _titleItemsContainerView.addGestureRecognizer(_titleItemsPreviewPanGesture)
    }
    
    private func _setupTitleItemsScrollView(_ itemsScrollView: UIScrollView? = nil, itemsView: UIView? = nil, alignmentContentView: _TabNavigaitonTitleContentAlignmentView? = nil, transition: Bool = false) {
        let titleItemsScrollView = itemsScrollView ?? _titleItemsScrollView
        let navigationTitleItemView = itemsView ?? _navigationTitleItemView
        let titleAlignmentLabel = __titleAlignmentLabel
        let titleItemContentAlignmentView = alignmentContentView ?? _titleItemContentAlignmentView
        
        titleItemsScrollView.delegate = self
        _titleItemsContainerView.addSubview(titleItemsScrollView)
        titleItemsScrollView.addSubview(navigationTitleItemView)
        
        _titleItemsContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[titleItemsScrollView]|", options: [], metrics: nil, views: ["titleItemsScrollView":titleItemsScrollView]))
        _titleItemsContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleItemsScrollView]|", options: [], metrics: nil, views: ["titleItemsScrollView":titleItemsScrollView]))
        titleItemsScrollView.widthAnchor.constraint(equalTo: _titleItemsContainerView.widthAnchor).isActive = true
        titleItemsScrollView.heightAnchor.constraint(equalTo: _titleItemsContainerView.heightAnchor).isActive = true
        
        titleItemsScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[navigationTitleItemView]|", options: [], metrics: nil, views: ["navigationTitleItemView":navigationTitleItemView]))
        titleItemsScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[navigationTitleItemView]|", options: [], metrics: nil, views: ["navigationTitleItemView":navigationTitleItemView]))
        
        _titleItemsContainerView.heightAnchor.constraint(equalTo: navigationTitleItemView.heightAnchor).isActive = true
        
        _titleItemsContainerView.addSubview(titleAlignmentLabel)
        _titleItemsContainerView.leadingAnchor.constraint(equalTo: titleAlignmentLabel.leadingAnchor).isActive = true
        _titleItemsContainerView.centerYAnchor.constraint(equalTo: titleAlignmentLabel.centerYAnchor).isActive = true
        
        navigationTitleItemView.addSubview(titleItemContentAlignmentView)
        navigationTitleItemView.trailingAnchor.constraint(equalTo: titleItemContentAlignmentView.trailingAnchor).isActive = true
        titleItemContentAlignmentView.heightAnchor.constraint(equalTo: navigationTitleItemView.heightAnchor).isActive = true
        titleItemContentAlignmentView.topAnchor.constraint(equalTo: navigationTitleItemView.topAnchor).isActive = true
        titleItemContentAlignmentView.bottomAnchor.constraint(equalTo: navigationTitleItemView.bottomAnchor).isActive = true
        titleItemContentAlignmentView.widthAnchor.constraint(greaterThanOrEqualToConstant: 0).isActive = true
        
        let _leading = navigationTitleItemView.leadingAnchor.constraint(equalTo: titleItemContentAlignmentView.leadingAnchor)
        _leading.isActive = true
        if transition {
            _trailingConstraintOfLastTransitionTitleItemLabel = _leading
        } else {
            _trailingConstraintOfLastTitleItemLabel = _leading
        }
        
        let _width = titleItemContentAlignmentView.widthAnchor.constraint(equalTo: titleItemsScrollView.widthAnchor, constant: 0)
        _width.isActive = true
        if transition {
            _widthOfTransitionTitleItemContentAlignmentView = _width
        } else {
            _widthOfTitleItemContentAlignmentView = _width
        }
    }
    
    internal func _toggleShowingOfNavigationBackItem(shows: Bool, duration: TimeInterval = 0.5, animated: Bool) {
        if let _horizontal = _horizontalConstraintOfBackItem {
            removeConstraint(_horizontal)
        }
        var _horizontal: NSLayoutConstraint
        if shows {
            _horizontal = _navigationBackItem._view.leadingAnchor.constraint(equalTo: leadingAnchor)
        } else {
            _horizontal = _navigationBackItem._view.trailingAnchor.constraint(equalTo: leadingAnchor)
        }
        _horizontal.isActive = true
        _horizontalConstraintOfBackItem = _horizontal
        
        if shows {
            _navigationBackItem._view.isHidden = false
        }
        if animated {
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [], animations: { [unowned self] in
                self.layoutIfNeeded()
                }, completion: { [unowned self] finished in
                if finished && !shows {
                    self._navigationBackItem._view.isHidden = true
                    self._navigationBackItem._view.transform = .identity
                }
            })
        }
    }
    
    private func _setupNavigationItemView(containerView: UIView? = nil, scrollView: UIScrollView? = nil, itemView: UIView? = nil, transition: Bool = false) {
        let itemsContainerView = containerView ?? _itemsContainerView
        let itemsScrollView = scrollView ?? _itemsScrollView
        let navigationItemView = itemView ?? _navigationItemView
        
        itemsContainerView.addSubview(itemsScrollView)
        itemsScrollView.addSubview(navigationItemView)
        
        itemsContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[itemsScrollView]|", options: [], metrics: nil, views: ["itemsScrollView":itemsScrollView]))
        itemsContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[itemsScrollView]|", options: [], metrics: nil, views: ["itemsScrollView":itemsScrollView]))
        itemsScrollView.widthAnchor.constraint(equalTo: itemsContainerView.widthAnchor).isActive = true
        itemsScrollView.heightAnchor.constraint(equalTo: itemsContainerView.heightAnchor).isActive = true
        
        itemsScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[navigationItemView]|", options: [], metrics: nil, views: ["navigationItemView":navigationItemView]))
        itemsScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[navigationItemView]|", options: [], metrics: nil, views: ["navigationItemView":navigationItemView]))
        
        let width = navigationItemView.widthAnchor.constraint(equalToConstant: 0.0)
        width.isActive = true
        if transition {
            _widthOfTransitionNavigationItemViewForZeroContent = width
        } else {
            _widthOfNavigationItemViewForZeroContent = width
        }
        
        let widthOfContainer = itemsContainerView.widthAnchor.constraint(equalTo: navigationItemView.widthAnchor)
        widthOfContainer.priority = UILayoutPriorityDefaultHigh
        widthOfContainer.isActive = true
        navigationItemView.heightAnchor.constraint(equalTo: itemsContainerView.heightAnchor).isActive = true
    }
    
    fileprivate func _addNavigationItemView(_ item: TabNavigationItem,`in` items: [TabNavigationItem]? = nil, to itemContainerView: UIView? = nil, transition: Bool = false) {
        let navigationItems = items ?? _navigationItems
        let navigationItemView = itemContainerView ?? _navigationItemView
        
        let _itemView = item._view
        _itemView.translatesAutoresizingMaskIntoConstraints = false

        if let _width = transition ? _widthOfTransitionNavigationItemViewForZeroContent : _widthOfNavigationItemViewForZeroContent {
            navigationItemView.removeConstraint(_width)
        }
        
        _itemView.removeFromSuperview()
        navigationItemView.addSubview(_itemView)
        
        _itemView._button.lastBaselineAnchor.constraint(equalTo: __titleAlignmentLabel.lastBaselineAnchor).isActive = true
        
        _itemView.trailingAnchor.constraint(equalTo: navigationItems.last?._view.leadingAnchor ?? navigationItemView.trailingAnchor, constant: !navigationItems.isEmpty ? 0.0 : -DefaultTabNavigationItemEdgeMargin).isActive = true
        
        if let _leading = transition ? _leadingConstraintOfLastTransitionItemView : _leadingConstraintOfLastItemView {
            navigationItemView.removeConstraint(_leading)
        }
        
        let _leading = _itemView.leadingAnchor.constraint(equalTo: navigationItemView.leadingAnchor)
        _leading.isActive = true
        if transition {
            _leadingConstraintOfLastTransitionItemView = _leading
        } else {
            _leadingConstraintOfLastItemView = _leading
        }
    }
    
    fileprivate func _createAndSetupNavigationItemViews() -> TabNavigationItemViews {
        let itemsContailerView = _createGeneralContainerView()
        let itemsScrollView = _createGeneralScrollView(alwaysBounceHorizontal: false)
        let navigationItemView = _createGeneralContainerView()
        
        _setupNavigationItemsContainerView(itemsContailerView, transition: true)
        _setupNavigationItemView(containerView: itemsContailerView, scrollView: itemsScrollView, itemView: navigationItemView, transition: true)
        
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
        guard navigationItemViews.itemsContainerView !== _itemsContainerView else {
            return
        }
        
        navigationItemViews.itemsView.alpha = 1.0
        
        _itemsContainerView.removeFromSuperview()
        
        _leadingConstraintOfLastItemView = _leadingConstraintOfLastTransitionItemView
        _widthOfNavigationItemViewForZeroContent = _widthOfTransitionNavigationItemViewForZeroContent
        _constraintBetweenTitleContainerAndItemsContainer = _constraintBetweenTransitionTitleContainerAndItemsContainer
        
        _itemsContainerView = navigationItemViews.itemsContainerView
        _itemsScrollView = navigationItemViews.itemsScrollView
        _navigationItemView = navigationItemViews.itemsView
        
        _navigationItems = navigationItems
    }
    
    fileprivate func _addNavigationTitleItemButton(_ item: TabNavigationTitleItem, `in` items: [TabNavigationTitleItem]? = nil, possibleActions actions: [TabNavigationTitleActionItem]? = nil, to itemContainerView: UIView? = nil, alignmentContentView: _TabNavigaitonTitleContentAlignmentView? = nil, transition: Bool = false) {
        let navigationTitleItems = items ?? _navigationTitleItems
        let navigationTitleActionItems = actions ?? _navigationTitleActionItems
        let navigationTitleItemView = itemContainerView ?? _navigationTitleItemView
        let titleAlignmentLabel = __titleAlignmentLabel
        let titleItemContentAlignmentView = alignmentContentView ?? _titleItemContentAlignmentView
        
        let _itemButton = item._button
        if !(item is TabNavigationTitleActionItem) {
            _itemButton.addTarget(self, action: #selector(_handleDidSelectTitleItem(_:)), for: .touchUpInside)
        }
        _itemButton.translatesAutoresizingMaskIntoConstraints = false
        
        _itemButton.removeFromSuperview()
        navigationTitleItemView.addSubview(_itemButton)
        
        _itemButton.lastBaselineAnchor.constraint(equalTo: titleAlignmentLabel.lastBaselineAnchor).isActive = true
        if item is TabNavigationTitleActionItem {
            let _trailingAnchor = navigationTitleActionItems.last?._button.trailingAnchor ?? (navigationTitleItems.last?._button.trailingAnchor ?? navigationTitleItemView.leadingAnchor)
            let _trailing = _itemButton.leadingAnchor.constraint(equalTo: _trailingAnchor, constant: DefaultTabNavigationTitleItemPadding)
            
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
            
            let _trailingOfTitleActionItems = _itemButton.trailingAnchor.constraint(equalTo: titleItemContentAlignmentView.leadingAnchor, constant: -DefaultTabNavigationTitleItemPadding)
            _trailingOfTitleActionItems.isActive = true
            if transition {
                _trailingConstraintOfLastTransitionTitleActionItemLabel = _trailingOfTitleActionItems
            } else {
                _trailingConstraintOfLastTitleActionItemLabel = _trailingOfTitleActionItems
            }
        } else {
            let _trailingAnchor = navigationTitleItems.last?._button.trailingAnchor ?? navigationTitleItemView.leadingAnchor
            _itemButton.leadingAnchor.constraint(equalTo: _trailingAnchor, constant: DefaultTabNavigationTitleItemPadding).isActive = true
            
            if let _trailing = transition ? _trailingConstraintOfLastTransitionTitleItemLabel : _trailingConstraintOfLastTitleItemLabel {
                navigationTitleItemView.removeConstraint(_trailing)
            }
            
            let _trailing = NSLayoutConstraint(item: navigationTitleActionItems.first?._button ?? titleItemContentAlignmentView, attribute: .leading, relatedBy: .equal, toItem: _itemButton, attribute: .trailing, multiplier: 1.0, constant: DefaultTabNavigationTitleItemPadding)
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
        let alignmentContentView: _TabNavigaitonTitleContentAlignmentView = _createGeneralContainerView()
        
        _setupTitleItemsScrollView(itemsScrollView, itemsView: itemsView, alignmentContentView: alignmentContentView, transition: true)
        
        return (itemsScrollView, itemsView, alignmentContentView)
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
                setSelectedTitle(at: index, animated: animated)
                _scrollToSelectedTitleItem(animated: animated)
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
                    let _deepCpItem = TabNavigationTitleActionItem(title: item._button.title(for: .normal)!)
                    _deepCpItem.setTitleFont(item.titleFont(whenSelected: false), whenSelected: false)
                    _deepCpItem.setTitleColor(item.titleColor(whenSelected: false), whenSelected: false)
                    if let action = item._action, let target = item._target {
                        _deepCpItem._button.addTarget(target, action: action, for: .touchUpInside)
                    }
                    _deepCpItem.tintColor = item.tintColor
                    navigationTitleActionItems.append(_deepCpItem)
                }
            }
            
            // Add title action item first.
            var _transitionActionItems: [TabNavigationTitleActionItem] = []
            for item in navigationTitleActionItems {
                _addNavigationTitleItemButton(item, in: _transitionActionItems, possibleActions: _transitionActionItems, to: titleItemViews.itemsView, alignmentContentView: (titleItemViews.alignmentContentView as! TabNavigationBar._TabNavigaitonTitleContentAlignmentView), transition: true)
                _transitionActionItems.append(item)
            }
        }
        // Add item to the navigatiom item view.
        var _transitionItems: [TabNavigationTitleItem] = []
        for item in items {
            _addNavigationTitleItemButton(item, in: _transitionItems, possibleActions: navigationTitleActionItems, to: titleItemViews.itemsView, alignmentContentView: (titleItemViews.alignmentContentView as! TabNavigationBar._TabNavigaitonTitleContentAlignmentView), transition: true)
            _transitionItems.append(item)
        }
        
        _calculateWidthConstantOfContentAlignmentView(in: items, possibleActions: navigationTitleActionItems, transition: true)
        
        setNeedsLayout()
        layoutIfNeeded()
        if !items.isEmpty {
            _setSelectedTitle(at: index, in: items, possibleActions: navigationTitleActionItems, animated: false)
            _scrollToSelectedTitleItem(items: items, in: titleItemViews.itemsScrollView, animated: false)
        }
        
        if let animationBlock = animation {
            let itemViews: TabNavigationTitleItemViews = (_titleItemsScrollView, _navigationTitleItemView, _titleItemContentAlignmentView as UIView)
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
        _titleItemContentAlignmentView = itemViews.alignmentContentView as! _TabNavigaitonTitleContentAlignmentView
        
        _navigationTitleItems = titleItems
    }
    
    fileprivate func _removeNavitationItemView(at index: Array<TabNavigationItem>.Index) -> (Bool, TabNavigationItem?) {
        guard _earlyCheckingBounds(index, in: _navigationItems) else { return (false, nil) }
        
        let item = _navigationItems[index]
        item._view.removeFromSuperview()
        
        if _navigationItems.count == 1 {// Handle zero content.
            let width = _navigationItemView.widthAnchor.constraint(equalToConstant: 0.0)
            width.isActive = true
            _widthOfNavigationItemViewForZeroContent = width
        } else {
            let _formerTrailingAnchor = index == _navigationItems.index(before: _navigationItems.endIndex) ? _navigationItemView.leadingAnchor : _navigationItems[_navigationItems.index(after: index)]._view.trailingAnchor
            let _latterLeadingAnchor = index == _navigationItems.startIndex ? _navigationItemView.trailingAnchor : _navigationItems[_navigationItems.index(before: index)]._view.leadingAnchor
            
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
        item._button.removeFromSuperview()
        item._button.removeTarget(self, action: #selector(_handleDidSelectTitleItem(_:)), for: .touchUpInside)
        
        let _formerTrailingAnchor = index == _navigationTitleItems.startIndex ? _navigationTitleItemView.leadingAnchor : _navigationTitleItems[_navigationTitleItems.index(before: index)]._button.trailingAnchor
        
        if index == _navigationTitleItems.index(before: _navigationTitleItems.endIndex) {
            if let _firstTitleActionItem = _navigationTitleActionItems.first {
                let _latterLeadingAnchor = _firstTitleActionItem._button.leadingAnchor
                _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor, constant: -DefaultTabNavigationTitleItemPadding).isActive = true
            } else {
                let _latterLeadingAnchor = _titleItemContentAlignmentView.leadingAnchor
                
                let trailing = _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor, constant: -DefaultTabNavigationTitleItemPadding)
                trailing.isActive = true
                _trailingConstraintOfLastTitleItemLabel = trailing
            }
        } else {
            let _latterLeadingAnchor = _navigationTitleItems[_navigationTitleItems.index(after: index)]._button.leadingAnchor
            _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor, constant: -DefaultTabNavigationTitleItemPadding).isActive = true
        }
        
        _navigationTitleItems.remove(at: index)
        
        if index == _selectedTitleItemIndex, !_navigationTitleItems.isEmpty {
            if _selectedTitleItemIndex >= _navigationTitleItems.endIndex {
                _selectedTitleItemIndex = _navigationTitleItems.index(before: _navigationTitleItems.endIndex)
            }
            setSelectedTitle(at: _selectedTitleItemIndex, animated: true)
        }
        
        _calculateWidthConstantOfContentAlignmentView()
        _offsetPositionsUpToEndIndex = _calculatedPositionsUptoTitleItemAtEndIndex()
        
        return (true, item)
    }
    
    fileprivate func _removeNavigationTitleActionItemButton(at index: Array<TabNavigationTitleActionItem>.Index) -> (Bool, TabNavigationTitleActionItem?) {
        guard _earlyCheckingBounds(index, in: _navigationTitleActionItems) else { return (false, nil) }
        
        let item = _navigationTitleActionItems[index]
        item._button.removeFromSuperview()
        
        let _formerTrailingAnchor = index == _navigationTitleActionItems.startIndex ? (_navigationTitleItems.isEmpty ? _navigationTitleItemView.leadingAnchor : _navigationTitleItems.last!._button.trailingAnchor) : _navigationTitleActionItems[_navigationTitleActionItems.index(before: index)]._button.trailingAnchor
        let _latterLeadingAnchor = index == _navigationTitleActionItems.index(before: _navigationTitleActionItems.endIndex) ? _titleItemContentAlignmentView.leadingAnchor : _navigationTitleActionItems[_navigationTitleActionItems.index(after: index)]._button.leadingAnchor
        _formerTrailingAnchor.constraint(equalTo: _latterLeadingAnchor, constant: -DefaultTabNavigationTitleItemPadding).isActive = true
        
        _navigationTitleActionItems.remove(at: index)
        _calculateWidthConstantOfContentAlignmentView()
        
        return (true, item)
    }
    
    fileprivate func _setSelectedTitle(at index: Array<TabNavigationTitleItem>.Index, `in` items: [TabNavigationTitleItem], possibleActions: [TabNavigationTitleActionItem]? = nil, animated: Bool) {
        guard _earlyCheckingBounds(index, in: items) else { return }
        
        _selectedTitleItemIndex = index
        let navigationTitleActionItems = possibleActions ?? _navigationTitleActionItems
        
        for item in navigationTitleActionItems {
            item.setSelected(false, animated: false)
        }
        for (idx, item) in items.enumerated() {
            if idx == index {
                delegate?.tabNavigationBar?(self, willSelectTitleItemAt: index, animated: animated)
                item.setSelected(true, animated: animated) { [unowned self] in
                    self.delegate?.tabNavigationBar?(self, didSelectTitleItemAt: index)
                }
            } else {
                item.setSelected(false, animated: animated)
            }
        }
    }
    
    @objc
    fileprivate func _scrollToSelectedTitleItem(items: [TabNavigationTitleItem]? = nil, `in` scrollView: UIScrollView? = nil, animated: Bool = true) {
        let _offsetX = _calculatedPositionUptoTitleItem(at: _selectedTitleItemIndex, in: items)
        let titleItemScrollView = scrollView ?? _titleItemsScrollView
        
        guard titleItemScrollView.contentOffset.x != _offsetX else {
            return
        }
        
        if animated && titleItemScrollView === _titleItemsScrollView {
            _titleItemsScrollView.delegate = _titleItemsScrollViewDelegate
        }
        
        titleItemScrollView.setContentOffset(CGPoint(x: _offsetX, y: 0.0), animated: animated)
    }
    @objc
    fileprivate func _scrollToSelectedTitleItemWithAnimation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
        _scrollToSelectedTitleItem()
    }
    
    fileprivate func _calculateWidthConstantOfContentAlignmentView(`in` items: [TabNavigationTitleItem]? = nil, possibleActions actions: [TabNavigationTitleActionItem]? = nil, transition: Bool = false) {
        let navigationTitleItems = items ?? _navigationTitleItems
        let navigationTitleActionItems = actions ?? _navigationTitleActionItems
        
        if navigationTitleActionItems.isEmpty && navigationTitleItems.isEmpty {
            if transition {
                _widthOfTransitionTitleItemContentAlignmentView?.constant = 0.0
            } else {
                _widthOfTitleItemContentAlignmentView?.constant = 0.0
            }
        } else {
            if navigationTitleItems.isEmpty {
                if transition {
                    _widthOfTransitionTitleItemContentAlignmentView?.constant = -_calculatedPositionsUptoTitleItemAtEndIndex(in: navigationTitleActionItems).last!
                } else {
                    _widthOfTitleItemContentAlignmentView?.constant = -_calculatedPositionsUptoTitleItemAtEndIndex(in: navigationTitleActionItems).last!
                }
            } else if navigationTitleActionItems.isEmpty {
                if transition {
                    _widthOfTransitionTitleItemContentAlignmentView?.constant = -_calculatedPositionWidthOfTitleItem(navigationTitleItems.last!)
                } else {
                    _widthOfTitleItemContentAlignmentView?.constant = -_calculatedPositionWidthOfTitleItem(navigationTitleItems.last!)
                }
            } else {
                if transition {
                    _widthOfTransitionTitleItemContentAlignmentView?.constant = -_calculatedPositionWidthOfTitleItem(navigationTitleItems.last!) - _calculatedPositionsUptoTitleItemAtEndIndex(in: navigationTitleActionItems).last!
                } else {
                    _widthOfTitleItemContentAlignmentView?.constant = -_calculatedPositionWidthOfTitleItem(navigationTitleItems.last!) - _calculatedPositionsUptoTitleItemAtEndIndex(in: navigationTitleActionItems).last!
                }
            }
        }
    }
    
    fileprivate func _calculatedPositionUptoTitleItem(at index: Int = 0, `in` items: [TabNavigationTitleItem]? = nil) -> CGFloat {
        let navigationTitleItems = items ?? _navigationTitleItems
        
        guard !navigationTitleItems.isEmpty, index < navigationTitleItems.endIndex else {
            return 0.0
        }
        
        var _positionX: CGFloat = 0.0
        
        for index in 0...index {
            if index > navigationTitleItems.startIndex {
                _positionX += DefaultTabNavigationTitleItemPadding
                let _titleItem = navigationTitleItems[navigationTitleItems.index(before: index)]
                
                var titleString = _titleItem._button.currentTitle
                if let _ = _titleItem.selectedRange {
                    titleString = _titleItem._button.currentAttributedTitle?.string
                }
                
                let size = (titleString as NSString?)?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bounds.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSFontAttributeName:_titleItem.titleFont(whenSelected: false)], context: nil).size
                _positionX += CGFloat(Double(size!.width))
            }
        }
        
        return _positionX
    }
    
    fileprivate func _calculatedPositionsUptoTitleItemAtEndIndex(in titleItems: [TabNavigationTitleItem]? = nil) -> [CGFloat] {
        let items = titleItems ?? _navigationTitleItems
        
        var positions: [CGFloat] = []
        var accumulatedPosition: CGFloat = 0.0
        
        let calculation: (Int) -> Void = { _index in
            accumulatedPosition += DefaultTabNavigationTitleItemPadding
            let _formerItem = items[items.index(before: _index)]
            
            var titleString = _formerItem._button.currentTitle
            if let _ = _formerItem.selectedRange {
                titleString = _formerItem._button.currentAttributedTitle?.string
            }
            
            let sizeOfTitleItem = (titleString as NSString?)?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bounds.height), options: [.usesLineFragmentOrigin], attributes: [NSFontAttributeName:_formerItem.titleFont(whenSelected: false) as Any], context: nil).size
            accumulatedPosition += sizeOfTitleItem!.width
            
            positions.append(accumulatedPosition)
        }
        
        for (index, _) in items.enumerated() {
            // Handle start index.
            if index == items.startIndex {
                positions.append(0.0)
            } else {
                calculation(index)
            }
        }
        if !items.isEmpty {
            calculation(items.endIndex)
        }
        
        return positions
    }
    
    fileprivate func _calculatedPositionWidthOfTitleItem(_ lastItem: TabNavigationTitleItem) -> CGFloat {
        var accumulatedPosition: CGFloat = DefaultTabNavigationTitleItemPadding
        
        if let _ = lastItem.selectedRange, let attributedString = lastItem._button.currentAttributedTitle {
            let sizeOfTitleItem = attributedString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bounds.height), options: [.usesLineFragmentOrigin], context: nil).size
            accumulatedPosition += sizeOfTitleItem.width
        } else {
            let titleString = lastItem._button.currentTitle
            let sizeOfTitleItem = (titleString as NSString?)?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bounds.height), options: [.usesLineFragmentOrigin], attributes: [NSFontAttributeName:lastItem.titleFont(whenSelected: true) as Any], context: nil).size
            accumulatedPosition += sizeOfTitleItem!.width
        }
        
        return accumulatedPosition
    }
}

extension UIColor {
    fileprivate typealias ColorComponents = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    fileprivate var components: ColorComponents {
        get {
            var _red: CGFloat = 0.0
            var _green: CGFloat = 0.0
            var _blue: CGFloat = 0.0
            var _alpha: CGFloat = 0.0
            getRed(&_red, green: &_green, blue: &_blue, alpha: &_alpha)
            return (_red, _green, _blue, _alpha)
        }
    }
    
    fileprivate class func diff(from fromComponents: ColorComponents, to components: ColorComponents) -> ColorComponents {
        let _components = fromComponents
        return (_components.red - components.red, _components.green - components.green, _components.blue - components.blue, _components.alpha - components.alpha)
    }
}

extension TabNavigationBar: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        _offsetPositionsUpToEndIndex = _calculatedPositionsUptoTitleItemAtEndIndex()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard !scrollView.isDragging, !scrollView.isTracking, !scrollView.isDecelerating else {
            return
        }
        
        let _offsetX = scrollView.contentOffset.x
        
        _positionQueue.async { autoreleasepool { [weak self] in
            guard let wself = self else { return }
            for (_index, _titleItem) in wself._navigationTitleItems.enumerated() {
                let _offsetPosition = wself._offsetPositionsUpToEndIndex[_index]
                
                let _comingTitleItem = _titleItem
                let _fontSizeDelta = _comingTitleItem.titleFont(whenSelected: true).pointSize - _comingTitleItem.titleFont(whenSelected: false).pointSize
                
                let _unselectedColorComponents = _comingTitleItem.titleColor(whenSelected: false).components
                let _selectedColorComponents = _comingTitleItem.titleColor(whenSelected: true).components
                
                let _selectedDiffToUnselectedColorComponents = UIColor.diff(from: _selectedColorComponents, to: _unselectedColorComponents)
                
                if _offsetPosition >= _offsetX { // Will Reach the threshold.
                    if _index > wself._navigationTitleItems.startIndex {
                        let _formerOffsetPosition = wself._offsetPositionsUpToEndIndex[wself._navigationTitleItems.index(before: _index)]
                        let _offsetPositionDelta = _offsetPosition - _formerOffsetPosition
                        
                        if _offsetPosition - _offsetX <= _offsetPositionDelta {
                            let _relativeOffsetX = _offsetX - _formerOffsetPosition
                            
                            let _transitionPercent = _relativeOffsetX / _offsetPositionDelta
                            let _relativeOfFontSize = _fontSizeDelta * _transitionPercent
                            
                            let _red = _unselectedColorComponents.red + _selectedDiffToUnselectedColorComponents.red * _transitionPercent
                            let _green = _unselectedColorComponents.green + _selectedDiffToUnselectedColorComponents.green * _transitionPercent
                            let _blue = _unselectedColorComponents.blue + _selectedDiffToUnselectedColorComponents.blue * _transitionPercent
                            let _alpha = _unselectedColorComponents.alpha + _selectedDiffToUnselectedColorComponents.alpha * _transitionPercent
                            
                            let _color = UIColor(red: _red, green: _green, blue: _blue, alpha: _alpha)
                            let _fontName = _comingTitleItem.titleFont(whenSelected: true).fontName
                            
                            if let range = _titleItem.selectedRange {
                                let _ns_range = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)
                                
                                let attributedTitle = NSMutableAttributedString(attributedString: _comingTitleItem._button.attributedTitle(for: .normal)!)
                                attributedTitle.addAttributes([NSFontAttributeName: UIFont(name: _fontName, size: _comingTitleItem.titleFont(whenSelected: false).pointSize + CGFloat(_relativeOfFontSize))!], range: _ns_range)
                                attributedTitle.addAttributes([NSForegroundColorAttributeName: _color], range: _ns_range)
                                
                                DispatchQueue.main.async {
                                    _comingTitleItem._button.setAttributedTitle(attributedTitle, for: .normal)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    _comingTitleItem._button.titleLabel?.font = UIFont(name: _fontName, size: _comingTitleItem.titleFont(whenSelected: false).pointSize + CGFloat(_relativeOfFontSize))
                                    _comingTitleItem._button.setTitleColor(_color, for: .normal)
                                    _comingTitleItem._button.tintColor = _color
                                }
                            }
                            
                            if _transitionPercent > 0.5 {
                                wself._selectedTitleItemIndex = _index
                            } else {
                                wself._selectedTitleItemIndex = wself._navigationTitleItems.index(before: _index)
                            }
                        } else {
                            DispatchQueue.main.async {
                                _titleItem.setSelected(false, animated: false)
                            }
                        }
                    }
                } else { // Will move from the threshold.
                    if _index < wself._navigationTitleItems.index(before: wself._navigationTitleItems.endIndex) {
                        let _latterOffsetPosition = wself._offsetPositionsUpToEndIndex[wself._navigationTitleItems.index(after: _index)]
                        
                        let _offsetPositionDelta = _latterOffsetPosition - _offsetPosition
                        
                        if _offsetX - _offsetPosition <= _offsetPositionDelta {
                            let _relativeOffsetX = _offsetX - _offsetPosition
                            
                            let _transitionPercent = _relativeOffsetX / _offsetPositionDelta
                            let _relativeOfFontSize = _fontSizeDelta * _transitionPercent
                            
                            let _red = _selectedColorComponents.red - _selectedDiffToUnselectedColorComponents.red * _transitionPercent
                            let _green = _selectedColorComponents.green - _selectedDiffToUnselectedColorComponents.green * _transitionPercent
                            let _blue = _selectedColorComponents.blue - _selectedDiffToUnselectedColorComponents.blue * _transitionPercent
                            let _alpha = _selectedColorComponents.alpha - _selectedDiffToUnselectedColorComponents.alpha * _transitionPercent
                            
                            let _color = UIColor(red: _red, green: _green, blue: _blue, alpha: _alpha)
                            let _fontName = _comingTitleItem.titleFont(whenSelected: false).fontName
                            
                            if let range = _titleItem.selectedRange {
                                let _ns_range = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)
                                
                                let attributedTitle = NSMutableAttributedString(attributedString: _comingTitleItem._button.attributedTitle(for: .normal)!)
                                attributedTitle.addAttributes([NSFontAttributeName: UIFont(name: _fontName, size: _comingTitleItem.titleFont(whenSelected: true).pointSize - CGFloat(_relativeOfFontSize))!], range: _ns_range)
                                attributedTitle.addAttributes([NSForegroundColorAttributeName: _color], range: _ns_range)
                                
                                DispatchQueue.main.async {
                                    _comingTitleItem._button.setAttributedTitle(attributedTitle, for: .normal)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    _comingTitleItem._button.titleLabel?.font = UIFont(name: _fontName, size: _comingTitleItem.titleFont(whenSelected: true).pointSize - CGFloat(_relativeOfFontSize))
                                    _comingTitleItem._button.setTitleColor(_color, for: .normal)
                                    _comingTitleItem._button.tintColor = _color
                                }
                            }
                            
                            if _transitionPercent > 0.5 {
                                wself._selectedTitleItemIndex = wself._navigationTitleItems.index(after: _index)
                            } else {
                                wself._selectedTitleItemIndex = _index
                            }
                        } else {
                            DispatchQueue.main.async {
                                _titleItem.setSelected(false, animated: false)
                            }
                        }
                    }
                }
            }
        }}
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
        self.perform(#selector(_scrollToSelectedTitleItemWithAnimation), with: nil, afterDelay: 2.0, inModes: [.commonModes])
    }
}

extension _TabNavigationBarScrollViewHooks: UIScrollViewDelegate {
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        _completion()
    }
}

extension TabNavigationBar {
    /// Checking the index in the bounds.
    /// - Parameter index: The current index to be checked.
    /// - Parameter array: The upper and lower bound of the index in a array.
    /// - Returns: True if index is in the bounds. Otherwise, false.
    fileprivate func _earlyCheckingIndex<T>(_ index: Array<T>.Index, `in` array: Array<T>) -> Bool {
        if index >= array.startIndex && index < array.endIndex {
            return true
        }
        return false
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
        guard _earlyCheckingIndex(_selectedTitleItemIndex, in: _navigationTitleItems) else {
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
        
        _calculateWidthConstantOfContentAlignmentView()
        _offsetPositionsUpToEndIndex = _calculatedPositionsUptoTitleItemAtEndIndex()
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
    }
    
    // MARK: - Tab transitions.
    
    public func beginTransitionNavigationTitleItems(_ items: [TabNavigationTitleItem], selectedIndex index: Array<TabNavigationTitleItem>.Index = 0, actionsConfig: (() -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?))? = nil, navigationItems: [TabNavigationItem]) -> TabNavigationTransitionContext {
        // Create views.
        let itemViews = _createAndSetupTitleItemViews()
        let _itemViews: TabNavigationTitleItemViews = (_titleItemsScrollView, _navigationTitleItemView, _titleItemContentAlignmentView as UIView)
        let animationParameters = (_titleItemsContainerView, _itemViews, itemViews)
        
        var navigationTitleActionItems: [TabNavigationTitleActionItem] = []
        let actionResults = actionsConfig?() ?? (ignore: false, actions: nil)
        if !actionResults.ignore {
            if let actions = actionResults.actions {
                navigationTitleActionItems = actions
            } else {
                // Make a deep copy of the navigation title action items.
                for item in _navigationTitleActionItems {
                    let _deepCpItem = TabNavigationTitleActionItem(title: item._button.title(for: .normal)!)
                    _deepCpItem.setTitleFont(item.titleFont(whenSelected: false), whenSelected: false)
                    _deepCpItem.setTitleColor(item.titleColor(whenSelected: false), whenSelected: false)
                    if let action = item._action, let target = item._target {
                        _deepCpItem._button.addTarget(target, action: action, for: .touchUpInside)
                    }
                    _deepCpItem.tintColor = item.tintColor
                    navigationTitleActionItems.append(_deepCpItem)
                }
            }
            
            // Add title action item first.
            var _transitionActionItems: [TabNavigationTitleActionItem] = []
            for item in navigationTitleActionItems {
                _addNavigationTitleItemButton(item, in: _transitionActionItems, possibleActions: _transitionActionItems, to: itemViews.itemsView, alignmentContentView: (itemViews.alignmentContentView as! TabNavigationBar._TabNavigaitonTitleContentAlignmentView), transition: true)
                _transitionActionItems.append(item)
            }
        }
        // Add title items.
        var transitionItems: [TabNavigationTitleItem] = []
        for item in items {
            _addNavigationTitleItemButton(item, in: transitionItems, possibleActions: navigationTitleActionItems, to: itemViews.itemsView, alignmentContentView: itemViews.alignmentContentView as? _TabNavigaitonTitleContentAlignmentView, transition: true)
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
        for _itemView in navigationItemViews.itemsView.subviews {
            _itemView.removeFromSuperview()
        }
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
        guard let navigationItemViews = itemViews else {
            return
        }
        
        if success {
            _commitTransitionNavigationItemViews(navigationItemViews, navigationItems: navigationItems)
        } else {
            _navigationItemView.alpha = 1.0
            if let _constraint = _constraintBetweenTransitionTitleContainerAndItemsContainer  {
                removeConstraint(_constraint)
            }
            let _constraint = _titleItemsContainerView.trailingAnchor.constraint(equalTo: _itemsContainerView.leadingAnchor, constant: -DefaultTabNavigationItemEdgeMargin)
            _constraint.isActive = true
            _constraintBetweenTitleContainerAndItemsContainer = _constraint
            navigationItemViews.itemsContainerView.removeFromSuperview()
        }
    }
    
    public func commitTransitionTitleItemViews(_ itemViews: TabNavigationTitleItemViews, items titleItems: [TabNavigationTitleItem]) {
        _commitTransitionTitleItemViews(itemViews, titleItems: titleItems)
    }
    
    public func setNestedScrollViewContentOffset(_ contentOffset: CGPoint, contentSize: CGSize, bounds: CGRect, transition itemViews: TabNavigationItemViews? = nil) {
        let _offsetPositions = _calculatedPositionsUptoTitleItemAtEndIndex()
        
        let index = Int(contentOffset.x / bounds.width)
        let beginsOffsetPosition = _offsetPositions[index]
        
        var _transitionOffsetDelta: CGFloat = 0.0
        if index == _offsetPositions.index(before: _offsetPositions.endIndex) {
            _transitionOffsetDelta = _offsetPositions[index] - _offsetPositions[_offsetPositions.index(before: index)]
        } else if index == _offsetPositions.startIndex {
            _transitionOffsetDelta = _offsetPositions[_offsetPositions.index(after: index)]
        } else {
            _transitionOffsetDelta = _offsetPositions[_offsetPositions.index(after: index)] - _offsetPositions[index]
        }
        
        let _signedPercent = contentOffset.x.truncatingRemainder(dividingBy: bounds.width) / bounds.width
        let _offsetXDelta = _transitionOffsetDelta * _signedPercent
        let _offsetX = beginsOffsetPosition + _offsetXDelta
        
        _titleItemsScrollView.setContentOffset(CGPoint(x: _offsetX, y: 0.0), animated: false)
        
        if let navigationItemView = itemViews?.itemsView {
            if _signedPercent >= navigationItemView.alpha {
                navigationItemView.alpha = _signedPercent
            }
            _navigationItemView.alpha = 1-navigationItemView.alpha
        }
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

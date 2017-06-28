//
//  NavigationBar.swift
//  AxReminder
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

private class _TabNavigationItemButton: UIButton { /* Custom view hooks. */ }
private class _TabNavigationTitleItemButton: UIButton { // Custom view hooks.
    weak var _titleItem: TabNavigationTitleItem?
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
        button.titleLabel?.font = UIFont(name: "PingFangTC-Semibold", size: DefaultTabNavigationItemFontSize)
        // button.tintColor =
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
        backgroundColor = .clear
        // Set up button.
        _setupButton()
    }
    
    // Private:
    private func _setupButton() {
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
    
    public var target: Any? {
        return _view._button.allTargets.first
    }
    
    public var selector: Selector? {
        guard let _selector = _view._button.actions(forTarget: target, forControlEvent: .touchUpInside)?.first else {
            return nil
        }
        return Selector(_selector)
    }
    
    fileprivate var _view: _TabNavigationItemView = _TabNavigationItemView()
    
    public init(image: UIImage? = nil, target: Any?, selector: Selector) {
        super.init()
        _view.image = image
        _view._button.addTarget(target, action: selector, for: .touchUpInside)
    }
    
    public init(title: String? = nil, target: Any?, selector: Selector) {
        super.init()
        _view.title = title
        _view._button.addTarget(target, action: selector, for: .touchUpInside)
    }
}

public class TabNavigationTitleItem: NSObject {
    public var selected: Bool {
        didSet {
            setSelected(selected, animated: false)
        }
    }
    
    public func setSelected(_ selected: Bool, animated: Bool) {
        if animated {
            let _fontSizeAnimation = POPSpringAnimation()
            _fontSizeAnimation.property = POPAnimatableProperty.labelFontSize(named: "PingFangTC-Semibold")
            _fontSizeAnimation.toValue = selected ? DefaultTitleFontSize : DefaultTitleUnselectedFontSize
            _fontSizeAnimation.removedOnCompletion = true
            self._button.titleLabel?.pop_add(_fontSizeAnimation, forKey: "FONT")
            
            let _titleColorAnimation = POPSpringAnimation()
            _titleColorAnimation.property = POPAnimatableProperty.buttonTitleColor(for: . normal)
            _titleColorAnimation.toValue = selected ? UIColor(hex: "4A4A4A") : UIColor(hex: "CCCCCC")
            _titleColorAnimation.removedOnCompletion = true
            self._button.pop_add(_titleColorAnimation, forKey: "COLOR")
            
            let _tintColorAnimation = POPSpringAnimation(propertyNamed: kPOPViewTintColor)
            _tintColorAnimation?.toValue = selected ? UIColor(hex: "4A4A4A") : UIColor(hex: "CCCCCC")
            _tintColorAnimation?.removedOnCompletion = true
            self._button.pop_add(_tintColorAnimation, forKey: "TINTCOLOR")
        } else {
            self._button.titleLabel?.font = UIFont(name: "PingFangTC-Semibold", size: selected ? DefaultTitleFontSize : DefaultTitleUnselectedFontSize)
            self._button.tintColor = selected ? UIColor(hex: "4A4A4A") : UIColor(hex: "CCCCCC")
            self._button.setTitleColor(selected ? UIColor(hex: "4A4A4A") : UIColor(hex: "CCCCCC"), for: .normal)
        }
    }
    
    fileprivate lazy var _button: _TabNavigationTitleItemButton = { () -> _TabNavigationTitleItemButton in
        let button = _TabNavigationTitleItemButton(type: .custom)
        button.titleLabel?.font = UIFont(name: "PingFangTC-Semibold", size: DefaultTitleFontSize)
        button.tintColor = UIColor(hex: "4A4A4A")
        button.setTitleColor(UIColor(hex: "4A4A4A"), for: .normal)
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
}

public class TabNavigationBar: UIView, UIBarPositioning {
    // MARK: - Public Properties.
    // MARK: - Private Properties.
    private lazy var __titleAlignmentLabel: UILabel = { () -> UILabel in
        let label = UILabel()
        label.text = "_|_"
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "PingFangTC-Semibold", size: DefaultTitleFontSize)
        label.textColor = .clear
        label.backgroundColor = .clear
        return label
    }()
    
    private lazy var _scrollViewContainerView: UIView = { () -> UIView in
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    private lazy var _contentScrollView: UIScrollView = { () -> UIScrollView in
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = UIColor.clear
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        // scrollView.alwaysBounceHorizontal = true
        // scrollView.isScrollEnabled = false
        return scrollView
    }()
    private lazy var _navigationItemView: UIView = { () -> UIView in
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    
    fileprivate var _navigationItems: [TabNavigationItem] = []
    fileprivate var _navigationTitleItems: [TabNavigationTitleItem] = []
    
    fileprivate var _selectedTitleItemIndex: Int = 0
    fileprivate var _transitonTitleItemIndex: Int = 0
    
    private weak var _leadingConstraintOflastItemView: NSLayoutConstraint?
    private weak var _trailingConstraintOflastTitleItemLabel: NSLayoutConstraint?
    
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
        
        _setupContentScrollView()
    }
    
    // MARK: - Actions.
    @objc
    private func _handleDidSelectTitleItem(_ sender: _TabNavigationTitleItemButton) {
        guard let _titleItem = sender._titleItem else {
            return
        }
        
        if let index = _navigationTitleItems.index(of: _titleItem) {
            setSelectedTitle(at: index, animated: true)
        }
        
        _scrollToSelectedTitleItem()
    }
    
    // MARK: - Private.
    private func _setupContainerViews() {
        addSubview(_scrollViewContainerView)
        addConstraint(NSLayoutConstraint(item: self, attribute: .leading, relatedBy: .equal, toItem: _scrollViewContainerView, attribute: .leading, multiplier: 1.0, constant: 0.0))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[_scrollViewContainerView]|", options: [], metrics: nil, views: ["_scrollViewContainerView":_scrollViewContainerView]))
        
        addSubview(_navigationItemView)
        // _navigationItemView.setContentHuggingPriority(.required, for: .horizontal)
        addConstraint(NSLayoutConstraint(item: _scrollViewContainerView, attribute: .trailing, relatedBy: .equal, toItem: _navigationItemView, attribute: .leading, multiplier: 1.0, constant: 0.0))
        addConstraint(NSLayoutConstraint(item: self, attribute: .trailing, relatedBy: .equal, toItem: _navigationItemView, attribute: .trailing, multiplier: 1.0, constant: 0.0))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[_navigationItemView]|", options: [], metrics: nil, views: ["_navigationItemView":_navigationItemView]))
    }
    
    private func _setupContentScrollView() {
        _contentScrollView.delegate = self
        _scrollViewContainerView.addSubview(_contentScrollView)
        _scrollViewContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[_contentScrollView]|", options: [], metrics: nil, views: ["_contentScrollView":_contentScrollView]))
        _scrollViewContainerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[_contentScrollView]|", options: [], metrics: nil, views: ["_contentScrollView":_contentScrollView]))
        _scrollViewContainerView.addConstraint(NSLayoutConstraint(item: _scrollViewContainerView, attribute: .height, relatedBy: .equal, toItem: _contentScrollView, attribute: .height, multiplier: 1.0, constant: 0.0))
        _scrollViewContainerView.addConstraint(NSLayoutConstraint(item: _scrollViewContainerView, attribute: .width, relatedBy: .equal, toItem: _contentScrollView, attribute: .width, multiplier: 1.0, constant: 0.0))
        
        _contentScrollView.addSubview(__titleAlignmentLabel)
        _scrollViewContainerView.addConstraint(NSLayoutConstraint(item: _scrollViewContainerView, attribute: .leading, relatedBy: .equal, toItem: __titleAlignmentLabel, attribute: .leading, multiplier: 1.0, constant: -DefaultTabNavigationTitleItemPadding))
        _scrollViewContainerView.addConstraint(NSLayoutConstraint(item: _scrollViewContainerView, attribute: .centerY, relatedBy: .equal, toItem: __titleAlignmentLabel, attribute: .centerY, multiplier: 1.0, constant: 0.0))
    }
    
    fileprivate func _addNavigationItemView(_ item: TabNavigationItem) {
        let _itemView = item._view
        _itemView.translatesAutoresizingMaskIntoConstraints = false

        _navigationItemView.addSubview(_itemView)
        // Height and with:
        _itemView.addConstraint(NSLayoutConstraint(item: _itemView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: DefaultTabNavigationItemHeight))
        _itemView.addConstraint(NSLayoutConstraint(item: _itemView, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: DefaultTabNavigationItemWidthThreshold))
        // Base line:
        addConstraint(NSLayoutConstraint(item: _itemView._button, attribute: _navigationTitleItems.last != nil ? .lastBaseline : .centerY, relatedBy: .equal, toItem: _navigationTitleItems.last?._button ?? _navigationItemView, attribute: _navigationTitleItems.last != nil ? .lastBaseline : .centerY, multiplier: 1.0, constant: 0.0))
        // Horizontal:
        _navigationItemView.addConstraint(NSLayoutConstraint(item: _itemView, attribute: .trailing, relatedBy: .equal, toItem: _navigationItems.last?._view ?? _navigationItemView, attribute: _navigationItems.last?._view != nil ? .leading : .trailing, multiplier: 1.0, constant: _navigationItems.count>0 ? 0.0 : -DefaultTabNavigationItemEdgeMargin))
        if let _leading = _leadingConstraintOflastItemView {
            _navigationItemView.removeConstraint(_leading)
        }
        
        let _leading = NSLayoutConstraint(item: _navigationItemView, attribute: .leading, relatedBy: .equal, toItem: _itemView, attribute: .leading, multiplier: 1.0, constant: 0.0)
        _navigationItemView.addConstraint(_leading)
        _leadingConstraintOflastItemView = _leading
    }
    
    fileprivate func _addNavigationTitleItemButton(_ item: TabNavigationTitleItem) {
        let _itemButton = item._button
        _itemButton.addTarget(self, action: #selector(_handleDidSelectTitleItem(_:)), for: .touchUpInside)
        _itemButton.translatesAutoresizingMaskIntoConstraints = false
        
        _contentScrollView.addSubview(_itemButton)
        
        _contentScrollView.addConstraint(NSLayoutConstraint(item: _itemButton, attribute: .leading, relatedBy: .equal, toItem: _navigationTitleItems.last?._button ?? _contentScrollView, attribute: _navigationTitleItems.last?._button != nil ? .trailing : .leading, multiplier: 1.0, constant:DefaultTabNavigationTitleItemPadding))
        _contentScrollView.addConstraint(NSLayoutConstraint(item: __titleAlignmentLabel, attribute: .lastBaseline, relatedBy: .equal, toItem: _itemButton, attribute: .lastBaseline, multiplier: 1.0, constant: 0.0))
        
        if let _trailing = _trailingConstraintOflastTitleItemLabel {
            _contentScrollView.removeConstraint(_trailing)
        }
        let _trailing = NSLayoutConstraint(item: _contentScrollView, attribute: .trailing, relatedBy: .equal, toItem: _itemButton, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        _contentScrollView.addConstraint(_trailing)
        _trailingConstraintOflastTitleItemLabel = _trailing
    }
    
    @objc
    fileprivate func _scrollToSelectedTitleItem(_ animated: Bool = true) {
        _contentScrollView.setContentOffset(CGPoint(x: _calculatedPositionUptoTitleItemIndex(_selectedTitleItemIndex), y: 0.0), animated: animated)
    }
    @objc
    fileprivate func _scrollToSelectedTitleItemWithAnimation() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
        _scrollToSelectedTitleItem()
    }
    
    fileprivate func _calculatedPositionUptoTitleItemIndex(_ index: Int = 0) -> CGFloat {
        assert(index < _navigationTitleItems.endIndex, "Index of title item is out of bounds.")
        var _positionX: CGFloat = 0.0
        
        for index in 0...index {
            if index > _navigationTitleItems.startIndex {
                _positionX += DefaultTabNavigationTitleItemPadding
                let _titleItem = _navigationTitleItems[_navigationTitleItems.index(before: index)]
                let size = (_titleItem._button.currentTitle as NSString?)?.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: self.bounds.height), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: [NSFontAttributeName:_titleItem._button.titleLabel != nil ? UIFont(name: _titleItem._button.titleLabel!.font.fontName, size: DefaultTitleUnselectedFontSize) as Any : UIFont.systemFont(ofSize: DefaultTitleUnselectedFontSize)], context: nil).size
                _positionX += CGFloat(Double(size!.width))
            }
        }
        
        return _positionX
    }
}

extension TabNavigationBar: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /*
        return
        let _uptoSelectedTitleItemPosition = _calculatedPositionUptoTitleItemIndex(_transitonTitleItemIndex)
        let _offset = scrollView.contentOffset.x - _uptoSelectedTitleItemPosition
        print("Offset of selected title index: \(_offset)")
        
        var _comingIndex: Int = 0
        var _comingOffsetPosition: CGFloat = 0.0
        
        if _offset >= 0 {
            guard _transitonTitleItemIndex < _navigationTitleItems.index(before: _navigationTitleItems.endIndex) else { return }
            
            // Get coming index of navigation title items.
            _comingIndex = _navigationTitleItems.index(after: _transitonTitleItemIndex)
            // Calculate the offset position to the coming index.
            _comingOffsetPosition = _calculatedPositionUptoTitleItemIndex(_comingIndex) - _uptoSelectedTitleItemPosition
        } else {
            guard _transitonTitleItemIndex > _navigationTitleItems.startIndex else { return }
            
            // Get coming index of navigation title items.
            _comingIndex = _navigationTitleItems.index(before: _transitonTitleItemIndex)
            // Calculate the offset position to the coming index.
            _comingOffsetPosition = _uptoSelectedTitleItemPosition - _calculatedPositionUptoTitleItemIndex(_comingIndex)
        }
        
        print("Coming offset position: \(_comingOffsetPosition)")
        
        if Double(_comingOffsetPosition) > fabs(Double(_offset)) {
            let _transitionPercent = fabs(Double(_offset))/Double(_comingOffsetPosition)
            let _deltaOfFontSize = Double(DefaultTitleFontSize - DefaultTitleUnselectedFontSize) * _transitionPercent
            
            let _transitionTitleItem = _navigationTitleItems[_transitonTitleItemIndex]
            let _comingTitleItem = _navigationTitleItems[_comingIndex]
            
            let _fontName = _transitionTitleItem._button.titleLabel?.font.fontName
            
            _transitionTitleItem._button.titleLabel?.font = UIFont(name: _fontName!, size: CGFloat(DefaultTitleFontSize) - CGFloat(_deltaOfFontSize))
            _comingTitleItem._button.titleLabel?.font = UIFont(name: _fontName!, size: CGFloat(DefaultTitleUnselectedFontSize) + CGFloat(_deltaOfFontSize))
        } else {
            _transitonTitleItemIndex = _comingIndex
            // setSelectedTitle(at: _comingIndex, animated: false)
        } */
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_scrollToSelectedTitleItemWithAnimation), object: nil)
        self.perform(#selector(_scrollToSelectedTitleItemWithAnimation), with: nil, afterDelay: 2.0, inModes: [.commonModes])
    }
}

extension TabNavigationBar {
    // MARK: - Public.
    public var selectedTitleItem: TabNavigationTitleItem { return _navigationTitleItems[_selectedTitleItemIndex] }
    
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
    
    public func addNavigationItem(_ item: TabNavigationItem) {
        _addNavigationItemView(item)
        
        _navigationItems.append(item)
    }
    
    public func addNavigationTitleItem(_ item: TabNavigationTitleItem) {
        _addNavigationTitleItemButton(item)
        
        _navigationTitleItems.append(item)
    }
    // MARK: - Selected title.
    public func setSelectedTitle(at index: Int, animated: Bool) {
        assert(index < _navigationTitleItems.endIndex, "Index of title item is out of bounds.")
        _selectedTitleItemIndex = index
        
        for (idx, item) in _navigationTitleItems.enumerated() {
            if idx == index {
                item.setSelected(true, animated: animated)
            } else {
                item.setSelected(false, animated: animated)
            }
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

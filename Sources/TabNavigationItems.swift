//
//  TabNavigationItems.swift
//  AxReminder
//
//  Created by devedbox on 2017/9/18.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Foundation
import QuartzCore

/// The type defines the constants of the TabNavigationItems.
internal struct _TabNavigationConfig {
    /// The font size for the title item button.
    let titleFontSize          : CGFloat
    /// The font size for the title item button at unselected state.
    let titleUnselectedFontSize: CGFloat
    /// The font size for the navigation item button.
    let itemFontSize           : CGFloat
    /// The padding constant of the items.
    let titleItemPadding       : CGFloat
    /// The edge margin of the items.
    let itemEdgeMargin         : CGFloat
    /// The height for the item button.
    let itemHeight             : CGFloat
    /// The minimal width value for the item button.
    let itemWidthThreshold     : CGFloat
}
extension _TabNavigationConfig {
    /// Returns the default configuration contains all the static constant of font size, padding value and sizes.
    static var `default` = _TabNavigationConfig(titleFontSize: 36.0, titleUnselectedFontSize: 16.0, itemFontSize: 14.0, titleItemPadding: 15.0, itemEdgeMargin: 8.0, itemHeight: 44.0, itemWidthThreshold: 30.0)
}

extension _TabNavigationConfig {
    /// The horizontal edge margin for the _TabNavigationItemView.
    static var edgeMarginForItemView: CGFloat { return 6.0 }
}

/// A type subclassing the UIButton representing the button element of the tab navigation item.
internal class _TabNavigationItemButton: UIButton { /* Custom view hooks. */ }
/// A type subclassing the UIButton representing the button element of the tab navigation title item.
internal class _TabNavigationTitleItemButton: UIButton { // Custom view hooks.
    /// The refrence storage if the related title item.
    weak var   _titleItem: TabNavigationTitleItem?
}

/// A subclassing of UIView representing the underlying container view of TabNavigationItem.
internal class _TabNavigationItemView: UIView {
    /// The title for the underlying button.
    var title: String?  { didSet { _button.setTitle(title, for: .normal) } }
    /// The image for the underlying button.
    var image: UIImage? { didSet { _button.setImage(image, for: .normal) } }
    /// The underlying UIButton object.
    lazy var _button: _TabNavigationItemButton = { () -> _TabNavigationItemButton in
        let button = _TabNavigationItemButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false // Using auto-layout.
        button.backgroundColor  = UIColor.clear
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: _TabNavigationConfig.default.itemFontSize)
        return button
    }()
    
    // MARK: Initializer.
    
    override init(frame: CGRect) {
        super.init(frame: frame);    _initializer()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder); _initializer()
    }
    
    private func _initializer() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .clear
        // Set up button.
        _setupButton()
    }
    
    // MARK: Private.
    private func _setupButton() {
        _button.heightAnchor.constraint(equalToConstant: _TabNavigationConfig.default.itemHeight).isActive = true
        widthAnchor.constraint(greaterThanOrEqualToConstant: _TabNavigationConfig.default.itemWidthThreshold).isActive = true
        
        addSubview(_button)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(margin)-[_button]-(margin)-|", options: [], metrics: ["margin": _TabNavigationConfig.edgeMarginForItemView], views: ["_button":_button]))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(>=0)-[_button]-(>=0)-|", options: [], metrics: nil, views: ["_button":_button]))
        
        _button.setContentHuggingPriority(1000.0, for: .horizontal)
    }
}
/// A type representing the navigation item on the right top corner of TabNavigationBar.
/// Same as the UINavigationItem to set up and use.
public class TabNavigationItem: NSObject {
    // MARK: - Properties.
    
    /// Returns the image of the underlying button.
    public var image: UIImage? { return _button.currentImage }
    /// Returns the title of the underlying button.
    public var title: String?  { return _button.currentTitle }
    /// The tint color of the underlying button.
    public var tintColor: UIColor? {
        set { _button.tintColor = newValue }
        get { return _button.tintColor }
    }
    /// The target in action-target mode of the underlying button.
    public var target: Any? { return _button.allTargets.first }
    /// Returns the first selector for the target of the underlying button.
    public var selector: Selector? {
        guard let _selector = _button.actions(forTarget: target, forControlEvent: .touchUpInside)?.first else { return nil }
        return Selector(_selector)
    }
    /// Returns the underlying view.
    internal var underlyingView  : UIView   { return underlyingButton }
    /// Returns the underlying button.
    internal var underlyingButton: UIButton { return _button }
    /// The underlying item view to manage the underlying button.
    @available(*, unavailable)
    private var _view: _TabNavigationItemView = _TabNavigationItemView()
    /// The underlying item button of the navigation item.
    private lazy var _button = { () -> _TabNavigationItemButton in
        let button = _TabNavigationItemButton(type: .system)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: _TabNavigationConfig.default.itemFontSize)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.widthAnchor.constraint(greaterThanOrEqualToConstant : _TabNavigationConfig.default.itemWidthThreshold).isActive = true
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: _TabNavigationConfig.default.itemHeight).isActive         = true
        button.setContentHuggingPriority(1000.0, for: .horizontal)
        button.setContentHuggingPriority(998.0,  for: .vertical)
        button.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 6.0, bottom: 0.0, right: 6.0)
        return button
    }()
    
    // MARK: Iniaializer.
    
    /// Creates a TabNavigationItem with a title for the underlying button.
    ///
    /// - Parameter title: The String value for the title of the underlying button at normal state.
    /// - Returns: A new item with the given title.
    public init(title: String?) {
        super.init()
        _button.setTitle(title, for: .normal)
    }
    /// Creates a TabNavigationItem with an image, target and selector for the underlying button.
    ///
    /// - Parameter image   : An UIImage object for the image of the underlying button at normal state.
    /// - Parameter target  : The target object for the action-target mode. Default: nil.
    /// - Parameter selector: The Selector value for the action-target mode. Default: nil.
    ///
    /// - Returns: A new item with the given parameters.
    public convenience init(image: UIImage? = nil, target: Any? = nil, selector: Selector? = nil) {
        self.init(title: nil)
        _button.setImage(image, for: .normal)
        if selector != nil {
            _button.addTarget(target, action: selector!, for: .touchUpInside)
        }
    }
    /// Creates a TabNavigationItem with a title, target and selector for the underlying button.
    ///
    /// - Parameter title   : A String value for the title of the underlying button at normal state.
    /// - Parameter target  : The target object for the action-target mode. Default: nil.
    /// - Parameter selector: The Selector value for the action-target mode. Default: nil.
    ///
    /// - Returns: A new item with the given parameters.
    public convenience init(title: String? = nil, target: Any? = nil, selector: Selector? = nil) {
        self.init(title: title)
        _button.setTitle(title, for: .normal)
        if selector != nil {
            _button.addTarget(target, action: selector!, for: .touchUpInside)
        }
    }
}

extension _TabNavigationItemButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Force to center the position of the image view or title label.
        imageView?.center  = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
        titleLabel?.center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
    }
}

/// A type reprensting the navigation back item of the TabNavigationBar.
internal class _TabNavigationBackItem: TabNavigationItem { /* Back navigation item*/ }
/// A type representing the navigation title item on the left top corner of TabNavigationBar.
public class TabNavigationTitleItem: NSObject {
    /// Indicates the selection state of the title item. The selected state will has a large font size
    /// and heavy text color.
    public var selected: Bool {
        didSet {
            if let range = selectedRange {
                let attributedTitle = NSMutableAttributedString(attributedString: self._button.attributedTitle(for: .normal)!)
                let _ns_range = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)
                attributedTitle.addAttributes([NSFontAttributeName: titleFont(whenSelected: selected), NSForegroundColorAttributeName: titleColor(whenSelected: selected)], range: _ns_range)
                self._button.setAttributedTitle(attributedTitle, for: .normal)
            } else {
                self._button.titleLabel?.font = _selectionTitleFonts[selected]
                self._button.tintColor        = _selectionTitleColors[selected]
                self._button.setTitleColor(_selectionTitleColors[selected], for: .normal)
            }
        }
    }
    /// A CountableRange<Int> value indicates the range of the title content to be selected.
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
    /// Returns the title color of current selection state.
    public var currentTitleColor: UIColor { return _selectionTitleColors[selected]! }
    /// Returns the title font of current selection state.
    public var currentTitleFont: UIFont { return _selectionTitleFonts[selected]! }
    /// The title colors configs for the selection states.
    private var _selectionTitleColors: [Bool: UIColor] = [true : UIColor(red: 0.29, green: 0.29, blue: 0.29, alpha: 1.0),
                                                          false: UIColor(red: 0.8,  green: 0.8,  blue: 0.8,  alpha: 1.0)]
    /// The title fonts configs for the selection states.
    private var _selectionTitleFonts: [Bool: UIFont] = [true: UIFont.boldSystemFont(ofSize: _TabNavigationConfig.default.titleFontSize), false: UIFont.boldSystemFont(ofSize: _TabNavigationConfig.default.titleUnselectedFontSize)]
    /// Sets and updates the color configs for the selection states of the item.
    ///
    /// - Parameter titleColor: A UIColor object to update the color config.
    /// - Parameter selected  : The selection state, true for selected and false for unselected.
    public func setTitleColor(_ titleColor: UIColor, whenSelected selected: Bool) {
        _selectionTitleColors[selected] = titleColor
    }
    /// Get the title color for the specific selection state.
    ///
    /// - Parameter selected: The selection state.
    /// - Returns: The color for the selection state.
    public func titleColor(whenSelected selected: Bool) -> UIColor {
        return _selectionTitleColors[selected]!
    }
    /// Sets and updates the font configs for the selection states of the item.
    ///
    /// - Parameter titleFont: A UIFont object to update the font config.
    /// - Parameter selected : The selection state, true for selected and false for unselected.
    public func setTitleFont(_ titleFont: UIFont, whenSelected selected: Bool) {
        _selectionTitleFonts[selected] = titleFont
        if _selectionTitleFonts[true]!.fontName != _selectionTitleFonts[false]!.fontName {
            fatalError("Font for selected state and font for unselected state must have the same font family and name.")
        }
    }
    /// Get the title font for the specific selection state.
    ///
    /// - Parameter selected: The selection state.
    /// - Returns: The font for the selection state.
    public func titleFont(whenSelected selected: Bool) -> UIFont {
        return _selectionTitleFonts[selected]!
    }
    
    @available(iOS, unavailable, message: "Animating set selection state of `TabNavigationTitleItem` is not supported.")
    public func setSelected(_ selected: Bool, animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            let framesCount = 69.0
            let duration = 0.4
            UIView.animateKeyframes(withDuration: duration, delay: 0.0, options: [.layoutSubviews, .calculationModeDiscrete], animations: { [unowned self] in
                for index in 0..<Int(framesCount) {
                    let percent = Double(index) / framesCount
                    UIView.addKeyframe(withRelativeStartTime: percent, relativeDuration: percent * duration, animations: {
                        let delta = (self._selectionTitleFonts[true]!.pointSize - self._selectionTitleFonts[false]!.pointSize) * CGFloat(percent)
                        let fontSize = self._selectionTitleFonts[!selected]!.pointSize + (delta * (selected ? 1.0 : -1.0))
                        let tintColor = UIColor.color(from: self._selectionTitleColors[!selected]!, to: self._selectionTitleColors[selected]!, percent: CGFloat(percent))
                        
                        if let range = self.selectedRange {
                            let _ns_range = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)
                            let attributedTitle = NSMutableAttributedString(string: self._titleStorage, attributes: [NSFontAttributeName: self._selectionTitleFonts[false]!, NSForegroundColorAttributeName: self._selectionTitleColors[false]!])
                            attributedTitle.addAttributes([NSFontAttributeName: UIFont(name: self._selectionTitleFonts[true]!.fontName, size: fontSize)!, NSForegroundColorAttributeName: tintColor], range: _ns_range)
                            self._button.setAttributedTitle(attributedTitle, for: .normal)
                        } else {
                            self._button.titleLabel?.font = UIFont(name: self._selectionTitleFonts[true]!.fontName, size: fontSize)!
                            self._button.tintColor = tintColor
                            self._button.setTitleColor(tintColor, for: .normal)
                        }
                    })
                }
            }) { (_) in
                completion?()
            }
        } else {
            if let range = selectedRange {
                let attributedTitle = NSMutableAttributedString(attributedString: self._button.attributedTitle(for: .normal)!)
                let _ns_range = NSMakeRange(range.lowerBound, range.upperBound - range.lowerBound)
                attributedTitle.addAttributes([NSFontAttributeName: titleFont(whenSelected: selected), NSForegroundColorAttributeName: titleColor(whenSelected: selected)], range: _ns_range)
                self._button.setAttributedTitle(attributedTitle, for: .normal)
            } else {
                self._button.titleLabel?.font = _selectionTitleFonts[selected]
                self._button.tintColor        = _selectionTitleColors[selected]
                self._button.setTitleColor(_selectionTitleColors[selected], for: .normal)
            }
        }
    }
    /// The underlying button object.
    internal var underlyingButton: UIButton { return _button }
    /// The underlying UIButton object.
    fileprivate lazy var _button: _TabNavigationTitleItemButton = { () -> _TabNavigationTitleItemButton in
        let button = _TabNavigationTitleItemButton(type: .custom)
        button.titleLabel?.numberOfLines = 1
        button.adjustsImageWhenHighlighted = false
        return button
    }()
    /// The storage for the title item.
    internal var _titleStorage: String!
    /// Creates a TabNavigationTitleItem object with a given title content.
    ///
    /// - Parameter title: A String value for the underlying button title of the title item.
    /// - Returns: A new TabNavigationTitleItem item.
    public init(title: String) {
        // _titleStorage = title
        selected = false
        super.init()
        _button.setTitle(title, for: .normal)
        _button._titleItem = self
    }
    /// Creates a TabNavigationTitleItem object with a given title content and selection range.
    ///
    /// - Parameter title        : A String value for the underlying button title of the title item.
    /// - Parameter selectedRange: A CountableRange<Int> value indicates the range of the selection of the button title.
    /// - Returns: A new TabNavigationTitleItem item.
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
/// A subclassing of TabNavigationTitleItem representing the title action item.
///
/// A title action item lay on the right end of the title items, the action item
/// cannot be selected like the title item, but the action item can perform like
/// a navigation item on the right corner of the tab nagivation bar.
public class TabNavigationTitleActionItem: TabNavigationTitleItem {
    /// Returns the unselected font for the action item.
    public override func titleFont(whenSelected selected: Bool) -> UIFont   { return super.titleFont(whenSelected: false ) }
    /// Returns the unselected color for the action item.
    public override func titleColor(whenSelected selected: Bool) -> UIColor { return super.titleColor(whenSelected: false) }
    /// Using system type button.
    override lazy var _button: _TabNavigationTitleItemButton = _TabNavigationTitleItemButton(type: .system)
    /// The action target for the underlying UIButton item to trigger.
    internal var _target: Any?
    /// The action selector fot the target to perform.
    internal var _action: Selector?
    /// The tint color of the action button.
    public var tintColor: UIColor? {
        didSet {
            _button.tintColor = tintColor
            if let tint = tintColor {
                setTitleColor(tint, whenSelected: false)
            }
        }
    }
    /// Creates a TabNavigationTitleActionItem object with a given title content.
    ///
    /// - Parameter title: A String value for the underlying button title of the title item.
    /// - Returns: A new TabNavigationTitleActionItem item.
    public override init(title: String) {
        super.init(title: title)
        _button = _TabNavigationTitleItemButton(type: .system)
        _button.setTitle(title, for: .normal)
        _button._titleItem = self
    }
    /// Creates a TabNavigationTitleActionItem object with a given title content and target-action field.
    ///
    /// - Parameter title   : A String value for the underlying button title of the title item.
    /// - Parameter target  : The target object for the action-target mode.
    /// - Parameter selector: The Selector value for the action-target mode.
    /// - Returns: A new TabNavigationTitleActionItem item.
    public convenience init(title: String, target: Any?, selector: Selector) {
        self.init(title: title)
        _target = target
        _action = selector
        
        _button.addTarget(target, action: selector, for: .touchUpInside)
    }
}

extension _TabNavigationTitleItemButton {
    // Overrides to force stylize the button.
    override func setAttributedTitle(_ title: NSAttributedString?, for state: UIControlState) {
        if buttonType == .system { if let text = title?.string { setTitle(text, for: state) } } else {
            super.setAttributedTitle(title, for: state)
        }
    }
    // Overrides to force stylize the button.
    override func setTitleColor(_ color: UIColor?, for state: UIControlState) {
        if buttonType == .system { if let tint = color { tintColor = tint } } else {
            super.setTitleColor(color, for: state)
        }
    }
}

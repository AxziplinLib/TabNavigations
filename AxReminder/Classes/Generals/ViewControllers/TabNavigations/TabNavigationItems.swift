//
//  TabNavigationItems.swift
//  AxReminder
//
//  Created by devedbox on 2017/9/18.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Foundation

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
        button.titleLabel?.font = /*UIFont(name: "PingFangSC-Semibold", size: DefaultTabNavigationItemFontSize)*/UIFont.boldSystemFont(ofSize: DefaultTabNavigationItemFontSize)
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
    private var _selectionTitleFonts: [Bool: UIFont] = [true: /*UIFont(name: "PingFangSC-Semibold", size: DefaultTitleFontSize)!*/UIFont.boldSystemFont(ofSize: DefaultTitleFontSize), false: /*UIFont(name: "PingFangSC-Semibold", size: DefaultTitleUnselectedFontSize)!*/UIFont.boldSystemFont(ofSize: DefaultTabNavigationItemFontSize)]
    
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

extension UIImage {
    /// Creates an image from any instances of `String` with the specific font and tint color in points.
    /// The `String` contents' count should not be zero. If so, nil will be returned.
    ///
    /// More info and tools to generate images: [RichImages](https://github.com/AxziplinLib/RichImages)\/Generator.
    ///
    /// - Parameter content: An instance of `String` to generate `UIImage` with.
    /// - Parameter font   : The font used to draw image with. Using `.systemFont(ofSize: 17)` by default.
    /// - Parameter color  : The color used to fill image with. Using `.black` by default.
    ///
    /// - Returns: A `String` contents image created with specific font and color.
    public class func _generateImage(from content: String, using font: UIFont = .systemFont(ofSize: 17), tint color: UIColor = .black) -> UIImage! {
        let ligature = NSMutableAttributedString(string: content)
        ligature.setAttributes([(kCTLigatureAttributeName as String): 2, (kCTFontAttributeName as String): font], range: NSMakeRange(0, content.lengthOfBytes(using: .utf8)))
        
        var imageSize    = ligature.size()
        imageSize.width  = ceil(imageSize.width)
        imageSize.height = ceil(imageSize.height)
        guard !imageSize.equalTo(.zero) else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        ligature.draw(at: .zero)
        guard let cgImage = UIGraphicsGetImageFromCurrentImageContext()?.cgImage else { return nil }
        
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0.0, y: -imageSize.height)
        let rect = CGRect(origin: .zero, size: imageSize)
        context.clip(to: rect, mask: cgImage)
        color.setFill()
        context.fill(rect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

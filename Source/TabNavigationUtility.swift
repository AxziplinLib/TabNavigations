//
//  TabNavigationUtility.swift
//  TabNavigations
//
//  Created by devedbox on 2017/8/14.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Foundation
import CoreText
import CoreGraphics

/// Return true if the index is in the bounds, otherwise false.
/// 
/// - Parameter index: The index to be checked.
/// - Parameter bounds: The bounds where the index lay in.
///
/// - Returns: Indicate the index is in the bounds or not.
///
internal func _earlyCheckingBounds<T>(_ index: Array<T>.Index, `in` bounds: Array<T>) -> Swift.Bool { return index >= bounds.startIndex && index < bounds.endIndex }
/// Return true if the index is in the bounds but not contains the start inedex, otherwise false.
///
/// - Parameter index: The index to be checked.
/// - Parameter bounds: The bounds where the index lay in.
///
/// - Returns: Indicate the index is in the bounds or not.
///
internal func _earlyCheckingBounds<T>(_ index: Array<T>.Index, inWithoutLower bounds: Array<T>) -> Swift.Bool { return index > bounds.startIndex && index < bounds.endIndex }

// MARK: - Extensions.

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
    internal class func _generateImage(from content: String, using font: UIFont = .systemFont(ofSize: 17), tint color: UIColor = .black) -> UIImage! {
        let ligature = NSMutableAttributedString(string: content, attributes: [(kCTFontAttributeName as String): font])
        
        return _generateImage(from: ligature, tint: color)
    }
    /// Creates an image from any instances of `NSAttributedString` with the specific tint color in points.
    /// The `NSAttributedString` contents' count should not be zero. If so, nil will be returned.
    ///
    /// More info and tools to generate images: [RichImages](https://github.com/AxziplinLib/RichImages)\/Generator.
    ///
    /// - Parameter attributedContent: An instance of `NSAttributedString` to generate `UIImage` with.
    /// - Parameter color            : The color used to fill image with. Using `.black` by default.
    ///
    /// - Returns: A `NSAttributedString` contents image created with specific font and color.
    internal class func _generateImage(from attributedContent: NSAttributedString, tint color: UIColor = .black) -> UIImage! {
        let ligature = NSMutableAttributedString(attributedString: attributedContent)
        ligature.addAttributes([(kCTLigatureAttributeName as String): 2], range: NSMakeRange(0, (attributedContent.string as NSString).length))
        
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

extension UIColor {
    /// A type representing the RGBA components of an UIColor object.
    internal typealias ColorComponents = (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)
    /// Returns the RGBA compoents of `ColorComponents` of the color .
    internal var components: ColorComponents {
        get {
            var _red: CGFloat = 0.0
            var _green: CGFloat = 0.0
            var _blue: CGFloat = 0.0
            var _alpha: CGFloat = 0.0
            getRed(&_red, green: &_green, blue: &_blue, alpha: &_alpha)
            return (_red, _green, _blue, _alpha)
        }
    }
    /// Get the diffrence between two color components.
    ///
    /// - Patameter fromComponents: The components values to be subducted.
    /// - Patameter components    : The components values to subduct.
    ///
    /// - Returns: The result of the two components.
    internal class func diff(from fromComponents: ColorComponents, to components: ColorComponents) -> ColorComponents {
        let _components = fromComponents
        return (components.red - _components.red, components.green - _components.green, components.blue - _components.blue, components.alpha - _components.alpha)
    }
}

extension UIColor {
    /// Calculates the middle color value between self to another color object.
    ///
    /// - Parameter from   : The color to transit from.
    /// - Parameter to     : The color to transit to.
    /// - Parameter percent: The color changing percent. The value is available in [0.0, 1.0].
    ///                      If the value is 0.0, the receiver color will be returned. And the
    ///                      to-color will be returned if the value is 1.0.
    ///
    /// - Returns: An UIColor between the receiver and the to-color by changing the percent.
    internal class func color(from: UIColor, to: UIColor, percent: CGFloat) -> UIColor {
        let fromColorComponents = from.components
        let toColorComponents   = to.components
        let diffComponents      = UIColor.diff(from: fromColorComponents, to: toColorComponents)
        
        let p = min(1.0, max(0.0, percent))
        
        let _red   = fromColorComponents.red   + diffComponents.red   * p
        let _green = fromColorComponents.green + diffComponents.green * p
        let _blue  = fromColorComponents.blue  + diffComponents.blue  * p
        let _alpha = fromColorComponents.alpha + diffComponents.alpha * p
        
        return UIColor(red: _red, green: _green, blue: _blue, alpha: _alpha)
    }
}

extension UIFont {
    /// Calculates the middle font size value between from and to fonts.
    ///
    /// - Parameter from   : The font to transit from.
    /// - Parameter to     : The font to transit to.
    /// - Parameter percent: The font trantision percent. The value is available in [0.0, 1.0].
    ///                      If the value is 0.0, the receiver color will be returned. And the
    ///                      to-color will be returned if the value is 1.0.
    ///
    /// - Returns: An UIColor between the receiver and the to-color by changing the percent.
    internal class func font(from: UIFont, to: UIFont, percent: CGFloat) -> UIFont! {
        // guard from.fontName == to.fontName else { return nil }
        
        let sizeDelta = to.pointSize - from.pointSize
        return UIFont(name: from.fontName, size: from.pointSize + sizeDelta * percent)
    }
}

extension Array {
    var lastIndex: Int { return index(before: endIndex) }
}

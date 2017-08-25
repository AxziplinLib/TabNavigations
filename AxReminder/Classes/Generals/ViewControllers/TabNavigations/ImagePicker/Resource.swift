//
//  Resource.swift
//  TabNavigations/ImagePicker
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Foundation

// MARK: - _Resource.

internal final class _Resource {}

extension _Resource {
    /// Path for the resource bundle.
    ///
    static var bundle: String { return (Bundle(for: self).path(forResource: "Resource", ofType: "bundle") ?? "unspecified") + "/" }
}

// MARK: - Config.

extension _Resource {
    internal struct Config {}
}

// MARK: - Camera.

extension _Resource.Config {
    internal struct Camera {}
}

extension _Resource.Config.Camera {
    internal struct Color {}
}

extension _Resource.Config.Camera.Color {
    static var highlighted: UIColor { return UIColor(colorLiteralRed: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) }
}

// MARK: - Assets.

extension _Resource.Config {
    internal struct Assets {}
}

extension _Resource.Config.Assets {
    internal struct Layouts {}
}

extension _Resource.Config.Assets.Layouts {
    static var sectionInsetValue: CGFloat { return 1.0 }
    static var itemPadding      : CGFloat { return 2.0 }
    static var itemColumns      : CGFloat { return 4.0 }
}

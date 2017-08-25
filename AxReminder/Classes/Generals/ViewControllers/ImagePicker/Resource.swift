//
//  Resource.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Foundation

internal struct Resource {}

extension Resource {
    /// Path for the resource bundle.
    ///
    static var bundle: String { return Bundle(for: TabNavigationImagePickerController.self).path(forResource: String(describing: TabNavigationImagePickerController.self), ofType: "bundle") ?? "unspecified" + "/" }
}

extension Resource {
    internal struct Config {}
}

extension Resource.Config {
    internal struct Camera {}
}

extension Resource.Config.Camera {
    internal struct Color {}
}

extension Resource.Config.Camera.Color {
    static var highlighted: UIColor { return UIColor(colorLiteralRed: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) }
}

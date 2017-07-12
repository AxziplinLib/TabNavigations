//
//  ApplicationColor.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/3.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

protocol ApplicationColorLoadable {
    /*
    var red: UIColor { get }
    var lightRed: UIColor { get }
    var green: UIColor { get }
    var blue: UIColor { get }
    var skyBlue: UIColor { get }
    var yellow: UIColor { get }
    var orange: UIColor { get }
    var gray: UIColor { get } */
}

extension UIColor {
    struct ApplicationColor: ApplicationColorLoadable { }
    class var application: ApplicationColorLoadable {
        get { return ApplicationColor() }
    }
}

extension ApplicationColorLoadable {
    var titleColor: UIColor {
        get { return UIColor(hex: "4A4A4A") }
    }
    var red: UIColor {
        get { return UIColor(hex: "FE2851") }
    }
    var lightRed: UIColor {
        get { return UIColor(hex: "FE3824") }
    }
    var green: UIColor {
        get { return UIColor(hex: "44DB5E") }
    }
    var blue: UIColor {
        get { return UIColor(hex: "0076FF") }
    }
    var skyBlue: UIColor {
        get { return UIColor(hex: "54C7FC") }
    }
    var yellow: UIColor {
        get { return UIColor(hex: "FFCD00") }
    }
    var orange: UIColor {
        get { return UIColor(hex: "FF9600") }
    }
    var gray: UIColor {
        get { return UIColor(hex: "8F8E94") }
    }
}

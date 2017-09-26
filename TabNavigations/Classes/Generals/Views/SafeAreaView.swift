//
//  SafeAreaView.swift
//  AxReminder
//
//  Created by devedbox on 2017/9/18.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

/// A subclassing of UIView that returns safe area layout guide is needed.
class SafeAreaView: UIView { }

extension SafeAreaView {
    override var leadingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.leadingAnchor
        } else {
            return super.leadingAnchor
        }
    }
    override var trailingAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.trailingAnchor
        } else {
            return super.trailingAnchor
        }
    }
    override var leftAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.leftAnchor
        } else {
            return super.leftAnchor
        }
    }
    override var rightAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.rightAnchor
        } else {
            return super.rightAnchor
        }
    }
    override var topAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.topAnchor
        } else {
            return super.topAnchor
        }
    }
    override var bottomAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.bottomAnchor
        } else {
            return super.bottomAnchor
        }
    }
    override var centerXAnchor: NSLayoutXAxisAnchor {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.centerXAnchor
        } else {
            return super.centerXAnchor
        }
    }
    override var centerYAnchor: NSLayoutYAxisAnchor {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.centerYAnchor
        } else {
            return super.centerYAnchor
        }
    }
    override var widthAnchor: NSLayoutDimension {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.widthAnchor
        } else {
            return super.widthAnchor
        }
    }
    override var heightAnchor: NSLayoutDimension {
        if #available(iOS 11.0, *) {
            return super.safeAreaLayoutGuide.heightAnchor
        } else {
            return super.heightAnchor
        }
    }
}

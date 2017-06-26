//
//  NavigationBar.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class NavigationBar: UIView, UIBarPositioning {
    // MARK: - Properties.
    @IBOutlet public var titleLabel: UILabel?
    // MARK: - `NSCoding` supporting.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}
// MARK: - Conforming `NSCoding`.
extension NavigationBar {
    override func encode(with aCoder: NSCoder) {
        
    }
}
// MARK: - Conforming `UIBarPositioning`.
extension NavigationBar {
    var barPosition: UIBarPosition { return .top }
}

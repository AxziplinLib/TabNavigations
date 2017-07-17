//
//  AppDelegateViewAppearance.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/14.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import AXPopoverView

extension AppDelegate {
    func setupUIAppearance() {
        _setupAXPopoverView()
    }
    
    private func _setupAXPopoverView() {
        AXPopoverView.appearance().animator = AXPopoverView.flipSpringAnimator()
        AXPopoverView.appearance().preferredArrowDirection = .top
        AXPopoverView.appearance().arrowConstant = 6.0
        AXPopoverView.appearance().offsets = CGPoint(x: 10.0, y: 10.0)
    }
}

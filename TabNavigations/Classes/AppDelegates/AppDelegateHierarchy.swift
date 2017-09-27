//
//  AppDelegateHierarchy.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import UserNotifications

extension AppDelegate {
    public var tabNavigationController: AxTabNavigationController? {
        return window?.rootViewController as? AxTabNavigationController
    }
    
    public func loadViewControllers() {
        tabNavigationController?.tabNavigationBar.isTranslucent = false
        tabNavigationController?.isTabNavigationItemsUpdatingDisabledInRootViewControllers = true
        tabNavigationController?.tabNavigationBar.navigationItems = [TabNavigationItem(title: "item")]
        let cities: [String] = ["BeiJing", "ShangHai", "ShenZhen", "GuangZhou", "ChengDu", "HongKong", "TaiWan", "LaSa", "KunMing", "GuiZhou", "HeFei", "ShiJiaZhuang"]
        for i in 0..<12 {
            let viewController = ViewController()
            viewController.setTabNavigationTitle(TabNavigationController.TabNavigationTitle(title: cities[i], selectedRange: 0..<3))
            tabNavigationController?.addViewController(viewController)
        }
        
        let settingsItem = TabNavigationTitleActionItem(title: "Settings", target: self, selector: #selector(_handleShowingSettingsViewController(_:)))
        settingsItem.tintColor = UIColor.application.blue
        tabNavigationController?.tabNavigationTitleActionItemsWhenPushed = [settingsItem]
        
        tabNavigationController?.tabNavigationBar.setSelectedTitle(at: 0, animated: false)
    }
    
    @objc
    private func _handleShowingSettingsViewController(_ sender: UIButton) {
        let settings = ViewController()
        settings.setTabNavigationTitle(TabNavigationController.TabNavigationTitle(title: "Settings"))
        tabNavigationController?.push(settings, animated: true)
    }
}

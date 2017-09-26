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
        
        for i in 0..<12 {
            let viewController = ViewController()
            viewController.setTabNavigationTitle(TabNavigationController.TabNavigationTitle(title: "H\(i)"))
            tabNavigationController?.addViewController(viewController)
        }
        
        let settingsItem = TabNavigationTitleActionItem(title: "设置", target: self, selector: #selector(_handleShowingSettingsViewController(_:)))
        settingsItem.tintColor = UIColor.application.blue
        tabNavigationController?.tabNavigationTitleActionItemsWhenPushed = [settingsItem]
        
        tabNavigationController?.tabNavigationBar.setSelectedTitle(at: 0, animated: false)
    }
    
    @objc
    private func _handleShowingSettingsViewController(_ sender: UIButton) {
        let settings = ViewController()
        settings.setTabNavigationTitle(TabNavigationController.TabNavigationTitle(title: "设置"))
        tabNavigationController?.push(settings, animated: true)
    }
}

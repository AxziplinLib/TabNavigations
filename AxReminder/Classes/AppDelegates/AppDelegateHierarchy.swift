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
        tabNavigationController?.addViewController(HomeViewController.instance(from: UIStoryboard(name: "Home", bundle: .main))!)
        tabNavigationController?.addViewController(CategoryViewController.instance(from: UIStoryboard(name: "Category", bundle: .main))!)
        
        let settingsItem = TabNavigationTitleActionItem(title: "设置", target: self, selector: #selector(_handleShowingSettingsViewController(_:)))
        settingsItem.tintColor = UIColor.application.blue
        tabNavigationController?.tabNavigationTitleActionItemsWhenPushed = [settingsItem]
        
        tabNavigationController?.tabNavigationBar.setSelectedTitle(at: 0, animated: false)
    }
    
    @objc
    private func _handleShowingSettingsViewController(_ sender: UIButton) {
        let settings = { () -> SettingsViewController in
            let settings = SettingsViewController.instance(from: UIStoryboard(name: "Settings", bundle: .main))!
            settings.title = "设置"
            return settings
        }()
        tabNavigationController?.push(settings, animated: true)
    }
}

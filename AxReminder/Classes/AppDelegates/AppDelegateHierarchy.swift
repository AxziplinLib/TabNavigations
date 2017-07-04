//
//  AppDelegateHierarchy.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

extension AppDelegate {
    public var tabNavigationController: TabNavigationController? {
        return window?.rootViewController as? TabNavigationController
    }
    
    public func loadViewControllers() {
        let home = { () -> HomeViewController in
            let home = HomeViewController.instance(from: UIStoryboard(name: "Home", bundle: .main))!
            home.title = "主页"
            return home
        }()
        home.tabNavigationItems = [TabNavigationItem(image: #imageLiteral(resourceName: "add")), TabNavigationItem(image: #imageLiteral(resourceName: "search"))]
        let category = { () -> CategoryViewController in
            let category = CategoryViewController.instance(from: UIStoryboard(name: "Category", bundle: .main))!
            category.title = "分类"
            return category
        }()
        category.tabNavigationItems = [TabNavigationItem(image: #imageLiteral(resourceName: "add"))]
        
        tabNavigationController?.addViewController(home)
        tabNavigationController?.addViewController(category)
        
        let settingsItem = TabNavigationTitleActionItem(title: "设置", target: self, selector: #selector(_handleShowingSettingsViewController(_:)))
        settingsItem.tintColor = UIColor.application.blue
        tabNavigationController?.tabNavigationBar.addNavigationTitleItem(settingsItem)
        
        tabNavigationController?.tabNavigationBar.setSelectedTitle(at: 0, animated: false)
    }
    
    @objc
    private func _handleShowingSettingsViewController(_ sender: UIButton) {
        print("Did click settings navigation title action item.")
    }
}

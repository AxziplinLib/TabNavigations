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
        
        let settingsItem = TabNavigationTitleActionItem(title: "显示", target: self, selector: #selector(_handleShowingSettingsViewController(_:)))
        settingsItem.tintColor = UIColor.application.blue
        let hidingItem = TabNavigationTitleActionItem(title: "隐藏", target: self, selector: #selector(_handleHidingSettingsViewController(_:)))
        hidingItem.tintColor = UIColor.application.blue
        tabNavigationController?.tabNavigationBar.addNavigationTitleItem(settingsItem)
        tabNavigationController?.tabNavigationBar.addNavigationTitleItem(hidingItem)
        
        tabNavigationController?.tabNavigationBar.setSelectedTitle(at: 0, animated: false)
    }
    
    @objc
    private func _handleShowingSettingsViewController(_ sender: UIButton) {
        let titleItem0 = TabNavigationTitleItem(title: "呵呵")
        let titleItem1 = TabNavigationTitleItem(title: "哈哈")
        let titleItems = [titleItem0, titleItem1]
        self.tabNavigationController?.tabNavigationBar.setNavigationTitleItems(titleItems, animated: true) /* { () -> (Bool, [TabNavigationTitleActionItem]?) in
            return (true, nil)
        } */
        self.tabNavigationController?.tabNavigationBar.showNavigationBackItem(true)
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { 
            let titleItem0 = TabNavigationTitleItem(title: "主页")
            let titleItem1 = TabNavigationTitleItem(title: "分类")
            let titleItems = [titleItem0, titleItem1]
            
            let settingsItem = TabNavigationTitleActionItem(title: "显示", target: self, selector: #selector(self._handleShowingSettingsViewController(_:)))
            settingsItem.tintColor = UIColor.application.blue
            let hidingItem = TabNavigationTitleActionItem(title: "隐藏", target: self, selector: #selector(self._handleHidingSettingsViewController(_:)))
            hidingItem.tintColor = UIColor.application.blue
            let actions = [settingsItem, hidingItem]
            
            self.tabNavigationController?.tabNavigationBar.setNavigationTitleItems(titleItems, animated: true) { () -> (Bool, [TabNavigationTitleActionItem]?) in
                return (false, actions)
            }
            
            self.tabNavigationController?.tabNavigationBar.hideNavigationBackItem(true)
        } */
    }
    @objc
    private func _handleHidingSettingsViewController(_ sender: UIButton) {
        let titleItem0 = TabNavigationTitleItem(title: "主页")
        let titleItem1 = TabNavigationTitleItem(title: "分类") 
        let titleItems = [titleItem0, titleItem1]
        self.tabNavigationController?.tabNavigationBar.setNavigationTitleItems(titleItems, animated: true)

        self.tabNavigationController?.tabNavigationBar.hideNavigationBackItem(true)
    }
}

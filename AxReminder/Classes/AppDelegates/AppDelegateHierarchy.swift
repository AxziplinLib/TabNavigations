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
        let item = TabNavigationTitleActionItem(title: "#工作#")
        item.tintColor = UIColor.red
        tabNavigationController?.tabNavigationBar.addNavigationTitleActionItem(item)
        
        let home = { () -> HomeViewController in
            let home = HomeViewController.instance(from: UIStoryboard(name: "Home", bundle: .main))!
            home.title = "主页测试"
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
//        let item1 = TabNavigationTitleActionItem(title: "#家庭#")
//        item1.tintColor = UIColor.red
        tabNavigationController?.addViewController({ () -> CategoryViewController in
            let category = CategoryViewController.instance(from: UIStoryboard(name: "Category", bundle: .main))!
            category.title = "设置"
            return category
            }())
        
//        tabNavigationController?.tabNavigationBar.addNavigationTitleActionItem(item1)
//        let item2 = TabNavigationTitleActionItem(title: "#生活#")
//        item2.tintColor = UIColor.red
//        tabNavigationController?.tabNavigationBar.addNavigationTitleActionItem(item2)
        
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [unowned self] in
            self.tabNavigationController?.tabNavigationBar.removeNavigationTitleActionItem(at: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned self] in
                self.tabNavigationController?.tabNavigationBar.removeLastNavigaitonTitleItem()
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned self] in
                    self.tabNavigationController?.tabNavigationBar.removeLastNavigaitonTitleItem()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned self] in
                        self.tabNavigationController?.tabNavigationBar.removeLastNavigaitonTitleItem()
                    }
                }
            }
        } */
        /*
        for index in 0...12 {
            tabNavigationController?.addViewController({ () -> CategoryViewController in
                let category = CategoryViewController.instance(from: UIStoryboard(name: "Category", bundle: .main))!
                if index % 2 == 0 {
                    category.title = "分类"
                } else {
                    category.title = "分类哈哈哈"
                }
                return category
                }())
        } */
//        var navigationItems: [TabNavigationItem] = []
//        let navigationItem = TabNavigationItem(title: "哈哈")
//        tabNavigationController?.tabNavigationBar.addNavigationItem(navigationItem)
//        for _ in 0...12 {
//            let _item = TabNavigationItem(title: "嘿嘿")
//            _item.tintColor = .red
//            navigationItems.append(_item)
//        }
        
        tabNavigationController?.tabNavigationBar.setSelectedTitle(at: 0, animated: false)
        /*
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [unowned self] in
            self.tabNavigationController?.tabNavigationBar.removeNavigationItem(at: 3)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned self] in
                self.tabNavigationController?.tabNavigationBar.removeNavigationItem(at: 8)
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned self] in
                    self.tabNavigationController?.tabNavigationBar.removeFirstNavigationItem()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned self] in
                        self.tabNavigationController?.tabNavigationBar.removeNavigationItem(at: 1)
                    }
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned self] in
            self.tabNavigationController?.tabNavigationBar.setNavigationItems(navigationItems, animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [unowned self] in
                navigationItems.removeLast(10)
                self.tabNavigationController?.tabNavigationBar.setNavigationItems([], animated: true)
            }
        } */
    }
    
}

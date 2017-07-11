//
//  HomeViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class HomeViewController: TableViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 100
    }
    
    override func viewDidLoadSetup() {
        super.viewDidLoadSetup()
        
        setTabNavigationTitle("主页")
        setTabNavigationItems([TabNavigationItem(image: #imageLiteral(resourceName: "add")), TabNavigationItem(image: #imageLiteral(resourceName: "navigation_search"))])
    }
}

// MARK: - UITableViewDataSource

extension HomeViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableViewCell.reusedIdentifier, for: indexPath) as! HomeTableViewCell
        
        return cell
    }
}

extension HomeViewController: StoryboardLoadable {
    public class func instance(from storyboard: UIStoryboard) -> Self? {
        return _instanceViewControllerFromStoryboard(storyboard)
    }
    // Private hooks.
    private class func _instanceViewControllerFromStoryboard<T>(_ storyboard: UIStoryboard) -> T? {
        return storyboard.instantiateInitialViewController() as? T
    }
}

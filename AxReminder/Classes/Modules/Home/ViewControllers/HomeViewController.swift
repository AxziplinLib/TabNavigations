//
//  HomeViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import YYText

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
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HomeTableViewCell.reusedIdentifier, for: indexPath) as! HomeTableViewCell
        cell.showsImageContent = false
        cell.showsTimingContent = false
        cell.showsLocationContent = false
        return cell
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont(name: "PingFangTC-Semibold", size: 14)
        label.textColor = UIColor.application.titleColor
        label.text = NSLocalizedString("Color_picking", comment: "pick color")
        let view = UIView()
        view.backgroundColor = .clear
        view.frame = CGRect(x: 0.0, y: 0.0, width: tableView.bounds.width, height: self.tableView(tableView, heightForHeaderInSection: section))
        
        view.addSubview(label)
        label.heightAnchor.constraint(equalToConstant: 20.0).isActive = true
        view.leadingAnchor.constraint(equalTo: label.leadingAnchor, constant: -15.0).isActive = true
        view.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: 20.0).isActive = true
        
        switch section {
        case 0:
            label.text = "紧急"
            return view
        case 1:
            label.text = "星标"
            return view
        case 2:
            label.text = "待办"
            return view
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 60.0
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
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

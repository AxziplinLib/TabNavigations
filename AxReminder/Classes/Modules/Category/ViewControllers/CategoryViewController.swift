//
//  CategoryViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class CategoryViewController: TableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidLoadSetup() {
        super.viewDidLoadSetup()
        
        setTabNavigationTitle("分类")
        setTabNavigationItems([TabNavigationItem(image: #imageLiteral(resourceName: "add"))])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension CategoryViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableViewCell.reusedIdentifier, for: indexPath) as! CategoryTableViewCell
        switch indexPath.section {
        case 0:
            cell.titleLabel.text = "工作"
            cell.frontGradientView.bringSubview(toFront: cell.titleLabel)
            cell.beginsColor = UIColor(hex: "C96DD8")
            cell.endsColor = UIColor(hex: "3023AE")
        case 1:
            cell.titleLabel.text = "家庭"
            cell.beginsColor = UIColor(hex: "B4ED50")
            cell.endsColor = UIColor(hex: "429321")
        case 2:
            cell.titleLabel.text = "旅游"
            cell.beginsColor = UIColor(hex: "FBDA61")
            cell.endsColor = UIColor(hex: "F76B1C")
        default:
            break
        }
        return cell
    }
}

extension CategoryViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20.0
    }
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == numberOfSections(in: tableView)-1 {
            return 10.0
        }
        return 0.01 
    }
}

extension CategoryViewController: StoryboardLoadable {
    public class func instance(from storyboard: UIStoryboard) -> Self? {
        return _instanceViewControllerFromStoryboard(storyboard)
    }
    // Private hooks.
    private class func _instanceViewControllerFromStoryboard<T>(_ storyboard: UIStoryboard) -> T? {
        return storyboard.instantiateInitialViewController() as? T
    }
}

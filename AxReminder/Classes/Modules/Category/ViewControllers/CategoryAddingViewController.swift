//
//  CategoryAddingViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/11.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class CategoryAddingViewController: TableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func viewDidLoadSetup() {
        super.viewDidLoadSetup()
        
        setTabNavigationTitle(["title": "添加分类", "range": 0..<2])
        let cancel = TabNavigationItem(title: "取消", target: self, selector: #selector(_handleCancelAction(_:)))
        cancel.tintColor = UIColor.application.red
        let complete = TabNavigationItem(title: "完成", target: self, selector: #selector(_handleCompleteAction(_:)))
        setTabNavigationItems([complete, cancel])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Actions.

extension CategoryAddingViewController {
    @objc
    fileprivate func _handleCancelAction(_ sender: UIButton) {
        self.tabNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc
    fileprivate func _handleCompleteAction(_ sender: UIButton) {
        self.tabNavigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - TableView Supporting.

extension CategoryAddingViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        default:
            return 3
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryAddingTextFieldTableViewCell.reusedIdentifier, for: indexPath) as! CategoryAddingTextFieldTableViewCell
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryAddingColorTableViewCell.reusedIdentifier, for: indexPath) as! CategoryAddingColorTableViewCell
            switch indexPath.row {
            case 0:
                cell.gradientColorView.beginsColor = UIColor(hex: "C96DD8")
                cell.gradientColorView.endsColor = UIColor(hex: "3023AE")
            case 1:
                cell.gradientColorView.beginsColor = UIColor(hex: "B4ED50")
                cell.gradientColorView.endsColor = UIColor(hex: "429321")
            case 2:
                cell.gradientColorView.beginsColor = UIColor(hex: "FBDA61")
                cell.gradientColorView.endsColor = UIColor(hex: "F76B1C")
            default:
                break
            }
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 40.0
        default:
            return 98.0
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 1:
            return 50.0
        default:
            return 20.0
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section != 0 else {
            return nil
        }
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
        view.topAnchor.constraint(equalTo: label.topAnchor, constant: -20.0).isActive = true
        
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
}

// MARK: - Storyboard Supporting.

extension CategoryAddingViewController {
    public class var storyboardId: String {
        return "_CategoryAddingViewController"
    }
}

extension CategoryAddingViewController: StoryboardLoadable {
    public class func instance(from storyboard: UIStoryboard) -> Self? {
        return _instanceViewControllerFromStoryboard(storyboard)
    }
    // Private hooks.
    private class func _instanceViewControllerFromStoryboard<T>(_ storyboard: UIStoryboard) -> T? {
        return storyboard.instantiateViewController(withIdentifier: storyboardId) as? T
    }
}

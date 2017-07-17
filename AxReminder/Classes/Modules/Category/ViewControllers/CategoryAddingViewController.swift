//
//  CategoryAddingViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/11.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import RealmSwift
import AXPracticalHUD

class CategoryAddingViewController: TableViewController {
    /// Header view.
    fileprivate var _headerView: UIView!
    /// Only text field.
    fileprivate weak var _textfield: UITextField?
    /// Scroll to top button.
    fileprivate var _backToTopButton: UIButton!
    
    /// Colors.
    fileprivate let _colors: [NSDictionary] = NSArray(contentsOfFile: Bundle.main.path(forResource: "Colors", ofType: "plist")!) as! [NSDictionary]

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
        
        _setupBackToTopButton()
        // Load data of table view.
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _showContentViews(animated)
        if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 1) > 0 {
            tableView.selectRow(at: IndexPath(row: 0, section: 1), animated: animated, scrollPosition: .none)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Animations.

extension CategoryAddingViewController {
    fileprivate func _showContentViews(_ animated: Bool) {
        guard animated else {
            return
        }
        let contentOffset = CGPoint(x: 0.0, y: -tableView.contentInset.top)
        var visibleCells = tableView.visibleCells as [UIView]
        visibleCells.insert(_headerView, at: 1)
        for (index, cell) in visibleCells.enumerated() {
            cell.transform = CGAffineTransform(translationX: 0.0, y: tableView.bounds.height)
            UIView.animate(withDuration: 0.5, delay: 0.05 * Double(index), usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [], animations: { [unowned self] in
                cell.transform = .identity
                self.tableView.contentOffset = contentOffset
            }, completion: nil)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05 * Double(visibleCells.count) / 2.0) { [unowned self] in
            self._textfield?.becomeFirstResponder()
        }
    }
}

// MARK: - Actions.

extension CategoryAddingViewController {
    @objc
    fileprivate func _handleCancelAction(_ sender: UIButton) {
        view.endEditing(true)
        self.tabNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc
    fileprivate func _handleCompleteAction(_ sender: UIButton) {
        view.endEditing(true)
        guard _textfield?.text?.lengthOfBytes(using: .utf8) ?? 0 > 0 else {
            AXPracticalHUD.shared().showText(in: tabNavigationController?.view, text: "请输入标题", detail: nil) { hud in
                hud?.lockBackground = true
            }
            AXPracticalHUD.shared().hide(true, afterDelay: 1.5) { [unowned self] in
                self._textfield?.becomeFirstResponder()
            }
            if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
                tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
            }
            return
        }
        guard tableView.indexPathForSelectedRow != nil else {
            AXPracticalHUD.shared().showText(in: tabNavigationController?.view, text: "请选择颜色", detail: nil) { hud in
                hud?.lockBackground = true
            }
            AXPracticalHUD.shared().hide(true, afterDelay: 1.5, completion: nil)
            return
        }
        // Insert the category object into realm database.
        let category = Category()
        category.id = Date().description
        category.title = _textfield?.text ?? ""
        let colorInfo = _colors[tableView.indexPathForSelectedRow!.row]
        let color = UIColor(hex: colorInfo.object(forKey: "color") as! String)
        let colors = _getColors(on: color)
        category.beginsColorHex = colors.begins.hexString()
        category.endsColorHex = colors.ends.hexString()
        AxRealmManager.default.synsWrites { realm in
            realm.add(category)
        }
        self.tabNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc
    fileprivate func _handleBackToTop(_ sender: UIButton) {
        tableView.scrollRectToVisible(CGRect(origin: .zero, size: CGSize(width: tableView.bounds.width, height: 1.0)), animated: true)
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
            return _colors.count
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryAddingTextFieldTableViewCell.reusedIdentifier, for: indexPath) as! CategoryAddingTextFieldTableViewCell
            _textfield = cell.textfield
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: CategoryAddingColorTableViewCell.reusedIdentifier, for: indexPath) as! CategoryAddingColorTableViewCell
            let colorInfo = _colors[indexPath.row]
            let color = UIColor(hex: colorInfo.object(forKey: "color") as! String)
            let colors = _getColors(on: color)
            
            cell.gradientColorView.beginsColor = colors.begins
            cell.gradientColorView.endsColor = colors.ends
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
        if _headerView == nil {
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
            
            _headerView = view
        }
        
        return _headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section != 0 else {
            return false
        }
        return true
    }
}

// MARK: - Private

extension CategoryAddingViewController {
    fileprivate func _getColors(on color: UIColor) -> (begins: UIColor, ends: UIColor) {
        let LAB = color.CIE_LAB()
        var lighterL: CGFloat
        var darkerL: CGFloat
        if LAB.l + 20.0 > 99.0 {
            lighterL = LAB.l
            darkerL = LAB.l - 30
        } else if LAB.l - 10.0 < 20.0 {
            lighterL = LAB.l + 30.0
            darkerL = LAB.l
        } else {
            lighterL = LAB.l + 20.0
            darkerL = LAB.l - 10.0
        }
        let lightColor = UIColor(CIE_LAB: (lighterL, LAB.a, LAB.b, LAB.alpha))
        let darkColor = UIColor(CIE_LAB: (darkerL, LAB.a, LAB.b, LAB.alpha))
        
        return (lightColor, darkColor)
    }
    
    fileprivate func _setupBackToTopButton() {
        guard let tabNavigationBar = tabNavigationController?.tabNavigationBar else {
            return
        }
        _backToTopButton = UIButton(type: .system)
        _backToTopButton.translatesAutoresizingMaskIntoConstraints = false
        _backToTopButton.setImage(#imageLiteral(resourceName: "back_to_top"), for: .normal)
        _backToTopButton.tintColor = UIColor.application.titleColor
        _backToTopButton.addTarget(self, action: #selector(_handleBackToTop(_:)), for: .touchUpInside)
        tabNavigationBar.addSubview(_backToTopButton)
        _backToTopButton.centerXAnchor.constraint(equalTo: tabNavigationBar.centerXAnchor).isActive = true
        _backToTopButton.widthAnchor.constraint(equalToConstant: 44.0).isActive = true
        _backToTopButton.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        _backToTopButton.lastBaselineAnchor.constraint(equalTo: tabNavigationBar.lastBaselineAnchor).isActive = true
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

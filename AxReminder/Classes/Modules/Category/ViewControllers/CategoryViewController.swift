//
//  CategoryViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import RealmSwift
import AXPopoverView

class CategoryViewController: TableViewController {
    fileprivate let _categories = Realm.default.objects(Category.self).sorted(byKeyPath: "atUpdation", ascending: false)
    fileprivate var _notificationToken: NotificationToken!

    deinit {
        _notificationToken.stop()
        _notificationToken = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        _notificationToken = _categories.addNotificationBlock { [weak self] change in
            switch change {
            case .initial( _):
                self?.tableView.reloadData()
            case .update( _, deletions: let deletedIndexes, insertions: let insertedIndexes, modifications: let modifiedIndexes):
                guard let _ = self?.tabNavigationController?.view.superview else {
                    self?.tableView.reloadData()
                    break
                }
                
                self?.tableView.beginUpdates()
                if !deletedIndexes.isEmpty {
                    for section in deletedIndexes {
                        self?.tableView.deleteSections(IndexSet(integer: section), with: .fade)
                    }
                }
                if !insertedIndexes.isEmpty {
                    for section in insertedIndexes {
                        self?.tableView.insertSections(IndexSet(integer: section), with: .fade)
                    }
                }
                for section in modifiedIndexes {
                    self?.tableView.reloadSections(IndexSet(integer: section), with: .fade)
                }
                self?.tableView.endUpdates()
            case .error(let error):
                print("Error occured: \(error)")
            }
        }
    }
    
    override func viewDidLoadSetup() {
        super.viewDidLoadSetup()
        
        setTabNavigationTitle("分类")
        setTabNavigationItems([TabNavigationItem(image: #imageLiteral(resourceName: "add"), target: self, selector: #selector(_handleAddingCategory(_:)))])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Actions.

extension CategoryViewController {
    @objc
    fileprivate func _handleAddingCategory(_ sender: UIButton) {
        let categoryAdding = CategoryAddingViewController.instance(from: UIStoryboard(name: "Category", bundle: .main))!
        let tabNavigationController = AxTabNavigationController()
        tabNavigationController.setViewControllers([categoryAdding])
        tabNavigationController.setSelectedViewController(at: 0, animated: false)
        self.present(tabNavigationController, animated: true, completion: nil)
    }
}

extension CategoryViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return _categories.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: CategoryTableViewCell.reusedIdentifier, for: indexPath) as! CategoryTableViewCell
        
        let category = _categories[indexPath.section]
        cell.titleLabel.text = category.title
        cell.beginsColor = UIColor(hex: category.beginsColorHex)
        cell.endsColor = UIColor(hex: category.endsColorHex)
        
        cell.settingHandler = { [unowned self] sender in
            AXPopoverView.showLabel(from: sender.imageView!, in: self.view, animated: true, duration: 10000.0, title: NSLocalizedString("PickHandler", comment: "Pick handler"), detail: " ", configuration: { (popoverView) in
                popoverView?.isTranslucent = true
                popoverView?.translucentStyle = .default
                popoverView?.isLockBackground = true
                popoverView?.isHideOnTouch = true
                popoverView?.titleTextColor = .white
                popoverView?.detailTextColor = .white
                popoverView?.indicatorColor = .white
                popoverView?.itemTintColor = .white
                popoverView?.preferredWidth = 150
                popoverView?.detailFont = UIFont.systemFont(ofSize: 9.0)
                let addItem = AXPopoverViewAdditionalButonItem()
                addItem.title = NSLocalizedString("AddStuff", comment: "add")
                let deleteItem = AXPopoverViewAdditionalButonItem()
                deleteItem.title = NSLocalizedString("Delete", comment: "delete")
                popoverView?.itemStyle = .vertical
                popoverView?.items = [addItem, deleteItem]
                popoverView?.itemHandler = { [unowned self] sender, index in
                    switch index {
                    case 0: break
                    case 1: break
                    case 2:
                    self._deleteCategory(at: indexPath)
                    popoverView?.hide(true, afterDelay: 0.01, completion: nil)
                    default: break
                    }
                }
            })
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

// MARK: - Deletion.

extension CategoryViewController {
    fileprivate func _deleteCategory(at indexPath: IndexPath) {
        let alert = UIAlertController(title: NSLocalizedString("Notice", comment: "Notice"), message: NSLocalizedString("DangerousDeleteHandler_Category", comment: "Delete alert"), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: "Confirm"), style: .destructive, handler: { [unowned self] (action) in
            let category = self._categories[indexPath.section]
            AxRealmManager.default.synsWrites { (realm) in
                realm.delete(category)
            }
        }))
        present(alert, animated: true, completion: nil)
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

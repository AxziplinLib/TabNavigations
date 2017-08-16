//
//  TableViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import AXResponderSchemaKit

class TableViewController: UITableViewController {
    fileprivate lazy var _backgroundFilterView: UIView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        viewDidLoadSetup()
        print(String(describing: type(of: self)) + "     " + #function)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        _backgroundFilterView.frame = CGRect(x: 0.0, y: min(0.0, tableView.contentOffset.y), width: tabNavigationController?.tabNavigationBar.bounds.width ?? 0.0, height: tabNavigationController?.tabNavigationBar.bounds.height ?? 0.0)
    }
    
    public func viewDidLoadSetup() {
        tableView.insertSubview(_backgroundFilterView, at: 0)
        _backgroundFilterView.backgroundColor = .white
        tabNavigationController?.tabNavigationBar.isTranslucent = true
    }
    
    override func viewWillBeginInteractiveTransition() {
        print(String(describing: type(of: self)) + "     " + #function)
    }
    
    override func viewDidEndInteractiveTransition(appearing: Bool) {
        print(String(describing: type(of: self)) + "     " + #function + "     " + String(describing: appearing))
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print(String(describing: type(of: self)) + "     " + #function + "     " + String(describing: animated))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print(String(describing: type(of: self)) + "     " + #function + "     " + String(describing: animated))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print(String(describing: type(of: self)) + "     " + #function + "     " + String(describing: animated))
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        print(String(describing: type(of: self)) + "     " + #function + "     " + String(describing: animated))
    }
    
    deinit {
        print(String(describing: type(of: self)) + "     " + #function)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - UITableViewDelegate.

extension TableViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20.0
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
}

// MARK: - Status Bar Supporting.

extension TableViewController {
    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
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

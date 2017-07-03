//
//  NavigationController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import AXResponderSchemaKit

class NavigationController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigationBarHidden(true, animated: false)
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Status Bar Supporting.
extension NavigationController {
    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

//
//  TabNavigationController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

private let DefaultTabNavigationBarHeight: CGFloat = 64.0

class TabNavigationController: ViewController {
    /// Tab navigation bar of the tab-navigation controller.
    public var tabNavigationBar: TabNavigationBar { return _tabNavigationBar }
    
    private lazy var _tabNavigationBar: TabNavigationBar = { () -> TabNavigationBar in
        let bar = TabNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = true
        return bar
    }()
    
    override func loadView() {
        super.loadView()
        
        _setupTabNavigationBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Private.
    private func _setupTabNavigationBar() {
        view.addSubview(_tabNavigationBar)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[_tabNavigationBar]|", options: [], metrics: nil, views: ["_tabNavigationBar":_tabNavigationBar]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[_tabNavigationBar(height)]", options: [], metrics: ["height":DefaultTabNavigationBarHeight], views: ["_tabNavigationBar":_tabNavigationBar]))
    }
}

// MARK: - Status Bar Supporting.
extension TabNavigationController {
    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

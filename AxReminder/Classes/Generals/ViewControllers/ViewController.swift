//
//  ViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var _navigationBar: TabNavigationBar?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        let navigationBar = TabNavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(navigationBar)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[navigationBar]|", options: [], metrics: nil, views: ["navigationBar":navigationBar]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[navigationBar(64)]", options: [], metrics: nil, views: ["navigationBar":navigationBar]))
        
        // navigationBar.title = "主页"
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "主页"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "分类"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "设置"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "随意"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "随意"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "随意"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "随意"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "随意"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "随意"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "随意"))
        navigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: "随意"))
        navigationBar.addNavigationItem(TabNavigationItem(image: #imageLiteral(resourceName: "add"), target: self, selector: #selector(_handleConfirm(_:))))
        navigationBar.addNavigationItem(TabNavigationItem(image: #imageLiteral(resourceName: "search"), target: self, selector: #selector(_handleConfirm(_:))))
        navigationBar.setSelectedTitle(at: 0, animated: false)
        _navigationBar = navigationBar
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            // self._navigationBar!.setSelectedTitle(at: 0, animated: true)
        // }
    }
    
    @objc
    func _handleConfirm(_ sender: AnyObject?) {
        print("Confirm")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Status Bar Supporting.
extension ViewController {
    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

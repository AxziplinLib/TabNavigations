//
//  ViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import AXResponderSchemaKit

protocol StoryboardLoadable: class {
    static func instance(from storyboard: UIStoryboard) -> Self?
}

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        print(String(describing: type(of: self)) + "     " + #function)
    }
    
    public func viewDidLoadSetup() {
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

// MARK: - Status Bar Supporting.
extension ViewController {
    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

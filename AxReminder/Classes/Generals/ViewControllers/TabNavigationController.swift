//
//  TabNavigationController.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import AXResponderSchemaKit

private let DefaultTabNavigationBarHeight: CGFloat = 64.0

protocol TabNavigationReadable: class {
    var tabNavigationController: TabNavigationController? { get }
    var tabNavigationItems: [TabNavigationItem] { get }
}

// MARK: Tab Navigation Controller.

extension UIViewController: TabNavigationReadable {
    private struct _TabNavigationControllerObjectKey {
        static var key = "_TabNavigationController"
    }
    
    fileprivate var _tabNavigationController: TabNavigationController? {
        get {
            return objc_getAssociatedObject(self, &_TabNavigationControllerObjectKey.key) as? TabNavigationController
        }
        set {
            objc_setAssociatedObject(self, &_TabNavigationControllerObjectKey.key, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
    }
    
    var tabNavigationController: TabNavigationController? { return _tabNavigationController }
}

// MARK: Navigation Items.

extension UIViewController {
    private struct _TabNavigationItemsObjectKey {
        static var key = "_TabNavigationItems"
    }
    
    public var tabNavigationItems: [TabNavigationItem] {
        get {
            if let _items = objc_getAssociatedObject(self, &_TabNavigationItemsObjectKey.key) {
                return _items as! [TabNavigationItem]
            }
            objc_setAssociatedObject(self, &_TabNavigationItemsObjectKey.key, [], .OBJC_ASSOCIATION_COPY_NONATOMIC)
            return objc_getAssociatedObject(self, &_TabNavigationItemsObjectKey.key) as! [TabNavigationItem]
        }
        set { objc_setAssociatedObject(self, &_TabNavigationItemsObjectKey.key, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
}

extension ViewController {
    override func removeFromParentViewController() {
        super.removeFromParentViewController()
        _tabNavigationController = nil
    }
}

extension TableViewController {
    override func removeFromParentViewController() {
        super.removeFromParentViewController()
        _tabNavigationController = nil
    }
}

extension TabNavigationController {
    public typealias TabNavigationItemViewsInfo = (index: Int, navigationItemViews: TabNavigationBar.TabNavigationItemViews?)
}

class TabNavigationController: ViewController {
    /// Tab navigation bar of the tab-navigation controller.
    public var tabNavigationBar: TabNavigationBar { return _tabNavigationBar }
    
    private weak var _trailingConstraintOflastViewController: NSLayoutConstraint?
    
    private lazy var _tabNavigationBar: TabNavigationBar = { () -> TabNavigationBar in
        let bar = TabNavigationBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        bar.backgroundColor = .white
        return bar
    }()
    
    fileprivate var _transitionNavigationItemViewsInfo: TabNavigationItemViewsInfo?
    
    fileprivate lazy var _contentScrollView: UIScrollView = { () -> UIScrollView in
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = UIColor.clear
        scrollView.decelerationRate = UIScrollViewDecelerationRateFast
        scrollView.isPagingEnabled = true
        return scrollView
    }()
    
    // MARK: - Overrides.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _initializer()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    private func _initializer() {
        tabNavigationBar.delegate = self
    }
    
    override func loadView() {
        super.loadView()
        
        _setupTabNavigationBar()
        _setupContentScrollView()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Public.
    
    public func addViewController<T>(_ viewController: T) where T: UIViewController, T: TabNavigationReadable {
        viewController._tabNavigationController = self
        
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        _contentScrollView.addSubview(viewController.view)
        _contentScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view":viewController.view]))
        viewController.view.leadingAnchor.constraint(equalTo: childViewControllers.last?.view.trailingAnchor ?? _contentScrollView.leadingAnchor).isActive = true
        if let _trailing = _trailingConstraintOflastViewController {
            _contentScrollView.removeConstraint(_trailing)
        }
        let _trailing = _contentScrollView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        _trailing.isActive = true
        _trailingConstraintOflastViewController = _trailing
        
        viewController.view.widthAnchor.constraint(equalTo: _contentScrollView.widthAnchor).isActive = true
        viewController.view.heightAnchor.constraint(equalTo: _contentScrollView.heightAnchor).isActive = true
        
        self.addChildViewController(viewController)
        viewController.didMove(toParentViewController: self)
        
        if let scrollView = viewController.view as? UIScrollView {
            scrollView.contentInset = UIEdgeInsets(top: DefaultTabNavigationBarHeight, left: 0.0, bottom: 0.0, right: 0.0)
        }
        
        viewController.beginAppearanceTransition(true, animated: false)
        viewController.endAppearanceTransition()
        
        _tabNavigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: viewController.title ?? ""))
    }
    @discardableResult
    public func removeViewController<T>(_ viewController: T) -> (Bool, UIViewController?) where T: UIViewController, T:TabNavigationReadable {
        guard let index = childViewControllers.index(of: viewController) else {
            return (false, nil)
        }
        
        return removeViewController(at: index)
    }
    @discardableResult
    public func removeViewController(at index: Array<UIViewController>.Index) -> (Bool, UIViewController?) {
        guard !childViewControllers.isEmpty else {
            return (false, nil)
        }
        
        guard index >= childViewControllers.startIndex && index < childViewControllers.endIndex else {
            return (false, nil)
        }
        
        let viewController = childViewControllers[index]
        viewController.willMove(toParentViewController: nil)
        viewController.removeFromParentViewController()
        
        viewController.beginAppearanceTransition(false, animated: false)
        viewController.view.removeFromSuperview()
        viewController.endAppearanceTransition()
        
        _tabNavigationBar.removeNavigaitonTitleItem(at: index)
        
        return (true, viewController)
    }
    
    // MARK: - Private.
    private func _setupTabNavigationBar() {
        view.addSubview(_tabNavigationBar)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[_tabNavigationBar]|", options: [], metrics: nil, views: ["_tabNavigationBar":_tabNavigationBar]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[_tabNavigationBar(==height)]", options: [], metrics: ["height":DefaultTabNavigationBarHeight], views: ["_tabNavigationBar":_tabNavigationBar]))
    }
    
    private func _setupContentScrollView() {
        _contentScrollView.delegate = self
        view.insertSubview(_contentScrollView, at: 0)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[_contentScrollView]|", options: [], metrics: nil, views: ["_contentScrollView":_contentScrollView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[_contentScrollView]|", options: [], metrics: nil, views: ["_contentScrollView":_contentScrollView]))
        _contentScrollView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        _contentScrollView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
    }
}

// MARK: - TabNavigationBarDelegate.

extension TabNavigationController: TabNavigationBarDelegate {
    func tabNavigationBar(_ tabNavigationBar: TabNavigationBar, didSelectTitleItemAt index: Int) {
        guard index >= childViewControllers.startIndex && index < childViewControllers.endIndex else {
            return
        }
        
        let _selectedViewController = childViewControllers[index]
        
        _contentScrollView.scrollRectToVisible(_selectedViewController.view.frame, animated: true)
        
        _selectedViewController.beginAppearanceTransition(true, animated: true)
        tabNavigationBar.setNavigationItems(_selectedViewController.tabNavigationItems, animated: true)
        _selectedViewController.endAppearanceTransition()
    }
}

// MARK: - UIScrollViewDelegate.

extension TabNavigationController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        _commitTransitionNavigationItemViews(at: Int(scrollView.contentOffset.x / scrollView.bounds.width))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.isDragging || scrollView.isDecelerating {
            let index = Int(scrollView.contentOffset.x / scrollView.bounds.width)
            
            if index < childViewControllers.index(before: childViewControllers.endIndex)
            && scrollView.contentOffset.x >= 0
            && scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.bounds.width) != 0.0
            {
                let showingIndex = childViewControllers.index(after: index)
                let viewController = childViewControllers[showingIndex]
                
                let formerViewController = childViewControllers[index]
                let transitionNavigationItemViews = tabNavigationBar.beginTransitionNavigationItems(viewController.tabNavigationItems, on: formerViewController.tabNavigationItems, in: _transitionNavigationItemViewsInfo?.navigationItemViews)
                
                _transitionNavigationItemViewsInfo = (showingIndex, transitionNavigationItemViews)
            }
            
            tabNavigationBar.setNestedScrollViewContentOffset(scrollView.contentOffset, contentSize: scrollView.contentSize, bounds: scrollView.bounds, transition: _transitionNavigationItemViewsInfo?.navigationItemViews)
        }
    }
    
    private func _commitTransitionNavigationItemViews(at index: Int) {
        if let info = _transitionNavigationItemViewsInfo {
            if info.index == index {
                let viewController = childViewControllers[index]
                tabNavigationBar.commitTransitionNavigatiomItemViews(info.navigationItemViews, navigationItems: viewController.tabNavigationItems, success: true)
            } else {
                tabNavigationBar.commitTransitionNavigatiomItemViews(info.navigationItemViews, navigationItems: [], success: false)
            }
            _transitionNavigationItemViewsInfo = nil
        }
    }
}

// MARK: - Status Bar Supporting.
extension TabNavigationController {
    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

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

private func _createGeneralPagingScrollView() -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.backgroundColor = UIColor.clear
    scrollView.decelerationRate = UIScrollViewDecelerationRateFast
    scrollView.isPagingEnabled = true
    return scrollView
}

private func _createGeneralTabNavigationBar() -> TabNavigationBar {
    let bar = TabNavigationBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    bar.backgroundColor = .white
    return bar
}

class TabNavigationController: ViewController {
    /// Tab navigation bar of the tab-navigation controller.
    public var tabNavigationBar: TabNavigationBar { return _tabNavigationBar }
    lazy
    private var _tabNavigationBar: TabNavigationBar = _createGeneralTabNavigationBar()
    
    private weak var _trailingConstraintOflastViewController: NSLayoutConstraint?
    
    fileprivate var _transitionNavigationItemViewsInfo: TabNavigationItemViewsInfo?
    lazy
    fileprivate var _contentScrollView: UIScrollView = _createGeneralPagingScrollView()
    
    fileprivate var _rootViewControllersInfo: (selectedIndex: Array<UIViewController>.Index, viewControllers: [UIViewController]) = (0, [])
    fileprivate var _viewControllersStack: [UIViewController] = []
    fileprivate var _headOfViewControllersStack: Array<UIViewController>.Index = 0
    
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
    
    fileprivate func _addViewControllerWithoutUpdatingNavigationTitle(_ viewController: UIViewController) {
        viewController._tabNavigationController = self
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.addChildViewController(viewController)
        _contentScrollView.addSubview(viewController.view)
        _contentScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view":viewController.view]))
        viewController.view.leadingAnchor.constraint(equalTo: _rootViewControllersInfo.viewControllers.last?.view.trailingAnchor ?? _contentScrollView.leadingAnchor).isActive = true
        if let _trailing = _trailingConstraintOflastViewController {
            _contentScrollView.removeConstraint(_trailing)
        }
        let _trailing = _contentScrollView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        _trailing.isActive = true
        _trailingConstraintOflastViewController = _trailing
        
        viewController.view.widthAnchor.constraint(equalTo: _contentScrollView.widthAnchor).isActive = true
        viewController.view.heightAnchor.constraint(equalTo: _contentScrollView.heightAnchor).isActive = true
        
        _rootViewControllersInfo.viewControllers.append(viewController)
        viewController.didMove(toParentViewController: self)
        
        if let scrollView = viewController.view as? UIScrollView {
            scrollView.contentInset = UIEdgeInsets(top: DefaultTabNavigationBarHeight, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
    
    fileprivate func _addChildViewController(_ viewController: UIViewController, below: UIView) {
        viewController._tabNavigationController = self
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(viewController)
        if view.subviews.contains(below) {
            view.insertSubview(viewController.view, belowSubview: below)
        } else {
            view.addSubview(viewController.view)
        }
        if viewController.view is UIScrollView {
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": viewController.view]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": viewController.view]))
            viewController.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            viewController.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
            (viewController.view as! UIScrollView).contentInset = UIEdgeInsets(top: DefaultTabNavigationBarHeight, left: 0.0, bottom: 0.0, right: 0.0)
        } else {
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": viewController.view]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-height-[view]|", options: [], metrics: ["height": DefaultTabNavigationBarHeight], views: ["view": viewController.view]))
        }
        viewController.didMove(toParentViewController: self)
    }
    
    private func _setViewControllersWithoutUpdatingNavigationItems(_ viewControllers: [UIViewController]) {
        
    }
}

extension TabNavigationController {
    // MARK: - Public.
    // MARK: Tab view controllers.
    
    public func setViewControllers<T>(_ viewControllers: Array<T>, animated: Bool) where T: UIViewController, T: TabNavigationReadable {
        // FIXME:Imp the function.
    }
    
    public func addViewController<T>(_ viewController: T) where T: UIViewController, T: TabNavigationReadable {
        _addViewControllerWithoutUpdatingNavigationTitle(viewController)
        tabNavigationBar.addNavigationTitleItem(TabNavigationTitleItem(title: viewController.title ?? ""))
    }
    @discardableResult
    public func removeViewController<T>(_ viewController: T) -> (Bool, UIViewController?) where T: UIViewController, T:TabNavigationReadable {
        guard let index = _rootViewControllersInfo.viewControllers.index(of: viewController) else {
            return (false, nil)
        }
        
        return removeViewController(at: index)
    }
    @discardableResult
    public func removeFirstViewController() -> (Bool, UIViewController?) {
        guard !_rootViewControllersInfo.viewControllers.isEmpty else {
            return (false, nil)
        }
        
        return removeViewController(at: _rootViewControllersInfo.viewControllers.startIndex)
    }
    @discardableResult
    public func removeLastViewController() -> (Bool, UIViewController?) {
        guard !_rootViewControllersInfo.viewControllers.isEmpty else {
            return (false, nil)
        }
        
        return removeViewController(at: _rootViewControllersInfo.viewControllers.index(before: _rootViewControllersInfo.viewControllers.endIndex))
    }
    @discardableResult
    public func removeViewController(at index: Array<UIViewController>.Index) -> (Bool, UIViewController?) {
        guard !_rootViewControllersInfo.viewControllers.isEmpty else {
            return (false, nil)
        }
        
        guard index >= _rootViewControllersInfo.viewControllers.startIndex && index < _rootViewControllersInfo.viewControllers.endIndex else {
            return (false, nil)
        }
        
        let viewController = _rootViewControllersInfo.viewControllers[index]
        viewController.willMove(toParentViewController: nil)
        viewController.removeFromParentViewController()
        
        viewController.beginAppearanceTransition(false, animated: false)
        viewController.view.removeFromSuperview()
        viewController.endAppearanceTransition()
        
        tabNavigationBar.removeNavigaitonTitleItem(at: index)
        
        return (true, viewController)
    }
    
    // MARK: Navigation controllers.
    
    public func push(_ viewController: UIViewController, animated: Bool) {
        viewController._tabNavigationController = self
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        // Add to child view controllers.
        addChildViewController(viewController)
        if _viewControllersStack.isEmpty {
            tabNavigationBar.showNavigationBackItem(animated)
            // Record the selected index of the root view controllers.
            _rootViewControllersInfo.selectedIndex = tabNavigationBar.selectedIndex
        }
        _viewControllersStack.append(viewController)
        _headOfViewControllersStack = _viewControllersStack.index(before: _viewControllersStack.endIndex)
        view.insertSubview(viewController.view, belowSubview: tabNavigationBar)
        
        if viewController.view is UIScrollView {
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": viewController.view]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view": viewController.view]))
            viewController.view.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
            viewController.view.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
            (viewController.view as! UIScrollView).contentInset = UIEdgeInsets(top: DefaultTabNavigationBarHeight, left: 0.0, bottom: 0.0, right: 0.0)
        } else {
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": viewController.view]))
            view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-height-[view]|", options: [], metrics: ["height": DefaultTabNavigationBarHeight], views: ["view": viewController.view]))
        }
        
        view.setNeedsLayout()
        view.layoutIfNeeded()
        viewController.didMove(toParentViewController: self)
        // Update items.
        let duration: TimeInterval = 0.5
        let titleItems = [TabNavigationTitleItem(title: viewController.title ?? "")]
        tabNavigationBar.setNavigationTitleItems(titleItems, animated: animated, actionsConfig: { () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
            return (true, nil)
        }) { animationParameters in
            if animated {
                let toTransform = animationParameters.toItemViews.itemsView.transform
                let fromTransform = animationParameters.fromItemViews.itemsView.transform
                
                let translation = min(animationParameters.fromItemViews.itemsView.bounds.width - animationParameters.fromItemViews.alignmentContentView.bounds.width, animationParameters.containerView.bounds.width) - animationParameters.fromItemViews.itemsScrollView.contentOffset.x
                
                animationParameters.toItemViews.itemsView.transform = CGAffineTransform(translationX: translation, y: 0.0)
                animationParameters.toItemViews.itemsView.alpha = 0.0
                
                UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    animationParameters.toItemViews.itemsView.transform = toTransform
                    animationParameters.toItemViews.itemsView.alpha = 1.0
                    animationParameters.fromItemViews.itemsView.alpha = 0.0
                    animationParameters.fromItemViews.itemsView.transform = CGAffineTransform(translationX: -translation, y: 0.0)
                }, completion: { [unowned self] finished in
                    if finished {
                        animationParameters.fromItemViews.itemsView.transform = fromTransform
                        animationParameters.fromItemViews.itemsView.alpha = 1.0
                        self.tabNavigationBar.commitTransitionTitleItemViews(animationParameters.toItemViews, items: titleItems)
                    }
                })
            }
        }
        tabNavigationBar.setNavigationItems(viewController.tabNavigationItems, animated: animated)
        // Prepare to remove root view controllers.
        for _viewController in _rootViewControllersInfo.viewControllers {
            _viewController.willMove(toParentViewController: nil)
        }
        
        if animated {
            let transform = viewController.view.transform
            viewController.view.transform = CGAffineTransform(translationX: view.bounds.width, y: 0.0)
            for _viewController in _rootViewControllersInfo.viewControllers {
                _viewController.beginAppearanceTransition(false, animated: animated)
            }
            let clipsToBounds = viewController.view.clipsToBounds
            
            viewController.view.clipsToBounds = false
            viewController.view.layer.shadowColor = UIColor.lightGray.cgColor
            viewController.view.layer.shadowOffset = CGSize(width: -4.0, height: 0.0)
            let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
            shadowOpacityAnimation.fromValue = 0.0
            shadowOpacityAnimation.toValue = 0.5
            shadowOpacityAnimation.duration = duration / 2.0
            shadowOpacityAnimation.isRemovedOnCompletion = true
            shadowOpacityAnimation.fillMode = kCAFillModeForwards
            viewController.view.layer.removeAnimation(forKey: "shadowOpacity")
            viewController.view.layer.add(shadowOpacityAnimation, forKey: "shadowOpacity")
            
            viewController.beginAppearanceTransition(true, animated: animated)
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                viewController.view.transform = transform
            }, completion: { [unowned self] finished in
                if finished {
                    viewController.endAppearanceTransition()
                    viewController.view.clipsToBounds = clipsToBounds
                    for _viewController in self._rootViewControllersInfo.viewControllers {
                        _viewController.view.removeFromSuperview()
                        _viewController.endAppearanceTransition()
                        _viewController.removeFromParentViewController()
                        _viewController.didMove(toParentViewController: nil)
                    }
                }
            })
        } else {
            for _viewController in _rootViewControllersInfo.viewControllers {
                _viewController.beginAppearanceTransition(false, animated: false)
                _viewController.view.removeFromSuperview()
                _viewController.endAppearanceTransition()
                _viewController.removeFromParentViewController()
                _viewController.didMove(toParentViewController: nil)
            }
            viewController.beginAppearanceTransition(true, animated: false)
            viewController.endAppearanceTransition()
        }
    }
    
    public func popToRootViewControllers(animated: Bool) {
        //FIXME: Imp.
    }
    
    public func pop(to viewController: UIViewController? = nil, animated: Bool) {
        guard !_viewControllersStack.isEmpty else {
            return
        }
        var formerViewController: UIViewController
        if let _viewController = viewController {
            if _viewControllersStack.contains(_viewController) {
                formerViewController = _viewController
            } else {
                return
            }
        } else if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {// Count == 1
            formerViewController = _rootViewControllersInfo.viewControllers[_rootViewControllersInfo.selectedIndex]
        } else {
            formerViewController = _viewControllersStack[_viewControllersStack.index(_viewControllersStack.endIndex, offsetBy: -2)]
        }
        
        var navigationTitleItems: [TabNavigationTitleItem] = []
        let _removingViewController = _viewControllersStack.last!
        // Add former view controllers.
        if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {
            let rootViewControllers = _rootViewControllersInfo.viewControllers
            _rootViewControllersInfo.viewControllers.removeAll()
            for _vc in rootViewControllers {
                _addViewControllerWithoutUpdatingNavigationTitle(_vc)
                navigationTitleItems.append(TabNavigationTitleItem(title: _vc.title ?? ""))
            }
            tabNavigationBar.hideNavigationBackItem(animated)
        } else {
            navigationTitleItems = [TabNavigationTitleItem(title: formerViewController.title ?? "")]
            _addChildViewController(formerViewController, below: _removingViewController.view)
        }
        
        // Update navigation items.
        let duration: TimeInterval = 0.25
        
        tabNavigationBar.setNavigationTitleItems(navigationTitleItems, animated: animated, selectedIndex: _rootViewControllersInfo.selectedIndex, actionsConfig: { [unowned self] () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
            return (false, self.tabNavigationBar.navigationTitleActionItems)
        }) { animationParameters in
            if animated {
                let toTransform = animationParameters.toItemViews.itemsView.transform
                let fromTransform = animationParameters.fromItemViews.itemsView.transform
                
                let translation = min(animationParameters.toItemViews.itemsView.bounds.width - animationParameters.toItemViews.alignmentContentView.bounds.width, animationParameters.containerView.bounds.width) - animationParameters.toItemViews.itemsScrollView.contentOffset.x
                
                animationParameters.toItemViews.itemsView.alpha = 0.0
                animationParameters.toItemViews.itemsView.transform = CGAffineTransform(translationX: -translation, y: 0.0)
                UIView.animate(withDuration: duration * 2.0, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.8, options: [], animations: {
                    animationParameters.toItemViews.itemsView.transform = toTransform
                    animationParameters.toItemViews.itemsView.alpha = 1.0
                    animationParameters.fromItemViews.itemsView.alpha = 0.0
                    animationParameters.fromItemViews.itemsView.transform = CGAffineTransform(translationX: translation, y: 0.0)
                }, completion: { [unowned self] finished in
                    if finished {
                        animationParameters.fromItemViews.itemsView.transform = fromTransform
                        animationParameters.fromItemViews.itemsView.alpha = 1.0
                        self.tabNavigationBar.commitTransitionTitleItemViews(animationParameters.toItemViews, items: navigationTitleItems)
                    }
                })
            }
        }
        tabNavigationBar.setNavigationItems(formerViewController.tabNavigationItems, animated: animated)
        
        _removingViewController.willMove(toParentViewController: nil)
        
        if animated {
            let transform = _removingViewController.view.transform
            let clipsToBounds = _removingViewController.view.clipsToBounds
            
            _removingViewController.view.clipsToBounds = false
            _removingViewController.view.layer.shadowColor = UIColor.lightGray.cgColor
            _removingViewController.view.layer.shadowOffset = CGSize(width: -4.0, height: 0.0)
            let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
            shadowOpacityAnimation.fromValue = 0.5
            shadowOpacityAnimation.toValue = 0.0
            shadowOpacityAnimation.duration = duration
            shadowOpacityAnimation.isRemovedOnCompletion = true
            shadowOpacityAnimation.fillMode = kCAFillModeForwards
            _removingViewController.view.layer.removeAnimation(forKey: "shadowOpacity")
            _removingViewController.view.layer.add(shadowOpacityAnimation, forKey: "shadowOpacity")
            
            _removingViewController.beginAppearanceTransition(false, animated: animated)
            UIView.animate(withDuration: duration, delay: 0.0, options: [.curveEaseOut], animations: {
                _removingViewController.view.transform = CGAffineTransform(translationX: _removingViewController.view.bounds.width, y: 0.0)
            }, completion: { [unowned self] finished in
                if finished {
                    _removingViewController.view.removeFromSuperview()
                    _removingViewController.endAppearanceTransition()
                    _removingViewController.removeFromParentViewController()
                    _removingViewController.didMove(toParentViewController: nil)
                    _removingViewController._tabNavigationController = nil
                    _removingViewController.view.transform = transform
                    _removingViewController.view.clipsToBounds = clipsToBounds
                    self._viewControllersStack.removeLast()
                }
            })
        } else {
            _removingViewController.beginAppearanceTransition(false, animated: false)
            _removingViewController.view.removeFromSuperview()
            _removingViewController.endAppearanceTransition()
            _removingViewController.removeFromParentViewController()
            _removingViewController.didMove(toParentViewController: nil)
            _removingViewController._tabNavigationController = nil
            _viewControllersStack.removeLast()
        }
    }
}

// MARK: - TabNavigationBarDelegate.

extension TabNavigationController: TabNavigationBarDelegate {
    func tabNavigationBar(_ tabNavigationBar: TabNavigationBar, didSelectTitleItemAt index: Int) {
        guard _viewControllersStack.isEmpty else {
            return
        }
        guard index >= _rootViewControllersInfo.viewControllers.startIndex && index < _rootViewControllersInfo.viewControllers.endIndex else {
            return
        }
        
        let _selectedViewController = _rootViewControllersInfo.viewControllers[index]
        
        _contentScrollView.scrollRectToVisible(_selectedViewController.view.frame, animated: true)
        
        _selectedViewController.beginAppearanceTransition(true, animated: true)
        tabNavigationBar.setNavigationItems(_selectedViewController.tabNavigationItems, animated: true)
        _selectedViewController.endAppearanceTransition()
    }
    
    func tabNavigationBarDidTouchNavigatiomBackItem(_ tabNavigationBar: TabNavigationBar) {
        pop(animated: true)
    }
}

// MARK: - UIScrollViewDelegate.

extension TabNavigationController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard _viewControllersStack.isEmpty else {
            return
        }
        _commitTransitionNavigationItemViews(at: Int(scrollView.contentOffset.x / scrollView.bounds.width))
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard _viewControllersStack.isEmpty else {
            return
        }
        if scrollView.isDragging || scrollView.isDecelerating {
            let index = Int(scrollView.contentOffset.x / scrollView.bounds.width)
            
            if index < _rootViewControllersInfo.viewControllers.index(before: _rootViewControllersInfo.viewControllers.endIndex)
            && scrollView.contentOffset.x >= 0
            && scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.bounds.width) != 0.0
            {
                let showingIndex = _rootViewControllersInfo.viewControllers.index(after: index)
                let viewController = _rootViewControllersInfo.viewControllers[showingIndex]
                
                let formerViewController = _rootViewControllersInfo.viewControllers[index]
                let transitionNavigationItemViews = tabNavigationBar.beginTransitionNavigationItems(viewController.tabNavigationItems, on: formerViewController.tabNavigationItems, in: _transitionNavigationItemViewsInfo?.navigationItemViews)
                
                _transitionNavigationItemViewsInfo = (showingIndex, transitionNavigationItemViews)
            }
            
            tabNavigationBar.setNestedScrollViewContentOffset(scrollView.contentOffset, contentSize: scrollView.contentSize, bounds: scrollView.bounds, transition: _transitionNavigationItemViewsInfo?.navigationItemViews)
        }
    }
    
    private func _commitTransitionNavigationItemViews(at index: Int) {
        if let info = _transitionNavigationItemViewsInfo {
            if info.index == index {
                let viewController = _rootViewControllersInfo.viewControllers[index]
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

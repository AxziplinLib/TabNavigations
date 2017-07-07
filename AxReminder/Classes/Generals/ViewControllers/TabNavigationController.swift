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
    var tabNavigationTitleActionItemsWhenPushed: [TabNavigationTitleActionItem] { get }
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

// MARK: Navigation Title Action Items.

extension UIViewController {
    private struct _TabNavigationTitleActionItemsObjectKey {
        static var key = "_TabNavigationTitleActionItems"
    }
    
    public var tabNavigationTitleActionItemsWhenPushed: [TabNavigationTitleActionItem] {
        get {
            if let _items = objc_getAssociatedObject(self, &_TabNavigationTitleActionItemsObjectKey.key) {
                return _items as! [TabNavigationTitleActionItem]
            }
            objc_setAssociatedObject(self, &_TabNavigationTitleActionItemsObjectKey.key, [], .OBJC_ASSOCIATION_COPY_NONATOMIC)
            return objc_getAssociatedObject(self, &_TabNavigationTitleActionItemsObjectKey.key) as! [TabNavigationTitleActionItem]
        }
        set { objc_setAssociatedObject(self, &_TabNavigationTitleActionItemsObjectKey.key, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
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
    public var tabNavigationTitleActionItems: [TabNavigationTitleActionItem] = [] {
        didSet {
            tabNavigationBar.navigationTitleActionItems = tabNavigationTitleActionItems
        }
    }
    override public var tabNavigationTitleActionItemsWhenPushed: [TabNavigationTitleActionItem] {
        get { return tabNavigationTitleActionItems }
        set { tabNavigationTitleActionItems = newValue }
    }
    
    lazy
    private var _tabNavigationBar: TabNavigationBar = _createGeneralTabNavigationBar()
    
    public var interactivePopGestureRecognizer: UIPanGestureRecognizer { return _panGestureRecognizer }
    fileprivate var _panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var _panGestureBeginsLocation: CGPoint = .zero
    fileprivate var _panGestureBeginsClips: Bool = true
    fileprivate var _panGestureBeginsTransform: (former: CGAffineTransform, top: CGAffineTransform) = (.identity, .identity)
    fileprivate var _panGestureBeginsTitleItems: [TabNavigationTitleItem] = []
    
    fileprivate var _transitionNavigationBarViews: TabNavigationBar.TabNavigationTransitionContext?
    fileprivate var _panGestureBeginsItemViewsTransform: (fromTransform: CGAffineTransform, toTransform: CGAffineTransform) = (.identity, .identity)
    
    public var topViewController: UIViewController? {
        return _viewControllersStack.last ?? { () -> UIViewController? in
            guard !_rootViewControllersInfo.viewControllers.isEmpty && _rootViewControllersInfo.selectedIndex >= _rootViewControllersInfo.viewControllers.startIndex && _rootViewControllersInfo.selectedIndex < _rootViewControllersInfo.viewControllers.endIndex else {
                return nil
            }
            return _rootViewControllersInfo.viewControllers[_rootViewControllersInfo.selectedIndex]
        }()
    }
    
    private weak var _trailingConstraintOfLastViewController: NSLayoutConstraint?
    
    fileprivate var _transitionNavigationItemViewsInfo: TabNavigationItemViewsInfo?
    lazy
    fileprivate var _contentScrollView: UIScrollView = _createGeneralPagingScrollView()
    
    fileprivate var _rootViewControllersInfo: (selectedIndex: Array<UIViewController>.Index, viewControllers: [UIViewController]) = (0, [])
    fileprivate var _viewControllersStack: [UIViewController] = []
    
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
        _panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(_handePanGestureRecognizer(_:)))
        _panGestureRecognizer.isEnabled = false
    }
    
    override func loadView() {
        super.loadView()
        
        view.addGestureRecognizer(_panGestureRecognizer)
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
    
    // MARK: - Actions.
    
    @objc
    private func _handePanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .possible: fallthrough
        case .began:
            _panGestureBeginsLocation = sender.location(in: view)
            
            guard let _topViewController = topViewController else { break }
            let _formerViewController = _formerViewControllerForPop()!
            
            var actionsWhenPushed: [TabNavigationTitleActionItem] = []
            if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {
                actionsWhenPushed = tabNavigationTitleActionItemsWhenPushed
            } else {
                actionsWhenPushed = _formerViewController.tabNavigationTitleActionItemsWhenPushed
            }
            _panGestureBeginsTitleItems = _fetchFormerNavigationTitleItemsAndSetupViewControllersIfNecessary(former: _formerViewController)
            
            _panGestureBeginsTransform = (_formerViewController.view.transform, _topViewController.view.transform)
            _panGestureBeginsClips = _topViewController.view.clipsToBounds
            
            _transitionNavigationBarViews = tabNavigationBar.beginTransitionNavigationTitleItems(_panGestureBeginsTitleItems, actionsConfig: { () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
                return (false, actionsWhenPushed)
            }, navigationItems: _formerViewController.tabNavigationItems)
            _transitionNavigationBarViews?.titleViews.toItemViews.itemsView.alpha = 0.0
            _panGestureBeginsItemViewsTransform = (_transitionNavigationBarViews!.titleViews.fromItemViews.itemsView.transform, _transitionNavigationBarViews!.titleViews.toItemViews.itemsView.transform)
        case .changed:
            let location = sender.location(in: view)
            let transitionPercent = max(0.0, location.x - _panGestureBeginsLocation.x) / view.bounds.width
            
            guard let _topViewController = topViewController else { break }
            let _formerViewController = _formerViewControllerForPop()!
            
            _topViewController.view.transform = CGAffineTransform(translationX: transitionPercent * _topViewController.view.bounds.width, y: 0.0)
            _formerViewController.view.transform = CGAffineTransform(translationX: -(1.0-transitionPercent) * _formerViewController.view.bounds.width / 2.0, y: 0.0)
            _topViewController.view.clipsToBounds = false
            _setupTransitionShadowOfViewController(_topViewController)
            _topViewController.view.layer.shadowOpacity = Float(1.0-transitionPercent) * Float(0.5)
            
            _transitionTabNavigationBarWithPercent(transitionPercent, transition: _transitionNavigationBarViews)
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .ended:
            let location = sender.location(in: view)
            let velocity = sender.velocity(in: view)
            let translation = sender.translation(in: view)
            // print("Velocity: \(velocity), Translation: \(translation)")

            let transitionPercent = max(0.0, location.x - _panGestureBeginsLocation.x) / view.bounds.width
            
            let _formerViewController = _formerViewControllerForPop()!
            let shouldCommitTransition = (transitionPercent >= 0.5 || velocity.x > translation.x * 5.0)
            
            _commitTransitionOfNavigationTitleItems(_panGestureBeginsTitleItems, navigationItems: _formerViewController.tabNavigationItems, transition: _transitionNavigationBarViews, success: shouldCommitTransition)
            
            guard let _topViewController = topViewController else { break }
            
            if shouldCommitTransition {
                let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
                shadowOpacityAnimation.toValue = 0.0
                shadowOpacityAnimation.isRemovedOnCompletion = true
                shadowOpacityAnimation.duration = 0.25
                shadowOpacityAnimation.fillMode = kCAFillModeForwards
                _topViewController.view.layer.removeAnimation(forKey: "shadowOpacity")
                _topViewController.view.layer.add(shadowOpacityAnimation, forKey: "shadowOpacity")
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseIn], animations: { [unowned self] in
                    _topViewController.view.transform = CGAffineTransform(translationX: _topViewController.view.bounds.width, y: 0.0)
                    _formerViewController.view.transform = self._panGestureBeginsTransform.former
                }, completion: { [unowned self] finished in
                    _topViewController.view.transform = self._panGestureBeginsTransform.top
                    _topViewController.view.clipsToBounds = self._panGestureBeginsClips
                    self._popViewController(ignoreBar: true, animated: false)
                })
            } else {
                let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
                shadowOpacityAnimation.toValue = 0.5
                shadowOpacityAnimation.isRemovedOnCompletion = true
                shadowOpacityAnimation.duration = 0.25
                shadowOpacityAnimation.fillMode = kCAFillModeForwards
                _topViewController.view.layer.removeAnimation(forKey: "shadowOpacity")
                _topViewController.view.layer.add(shadowOpacityAnimation, forKey: "shadowOpacity")
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseOut], animations: { [unowned self] in
                    _topViewController.view.transform = self._panGestureBeginsTransform.top
                    _topViewController.view.clipsToBounds = self._panGestureBeginsClips
                    _formerViewController.view.transform = CGAffineTransform(translationX: -_formerViewController.view.bounds.width/2.0, y: 0.0)
                }, completion: { [unowned self] finished in
                    _formerViewController.view.transform = self._panGestureBeginsTransform.former
                })
            }
        }
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
    
    private func _transitionTabNavigationBarWithPercent(_ perecent: CGFloat, transition views: TabNavigationBar.TabNavigationTransitionContext?) {
        guard let transitionViews = views else {
            return
        }
        // Get title views.
        let titleViews = transitionViews.titleViews
        let itemViews = transitionViews.itemViews
        // Get translation of the to item views.
        let translation = min(titleViews.toItemViews.itemsView.bounds.width - titleViews.toItemViews.alignmentContentView.bounds.width, titleViews.containerView.bounds.width) - titleViews.toItemViews.itemsScrollView.contentOffset.x
        // Update the transform of items views.
        titleViews.toItemViews.itemsView.transform = CGAffineTransform(translationX: -translation * (1.0 - perecent), y: 0.0)
        titleViews.toItemViews.itemsView.alpha = perecent
        titleViews.fromItemViews.itemsView.transform = CGAffineTransform(translationX: translation * perecent, y: 0.0)
        titleViews.fromItemViews.itemsView.alpha = 1.0 - perecent
        // Update alpha components of the navigation item views.
        itemViews.fromItemViews.itemsView.alpha = 1.0 - perecent
        itemViews.toItemViews.itemsView.alpha = perecent
        
        if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {// Count == 1
            let backItem = transitionViews.backItem
            let translation = -perecent*backItem.underlyingView.bounds.width
            backItem.underlyingView.transform = CGAffineTransform(translationX: translation, y: 0.0)
            transitionViews.titleViews.containerView.transform = CGAffineTransform(translationX: translation, y: 0.0)
        }
    }
    
    private func _commitTransitionOfNavigationTitleItems(_ items: [TabNavigationTitleItem], navigationItems: [TabNavigationItem], transition views: TabNavigationBar.TabNavigationTransitionContext?, success: Bool, velocity: CGFloat = 1.0) {
        guard let transitionViews = views else { return }
        
        let titleViews = transitionViews.titleViews
        let itemViews = transitionViews.itemViews
        
        let translation = min(titleViews.toItemViews.itemsView.bounds.width - titleViews.toItemViews.alignmentContentView.bounds.width, titleViews.containerView.bounds.width) - titleViews.toItemViews.itemsScrollView.contentOffset.x
        
        if success {
            if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {
                tabNavigationBar._toggleShowingOfNavigationBackItem(shows: false, duration: 0.25, animated: true)
            }
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: velocity, options: [.curveEaseIn], animations: { [unowned self] in
                itemViews.toItemViews.itemsView.alpha = 1.0
                itemViews.fromItemViews.itemsView.alpha = 0.0
                
                transitionViews.backItem.underlyingView.transform = .identity
                titleViews.containerView.transform = .identity
                titleViews.toItemViews.itemsView.transform = self._panGestureBeginsItemViewsTransform.toTransform
                titleViews.toItemViews.itemsView.alpha = 1.0
                titleViews.fromItemViews.itemsView.alpha = 0.0
                titleViews.fromItemViews.itemsView.transform = CGAffineTransform(translationX: translation, y: 0.0)
            }, completion: { [unowned self] finished in
                titleViews.fromItemViews.itemsView.transform = self._panGestureBeginsItemViewsTransform.fromTransform
                titleViews.fromItemViews.itemsView.alpha = 1.0
                itemViews.fromItemViews.itemsView.alpha = 1.0
                
                self.tabNavigationBar.commitTransitionNavigatiomItemViews(itemViews.toItemViews, navigationItems: navigationItems, success: true)
                self.tabNavigationBar.commitTransitionTitleItemViews(titleViews.toItemViews, items: items)
            })
        } else {
            UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: velocity, options: [.curveEaseOut], animations: { [unowned self] in
                itemViews.toItemViews.itemsView.alpha = 0.0
                itemViews.fromItemViews.itemsView.alpha = 1.0
                
                transitionViews.backItem.underlyingView.transform = .identity
                titleViews.containerView.transform = .identity
                titleViews.toItemViews.itemsView.transform = CGAffineTransform(translationX: -translation, y: 0.0)
                titleViews.toItemViews.itemsView.alpha = 0.0
                titleViews.fromItemViews.itemsView.alpha = 1.0
                titleViews.fromItemViews.itemsView.transform = self._panGestureBeginsItemViewsTransform.fromTransform
            }, completion: { [unowned self] finished in
                titleViews.toItemViews.itemsScrollView.removeFromSuperview()
                titleViews.toItemViews.itemsView.transform = self._panGestureBeginsItemViewsTransform.toTransform
                titleViews.toItemViews.itemsView.alpha = 0.0
                
                itemViews.toItemViews.itemsView.alpha = 1.0
                self.tabNavigationBar.commitTransitionNavigatiomItemViews(itemViews.toItemViews, navigationItems: [], success: false)
            })
        }
    }
    
    fileprivate func _pushNavigationTitleItems(_ items: [TabNavigationTitleItem], `in` parameters: TabNavigationBar.TabNavigationTitleItemAnimationContext, completion: (() -> Void)? = nil) {
        let duration: TimeInterval = 0.5
        let animationParam = parameters
        let toTransform = animationParam.toItemViews.itemsView.transform
        
        let translation = min(animationParam.fromItemViews.itemsView.bounds.width - animationParam.fromItemViews.alignmentContentView.bounds.width, animationParam.containerView.bounds.width) - animationParam.fromItemViews.itemsScrollView.contentOffset.x
        
        animationParam.toItemViews.itemsView.transform = CGAffineTransform(translationX: translation, y: 0.0)
        animationParam.toItemViews.itemsView.alpha = 0.0
        
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [.curveEaseOut], animations: {
            animationParam.toItemViews.itemsView.transform = toTransform
            animationParam.toItemViews.itemsView.alpha = 1.0
            animationParam.fromItemViews.itemsView.alpha = 0.0
            animationParam.fromItemViews.itemsView.transform = CGAffineTransform(translationX: -translation, y: 0.0)
        }, completion: { finished in
            if finished {
                completion?()
            }
        })
    }
    
    fileprivate func _popNavigationTitleItems(_ items: [TabNavigationTitleItem], `in` parameters: TabNavigationBar.TabNavigationTitleItemAnimationContext, completion: (() -> Void)? = nil) {
        let duration: TimeInterval = 0.5
        let animationParam = parameters
        let toTransform = animationParam.toItemViews.itemsView.transform
        
        let translation = min(animationParam.toItemViews.itemsView.bounds.width - animationParam.toItemViews.alignmentContentView.bounds.width, animationParam.containerView.bounds.width) - animationParam.toItemViews.itemsScrollView.contentOffset.x
        
        animationParam.toItemViews.itemsView.alpha = 0.0
        animationParam.toItemViews.itemsView.transform = CGAffineTransform(translationX: -translation, y: 0.0)
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [], animations: {
            animationParam.toItemViews.itemsView.transform = toTransform
            animationParam.toItemViews.itemsView.alpha = 1.0
            animationParam.fromItemViews.itemsView.alpha = 0.0
            animationParam.fromItemViews.itemsView.transform = CGAffineTransform(translationX: translation, y: 0.0)
        }, completion: { finished in
            if finished {
                completion?()
            }
        })
    }
    
    fileprivate func _popViewController(_ viewController: UIViewController? = nil, toRoot: Bool = false, ignoreBar: Bool, animated: Bool) {
        guard !_viewControllersStack.isEmpty else {
            return
        }
        guard let formerViewController = _formerViewControllerForPop(viewController, toRoot: toRoot) else { return }
        
        var navigationTitleItems: [TabNavigationTitleItem] = []
        var actionsWhenPushed: [TabNavigationTitleActionItem] = []
        let _removingViewController = _viewControllersStack.last!
        // Add former view controllers.
        if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) || toRoot {
            actionsWhenPushed = tabNavigationTitleActionItemsWhenPushed
            let rootViewControllers = _rootViewControllersInfo.viewControllers
            _rootViewControllersInfo.viewControllers.removeAll()
            for _vc in rootViewControllers {
                _addViewControllerWithoutUpdatingNavigationTitle(_vc)
                navigationTitleItems.append(TabNavigationTitleItem(title: _vc.title ?? ""))
            }
            _contentScrollView.isScrollEnabled = true
            _panGestureRecognizer.isEnabled = false
            tabNavigationBar.hideNavigationBackItem(animated)
        } else {
            actionsWhenPushed = formerViewController.tabNavigationTitleActionItemsWhenPushed
            navigationTitleItems = [TabNavigationTitleItem(title: formerViewController.title ?? "")]
            _addChildViewController(formerViewController, below: _removingViewController.view)
        }
        
        // Update navigation items.
        let duration: TimeInterval = 0.5
        
        if !ignoreBar {
            tabNavigationBar.setNavigationTitleItems(navigationTitleItems, animated: animated, selectedIndex: _rootViewControllersInfo.selectedIndex, actionsConfig: { () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
                return (false, actionsWhenPushed)
            }) { [unowned self] animationParameters in
                if animated {
                    let fromTransform = animationParameters.fromItemViews.itemsView.transform
                    
                    self._popNavigationTitleItems(navigationTitleItems, in: animationParameters) {
                        animationParameters.fromItemViews.itemsView.transform = fromTransform
                        animationParameters.fromItemViews.itemsView.alpha = 1.0
                        self.tabNavigationBar.commitTransitionTitleItemViews(animationParameters.toItemViews, items: navigationTitleItems)
                    }
                }
            }
            tabNavigationBar.setNavigationItems(formerViewController.tabNavigationItems, animated: animated)
        }
        
        _removingViewController.willMove(toParentViewController: nil)
        
        if animated {
            let formerTransform = formerViewController.view.transform
            formerViewController.view.transform = CGAffineTransform(translationX: -formerViewController.view.bounds.width / 2.0, y: 0.0)
            
            let transform = _removingViewController.view.transform
            let clipsToBounds = _removingViewController.view.clipsToBounds
            
            _removingViewController.view.clipsToBounds = false
            _setupTransitionShadowOfViewController(_removingViewController)
            let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
            shadowOpacityAnimation.fromValue = 0.5
            shadowOpacityAnimation.toValue = 0.0
            shadowOpacityAnimation.duration = duration
            shadowOpacityAnimation.fillMode = kCAFillModeForwards
            _removingViewController.view.layer.removeAnimation(forKey: "shadowOpacity")
            _removingViewController.view.layer.add(shadowOpacityAnimation, forKey: "shadowOpacity")
            
            _removingViewController.beginAppearanceTransition(false, animated: animated)
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseIn], animations: {
                _removingViewController.view.transform = CGAffineTransform(translationX: _removingViewController.view.bounds.width, y: 0.0)
                formerViewController.view.transform = formerTransform
            }, completion: { [unowned self] finished in
                if finished {
                    _removingViewController.view.removeFromSuperview()
                    _removingViewController.endAppearanceTransition()
                    _removingViewController.removeFromParentViewController()
                    _removingViewController.didMove(toParentViewController: nil)
                    _removingViewController._tabNavigationController = nil
                    _removingViewController.view.transform = transform
                    _removingViewController.view.clipsToBounds = clipsToBounds
                    if !self._viewControllersStack.isEmpty {
                        if toRoot {
                            self._viewControllersStack.removeAll()
                        } else {
                            self._viewControllersStack.removeLast()
                        }
                    }
                }
            })
        } else {
            _removingViewController.beginAppearanceTransition(false, animated: false)
            _removingViewController.view.removeFromSuperview()
            _removingViewController.endAppearanceTransition()
            _removingViewController.removeFromParentViewController()
            _removingViewController.didMove(toParentViewController: nil)
            _removingViewController._tabNavigationController = nil
            if !_viewControllersStack.isEmpty {
                if toRoot {
                    _viewControllersStack.removeAll()
                } else {
                    _viewControllersStack.removeLast()
                }
            }
        }
    }
    
    fileprivate func _setupTransitionShadowOfViewController(_ viewController: UIViewController) {
        viewController.view.layer.shadowColor = UIColor.lightGray.cgColor
        viewController.view.layer.shadowOffset = CGSize(width: -4.0, height: 0.0)
    }
    
    fileprivate func _addViewControllerWithoutUpdatingNavigationTitle(_ viewController: UIViewController) {
        viewController._tabNavigationController = self
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.addChildViewController(viewController)
        _contentScrollView.addSubview(viewController.view)
        _contentScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: ["view":viewController.view]))
        viewController.view.leadingAnchor.constraint(equalTo: _rootViewControllersInfo.viewControllers.last?.view.trailingAnchor ?? _contentScrollView.leadingAnchor).isActive = true
        if let _trailing = _trailingConstraintOfLastViewController {
            _contentScrollView.removeConstraint(_trailing)
        }
        let _trailing = _contentScrollView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        _trailing.isActive = true
        _trailingConstraintOfLastViewController = _trailing
        
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
    
    fileprivate func _formerViewControllerForPop(_ viewController: UIViewController? = nil, toRoot: Bool = false) -> UIViewController? {
        guard !toRoot else {
            return _rootViewControllersInfo.viewControllers[_rootViewControllersInfo.selectedIndex]
        }
        var formerViewController: UIViewController
        if let _viewController = viewController {
            if _viewControllersStack.contains(_viewController) {
                formerViewController = _viewController
            } else {
                return nil
            }
        } else if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {// Count == 1
            formerViewController = _rootViewControllersInfo.viewControllers[_rootViewControllersInfo.selectedIndex]
        } else {
            formerViewController = _viewControllersStack[_viewControllersStack.index(_viewControllersStack.endIndex, offsetBy: -2)]
        }
        
        return formerViewController
    }
    
    fileprivate func _fetchFormerNavigationTitleItemsAndSetupViewControllersIfNecessary(former viewController: UIViewController) -> [TabNavigationTitleItem] {
        var navigationTitleItems: [TabNavigationTitleItem] = []
        // Add former view controllers.
        if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {
            let rootViewControllers = _rootViewControllersInfo.viewControllers
            _rootViewControllersInfo.viewControllers.removeAll()
            for _vc in rootViewControllers {
                _addViewControllerWithoutUpdatingNavigationTitle(_vc)
                navigationTitleItems.append(TabNavigationTitleItem(title: _vc.title ?? ""))
            }
        } else {
            navigationTitleItems = [TabNavigationTitleItem(title: viewController.title ?? "")]
        }
        
        return navigationTitleItems
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
            _contentScrollView.isScrollEnabled = false
            _panGestureRecognizer.isEnabled = true
            tabNavigationBar.showNavigationBackItem(animated)
            // Record the selected index of the root view controllers.
            _rootViewControllersInfo.selectedIndex = tabNavigationBar.selectedIndex
        }
        _viewControllersStack.append(viewController)
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
            return (false, viewController.tabNavigationTitleActionItemsWhenPushed)
        }) { [unowned self] animationParameters in
            if animated {
                let fromTransform = animationParameters.fromItemViews.itemsView.transform
                
                self._pushNavigationTitleItems(titleItems, in: animationParameters) {
                    animationParameters.fromItemViews.itemsView.transform = fromTransform
                    animationParameters.fromItemViews.itemsView.alpha = 1.0
                    self.tabNavigationBar.commitTransitionTitleItemViews(animationParameters.toItemViews, items: titleItems)
                }
            }
        }
        tabNavigationBar.setNavigationItems(viewController.tabNavigationItems, animated: animated)
        // Prepare to remove root view controllers.
        for _viewController in _rootViewControllersInfo.viewControllers {
            _viewController.willMove(toParentViewController: nil)
        }
        
        if animated {
            let formerViewController = _formerViewControllerForPop()!
            let formerTransform = formerViewController.view.transform
            
            let transform = viewController.view.transform
            viewController.view.transform = CGAffineTransform(translationX: view.bounds.width, y: 0.0)
            for _viewController in _rootViewControllersInfo.viewControllers {
                _viewController.beginAppearanceTransition(false, animated: animated)
            }
            let clipsToBounds = viewController.view.clipsToBounds
            
            viewController.view.clipsToBounds = false
            _setupTransitionShadowOfViewController(viewController)
            let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
            shadowOpacityAnimation.fromValue = 0.0
            shadowOpacityAnimation.toValue = 0.5
            shadowOpacityAnimation.duration = duration
            shadowOpacityAnimation.fillMode = kCAFillModeForwards
            viewController.view.layer.removeAnimation(forKey: "shadowOpacity")
            viewController.view.layer.add(shadowOpacityAnimation, forKey: "shadowOpacity")
            
            viewController.beginAppearanceTransition(true, animated: animated)
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 5.0, options: [.curveEaseOut], animations: {
                viewController.view.transform = transform
                formerViewController.view.transform = CGAffineTransform(translationX: -formerViewController.view.bounds.width / 2.0, y: 0.0)
            }, completion: { [unowned self] finished in
                if finished {
                    formerViewController.view.transform = formerTransform
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
        _popViewController(toRoot: true, ignoreBar: false, animated: animated)
    }
    
    public func pop(to viewController: UIViewController? = nil, animated: Bool) {
        _popViewController(viewController, ignoreBar: false, animated: animated)
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
        _rootViewControllersInfo.selectedIndex = index
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

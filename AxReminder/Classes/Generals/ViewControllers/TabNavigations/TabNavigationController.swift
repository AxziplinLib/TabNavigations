//
//  TabNavigationController.swift
//  TabNavigations
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import AXResponderSchemaKit

private let DefaultTabNavigationBarHeight: CGFloat = 64.0

public extension TabNavigationController {
    public struct TabNavigationTitle {
        let title: String
        let range: CountableRange<Int>?
        
        public init(title: String, selectedRange: CountableRange<Int>? = nil) {
            self.title = title
            range = selectedRange
        }
    }
}

extension TabNavigationController.TabNavigationTitle: ExpressibleByStringLiteral {
    public typealias ExtendedGraphemeClusterLiteralType = Character
    public typealias UnicodeScalarLiteralType = UnicodeScalar
    public typealias StringLiteralType = String
    
    public init(stringLiteral value: TabNavigationController.TabNavigationTitle.StringLiteralType) {
        self.init(title: value)
    }
    
    public init(extendedGraphemeClusterLiteral value: TabNavigationController.TabNavigationTitle.ExtendedGraphemeClusterLiteralType) {
        self.init(stringLiteral: String(value))
    }
    
    public init(unicodeScalarLiteral value: TabNavigationController.TabNavigationTitle.UnicodeScalarLiteralType) {
        self.init(extendedGraphemeClusterLiteral: Character(value))
    }
}

extension TabNavigationController.TabNavigationTitle: ExpressibleByDictionaryLiteral {
    public typealias Key = String
    public typealias Value = Any
    
    public init(dictionaryLiteral elements: (String, Any)...) {
        var _title: String?
        var _range: CountableRange<Int>?
        for (key, value) in elements {
            switch key {
            case "title":
                _title = value as? String
            case "range":
                _range = value as? CountableRange<Int>
            default:
                break
            }
        }
        self.init(title: _title ?? "", selectedRange: _range)
    }
}

public protocol TabNavigationReadable: class {
    var tabNavigationController: TabNavigationController? { get }
    var tabNavigationItems: [TabNavigationItem] { get }
    var tabNavigationTitle: TabNavigationController.TabNavigationTitle? { get }
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
    
    public var tabNavigationController: TabNavigationController? { return _tabNavigationController }
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
    
    public func setTabNavigationItems(_ items: [TabNavigationItem], animated: Bool = false) {
        tabNavigationItems = items
        if _tabNavigationController?._selectedViewController === self && !(_tabNavigationController?.isTabNavigationItemsUpdatingDisabledInRootViewControllers ?? false) {
            _tabNavigationController?.tabNavigationBar.setNavigationItems(items, animated: animated)
        }
    }
}

// MARK: Navigation Title Items.

extension UIViewController {
    private struct _TabNavigationTitleObjectKey {
        static var key = "_TabNavigationTitle"
    }
    
    fileprivate var _tabNavigationTitleItem: TabNavigationTitleItem {
        var titleItem: TabNavigationTitleItem
        if let _title = tabNavigationTitle {
            titleItem = TabNavigationTitleItem(title: _title.title, selectedRange: _title.range)
        } else {
            titleItem = TabNavigationTitleItem(title: self.title ?? "")
        }
        return titleItem
    }
    
    public var tabNavigationTitle: TabNavigationController.TabNavigationTitle? {
        get {
            if let _title = objc_getAssociatedObject(self, &_TabNavigationTitleObjectKey.key) {
                return _title as? TabNavigationController.TabNavigationTitle
            }
            objc_setAssociatedObject(self, &_TabNavigationTitleObjectKey.key, nil, .OBJC_ASSOCIATION_COPY_NONATOMIC)
            return objc_getAssociatedObject(self, &_TabNavigationTitleObjectKey.key) as? TabNavigationController.TabNavigationTitle
        }
        set { objc_setAssociatedObject(self, &_TabNavigationTitleObjectKey.key, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }
    
    public func setTabNavigationTitle(_ title: TabNavigationController.TabNavigationTitle?, animated: Bool = false) {
        tabNavigationTitle = title
        
        if let tabNavigationController = _tabNavigationController {
            if tabNavigationController.topViewController === self && !tabNavigationController._viewControllersStack.isEmpty {
                tabNavigationController.tabNavigationBar.setNavigationTitleItems([_tabNavigationTitleItem], animated: animated, actionsConfig: { () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
                    return (false, self.tabNavigationTitleActionItemsWhenPushed)
                })
            } else if tabNavigationController._rootViewControllersContext.viewControllers.contains(self) {
                var items: [TabNavigationTitleItem] = []
                for viewController in tabNavigationController._rootViewControllersContext.viewControllers {
                    items.append(viewController._tabNavigationTitleItem)
                }
                tabNavigationController.tabNavigationBar.setNavigationTitleItems(items, animated: animated, selectedIndex: tabNavigationController._rootViewControllersContext.selectedIndex, actionsConfig: { () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
                    return (false, tabNavigationController.tabNavigationTitleActionItemsWhenPushed)
                })
            }
        }
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

// MARK: Transitions.

extension UIViewController {
    /// Overrides to prepare for next transition when selected view did appear.
    /// The view controllers former and nexter will be triggered.
    ///
    open func prepareForTransition() { /* No imp for now. */ }
    /// Indicate the view controller managed by TabNavigationController will
    /// begin transition by gesture.(The content scroll view will begin dragging.)
    ///
    open func viewWillBeginInteractiveTransition() { /* No imp for now. */ }
    /// Indicate the view controller managed by TabNavigationController will end 
    /// dragging trasition.
    ///
    /// - Parameter appearing: Indicate the view controller is about to call `viewWillAppear(:)` or not.
    ///
    open func viewDidEndInteractiveTransition(appearing: Bool) { /* No imp for now. */ }
}

// MARK: Layout guide.

extension UIViewController {
    public var keyboardAlignmentLayoutGuide: UILayoutSupport? { return tabNavigationController?.keyboardAlignmentLayoutGuide }
}

extension UIViewController {
    public var layoutInsets: UIEdgeInsets {
        if self.view is UIScrollView {
            return .zero
        } else {
            return UIEdgeInsets(top: DefaultTabNavigationBarHeight, left: 0.0, bottom: 0.0, right: 0.0)
        }
    }
}

// MARK: ScrollView's scrolling to top.

extension UIViewController {
    open func makeViewScrollToTopIfNecessary(at location: CGPoint) {}
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
    fileprivate typealias TabNavigationRootViewControllersContext = (selectedIndex: Array<UIViewController>.Index, viewControllers: [UIViewController])
    public typealias TabNavigationItemViewsContext = (index: Int, navigationItemViews: TabNavigationBar.TabNavigationItemViews?)
}

private func _createGeneralPagingScrollView() -> UIScrollView {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    scrollView.showsVerticalScrollIndicator = false
    scrollView.showsHorizontalScrollIndicator = false
    scrollView.backgroundColor = UIColor.clear
    scrollView.decelerationRate = UIScrollViewDecelerationRateFast
    scrollView.isPagingEnabled = true
    scrollView.scrollsToTop = false
    scrollView.delaysContentTouches = false
    return scrollView
}

private func _createGeneralTabNavigationBar() -> TabNavigationBar {
    let bar = TabNavigationBar()
    bar.translatesAutoresizingMaskIntoConstraints = false
    bar.backgroundColor = .white
    return bar
}

private func _createGeneralAlignmentView<T>() -> T where T: UIView {
    let view = T()
    view.translatesAutoresizingMaskIntoConstraints = false
    view.backgroundColor = .clear
    view.clipsToBounds = true
    view.isUserInteractionEnabled = false
    return view
}

extension TabNavigationController {
    fileprivate class _TabNavigationKeyboardAlignmentLayoutView: UIView { }
}

extension TabNavigationController._TabNavigationKeyboardAlignmentLayoutView: UILayoutSupport {
    var length: CGFloat { return bounds.height }
}

open class TabNavigationController: UIViewController {
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
    
    lazy private var _tabNavigationBar: TabNavigationBar = _createGeneralTabNavigationBar()
    
    public override var keyboardAlignmentLayoutGuide: UILayoutSupport { return _keyboardAlignmentView }
    lazy fileprivate var _keyboardAlignmentView: _TabNavigationKeyboardAlignmentLayoutView = _createGeneralAlignmentView()
    fileprivate var _keyboardAlignmentViewHeightConstraint: NSLayoutConstraint!
    
    public var interactivePopGestureRecognizer: UIPanGestureRecognizer { return _panGestureRecognizer }
    fileprivate var _panGestureRecognizer: UIPanGestureRecognizer!
    fileprivate var _panGestureBeginsLocation: CGPoint = .zero
    fileprivate var _panGestureBeginsTransform: (former: CGAffineTransform, top: CGAffineTransform) = (.identity, .identity)
    fileprivate var _panGestureBeginsTitleItems: [TabNavigationTitleItem] = []
    
    fileprivate var _transitionNavigationBarViews: TabNavigationBar.TabNavigationTransitionContext?
    fileprivate var _panGestureBeginsItemViewsTransform: (fromTransform: CGAffineTransform, toTransform: CGAffineTransform) = (.identity, .identity)
    
    public var topViewController: UIViewController? {
        return _viewControllersStack.last ?? { () -> UIViewController? in
            guard !_rootViewControllersContext.viewControllers.isEmpty && _earlyCheckingBounds(_rootViewControllersContext.selectedIndex, in: _rootViewControllersContext.viewControllers) else { return nil }
            return _rootViewControllersContext.viewControllers[_rootViewControllersContext.selectedIndex]
        }()
    }
    fileprivate weak var _selectedViewController: UIViewController?
    
    private weak var _trailingConstraintOfLastViewController: NSLayoutConstraint?
    fileprivate var _transitionNavigationItemViewsContext: TabNavigationItemViewsContext?
    lazy
    fileprivate var _contentScrollView: UIScrollView = _createGeneralPagingScrollView()
    
    fileprivate var _rootViewControllersContext: TabNavigationRootViewControllersContext = (0, [])
    fileprivate var _viewControllersWaitingForTransition: [UIViewController] = []
    fileprivate var _viewControllersStack: [UIViewController] = []
    fileprivate var _endingAppearanceViewControllers: Set<UIViewController> = []
    
    override open var shouldAutomaticallyForwardAppearanceMethods: Bool { return false }
    public var isViewAppeared: Bool { return _isViewAppeared }
    private var _isViewAppeared: Bool = false
    
    open var isTabNavigationItemsUpdatingDisabledInRootViewControllers: Bool = false {
        didSet {
            _backupedTabNavigationItems = _tabNavigationBar.navigationItems
        }
    }
    fileprivate var _backupedTabNavigationItems: [TabNavigationItem] = []
    
    // MARK: - Overrides.
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _initializer()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    private func _initializer() {
        tabNavigationBar.delegate = self
        _panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(_handlePanGestureRecognizer(_:)))
        _panGestureRecognizer.isEnabled = false
        _panGestureRecognizer.maximumNumberOfTouches = 1
        _keyboardAlignmentViewHeightConstraint = _keyboardAlignmentView.heightAnchor.constraint(equalToConstant: 0.0)
        _keyboardAlignmentViewHeightConstraint.isActive = true
        // NotificationCenter.default.addObserver(self, selector: #selector(_handleKeyboardWillChangeFrameNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(_handleKeyboardWillChangeFrameNotification(_:)), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
        // NotificationCenter.default.addObserver(self, selector: #selector(_handleKeyboardWillChangeFrameNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        // Add tap to scroll to top gesture.
        _tabNavigationBar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(_handleTapTopOfTabNavigationBar(_:))))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override open func loadView() {
        super.loadView()
        
        view.addGestureRecognizer(_panGestureRecognizer)
        _setupTabNavigationBar()
        _setupContentScrollView()
        _setupKeyboardAlignmentView()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // Layout the navigation bar.
        view!.setNeedsLayout()
        view!.layoutIfNeeded()
        // Load all root view controllers if needed.
        let viewControllers = _rootViewControllersContext.viewControllers
        setViewControllers(viewControllers)
        setSelectedViewController(at: _rootViewControllersContext.selectedIndex, animated: false)
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        topViewController?.beginAppearanceTransition(true, animated: animated)
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _isViewAppeared = true
        topViewController?.endAppearanceTransition()
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        topViewController?.beginAppearanceTransition(false, animated: animated)
    }
    
    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        topViewController?.endAppearanceTransition()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Actions.
    
    @objc
    private func _handleTapTopOfTabNavigationBar(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: _tabNavigationBar)
        if CGRect(origin: .zero, size: CGSize(width: UIScreen.main.bounds.width, height: 20.0)).contains(location) {
            if let top = topViewController {
                top.makeViewScrollToTopIfNecessary(at: location)
            }
        }
    }
    
    @objc
    private func _handlePanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
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
            
            _transitionNavigationBarViews = tabNavigationBar.beginTransitionNavigationTitleItems(_panGestureBeginsTitleItems, selectedIndex: _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) ? _rootViewControllersContext.selectedIndex : 0, actionsConfig: { () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
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
            
            _transitionTabNavigationBarWithPercent(transitionPercent, transition: _transitionNavigationBarViews)
        case .cancelled: fallthrough
        case .failed: fallthrough
        case .ended:
            let location = sender.location(in: view)
            let velocity = sender.velocity(in: view)
            let translation = sender.translation(in: view)

            let transitionPercent = max(0.0, location.x - _panGestureBeginsLocation.x) / view.bounds.width
            
            let _formerViewController = _formerViewControllerForPop()!
            let shouldCommitTransition = (transitionPercent >= 0.5 || velocity.x > translation.x * 5.0)
            
            _commitTransitionOfNavigationTitleItems(_panGestureBeginsTitleItems, navigationItems: _formerViewController.tabNavigationItems, transition: _transitionNavigationBarViews, success: shouldCommitTransition)
            
            guard let _topViewController = topViewController else { break }
            
            if shouldCommitTransition {
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseIn], animations: { [unowned self] in
                    _topViewController.view.transform = CGAffineTransform(translationX: _topViewController.view.bounds.width, y: 0.0)
                    _formerViewController.view.transform = self._panGestureBeginsTransform.former
                }, completion: { [unowned self] finished in
                    _topViewController.view.transform = self._panGestureBeginsTransform.top
                    self._popViewController(ignoreBar: true, animated: false)
                })
            } else {
                UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseOut], animations: { [unowned self] in
                    _topViewController.view.transform = self._panGestureBeginsTransform.top
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
    
    private func _setupKeyboardAlignmentView() {
        view.insertSubview(_keyboardAlignmentView, belowSubview: _contentScrollView)
        _keyboardAlignmentView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        _keyboardAlignmentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        _keyboardAlignmentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
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
            let scale = CGPoint(x: 1.0 + perecent * 0.1, y: 1.0 - perecent * 0.3) // Scale effects.
            backItem.underlyingView.transform = CGAffineTransform(translationX: translation, y: 0.0).scaledBy(x: scale.x, y: scale.y)
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
    
    fileprivate func _pushNavigationTitleItems(`in` context: TabNavigationBar.TabNavigationTitleItemAnimationContext, completion: (() -> Void)? = nil) {
        let duration: TimeInterval = 0.5
        
        let fromDelegate = context.fromItemViews.itemsScrollView.delegate
        let fromAlpha = context.fromItemViews.itemsView.alpha
        let toAlpha = context.toItemViews.itemsView.alpha
        let fromTransform = context.fromItemViews.itemsView.transform
        let toTransform = context.toItemViews.itemsView.transform
        
        let translation = min(context.fromItemViews.itemsView.bounds.width - context.fromItemViews.alignmentContentView.bounds.width, context.containerView.bounds.width) - context.fromItemViews.itemsScrollView.contentOffset.x - TabNavigationBar.paddingOfTitleItems

        context.toItemViews.itemsView.transform = CGAffineTransform(translationX: translation, y: 0.0)
        context.toItemViews.itemsView.alpha = 0.0
        context.fromItemViews.itemsScrollView.delegate = nil
        
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 0.0, options: [.curveEaseOut, .layoutSubviews], animations: {
            context.toItemViews.itemsView.transform = toTransform
            context.toItemViews.itemsView.alpha = toAlpha
            context.fromItemViews.itemsView.transform = CGAffineTransform(translationX: -translation, y: 0.0)
            context.fromItemViews.itemsView.alpha = 0.0
        }, completion: { finished in
            context.fromItemViews.itemsScrollView.delegate = fromDelegate
            context.fromItemViews.itemsView.alpha = fromAlpha
            context.fromItemViews.itemsView.transform = fromTransform
            if finished {
                completion?()
            }
        })
    }
    
    fileprivate func _popNavigationTitleItems(`in` context: TabNavigationBar.TabNavigationTitleItemAnimationContext, completion: (() -> Void)? = nil) {
        let duration: TimeInterval = 0.5
        
        let fromAlpha = context.fromItemViews.itemsScrollView.alpha
        let toAlpha = context.toItemViews.itemsScrollView.alpha
        let fromTransform = context.fromItemViews.itemsScrollView.transform
        let toTransform = context.toItemViews.itemsScrollView.transform
        
        let translation = min(context.toItemViews.itemsView.bounds.width - context.toItemViews.alignmentContentView.bounds.width, context.containerView.bounds.width) - context.toItemViews.itemsScrollView.contentOffset.x + TabNavigationBar.paddingOfTitleItems
        
        context.toItemViews.itemsScrollView.transform = CGAffineTransform(translationX: -translation, y: 0.0)
        context.toItemViews.itemsScrollView.alpha = 0.0
        UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseIn], animations: {
            context.toItemViews.itemsScrollView.transform = toTransform
            context.toItemViews.itemsScrollView.alpha = toAlpha
            context.fromItemViews.itemsScrollView.alpha = 0.0
            context.fromItemViews.itemsScrollView.transform = CGAffineTransform(translationX: translation, y: 0.0)
        }, completion: { finished in
            // Restores transform and alpha of from views:
            context.fromItemViews.itemsScrollView.transform = fromTransform
            context.fromItemViews.itemsScrollView.alpha = fromAlpha
            if finished {
                completion?()
            }
        })
    }
    
    fileprivate func _pushViewController(_ viewController: UIViewController, animated: Bool) {
        viewController._tabNavigationController = self
        viewController.loadViewIfNeeded()
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        // Add to child view controllers.
        addChildViewController(viewController)
        var viewControllersToBeRemoved: [UIViewController] = []
        if _viewControllersStack.isEmpty {
            viewControllersToBeRemoved = _rootViewControllersContext.viewControllers
        } else {
            viewControllersToBeRemoved = Array(_viewControllersStack.suffix(1))
        }
        // Prepare to remove root view controllers.
        for _viewController in viewControllersToBeRemoved {
            _viewController.willMove(toParentViewController: nil)
        }
        
        if _viewControllersStack.isEmpty {
            _contentScrollView.isScrollEnabled = false
            _panGestureRecognizer.isEnabled = true
            tabNavigationBar.showNavigationBackItem(animated)
            // Record the selected index of the root view controllers.
            _rootViewControllersContext.selectedIndex = tabNavigationBar.selectedIndex
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
        // Layout view.
        view.setNeedsLayout()
        view.layoutIfNeeded()
        // Update items.
        let duration: TimeInterval = 0.5
        let titleItems = [viewController._tabNavigationTitleItem]
        tabNavigationBar.setNavigationTitleItems(titleItems, animated: animated, actionsConfig: { () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
            return (false, viewController.tabNavigationTitleActionItemsWhenPushed)
        }) { [unowned self] context in
            if animated {
                self._pushNavigationTitleItems(in: context) {
                    self.tabNavigationBar.commitTransitionTitleItemViews(context.toItemViews, items: titleItems)
                }
            }
        }
        if _viewControllersStack.isEmpty && isTabNavigationItemsUpdatingDisabledInRootViewControllers {
            _backupedTabNavigationItems = tabNavigationBar.navigationItems
        }
        tabNavigationBar.setNavigationItems(viewController.tabNavigationItems, animated: animated)
        
        if animated {
            let formerViewController = _formerViewControllerForPop()!
            
            let transform = viewController.view.transform
            let formerTransform = formerViewController.view.transform
            
            viewController.view.transform = CGAffineTransform(translationX: view.bounds.width, y: 0.0)
            
            viewController.beginAppearanceTransition(true, animated: animated)
            _selectedViewController?.beginAppearanceTransition(false, animated: animated)
            
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 5.0, options: [.curveEaseOut], animations: {
                viewController.view.transform = transform
                formerViewController.view.transform = CGAffineTransform(translationX: -formerViewController.view.bounds.width / 2.0, y: 0.0)
            }, completion: { [unowned self] finished in
                if finished {
                    viewController.endAppearanceTransition()
                    self._selectedViewController?.endAppearanceTransition()
                    viewController.didMove(toParentViewController: self)
                    
                    formerViewController.view.transform = formerTransform
                    for _viewController in viewControllersToBeRemoved {
                        _viewController.view.removeFromSuperview()
                        _viewController.removeFromParentViewController()
                        _viewController.didMove(toParentViewController: nil)
                    }
                }
            })
        } else {
            _selectedViewController?.beginAppearanceTransition(false, animated: false)
            _selectedViewController?.endAppearanceTransition()
            for _viewController in viewControllersToBeRemoved {
                _viewController.view.removeFromSuperview()
                _viewController.removeFromParentViewController()
                _viewController.didMove(toParentViewController: nil)
            }
            viewController.beginAppearanceTransition(true, animated: false)
            viewController.endAppearanceTransition()
            viewController.didMove(toParentViewController: self)
        }
    }
    
    fileprivate func _popViewController(_ viewController: UIViewController? = nil, toRoot: Bool = false, ignoreBar: Bool, animated: Bool) {
        guard !_viewControllersStack.isEmpty else { return }
        guard let formerViewController = _formerViewControllerForPop(viewController, toRoot: toRoot) else { return }
        
        var navigationTitleItems: [TabNavigationTitleItem] = []
        var actionsWhenPushed: [TabNavigationTitleActionItem] = []
        guard let _removingViewController = _viewControllersStack.last else { return }
        // Add former view controllers.
        if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) || toRoot {
            actionsWhenPushed = tabNavigationTitleActionItemsWhenPushed
            let rootViewControllers = _rootViewControllersContext.viewControllers
            _rootViewControllersContext.viewControllers.removeAll()
            for _vc in rootViewControllers {
                _addViewControllerWithoutUpdatingNavigationTitle(_vc)
                navigationTitleItems.append(_vc._tabNavigationTitleItem)
            }
            _contentScrollView.isScrollEnabled = true
            _panGestureRecognizer.isEnabled = false
            tabNavigationBar.hideNavigationBackItem(animated)
        } else {
            actionsWhenPushed = formerViewController.tabNavigationTitleActionItemsWhenPushed
            navigationTitleItems = [formerViewController._tabNavigationTitleItem]
            _addChildViewController(formerViewController, below: _removingViewController.view)
        }
        
        // Update navigation items.
        let duration: TimeInterval = 0.5
        
        if !ignoreBar {
            // Update title items.
            tabNavigationBar.setNavigationTitleItems(navigationTitleItems, animated: animated, selectedIndex: _rootViewControllersContext.selectedIndex, actionsConfig: { () -> (ignore: Bool, actions: [TabNavigationTitleActionItem]?) in
                return (false, actionsWhenPushed)
            }) { [unowned self] context in
                if animated {
                    self._popNavigationTitleItems(in: context) {
                        self.tabNavigationBar.commitTransitionTitleItemViews(context.toItemViews, items: navigationTitleItems)
                    }
                }
            }
            // Update navigation items.
            if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) && isTabNavigationItemsUpdatingDisabledInRootViewControllers {
                tabNavigationBar.setNavigationItems(_backupedTabNavigationItems, animated: animated)
            } else {
                tabNavigationBar.setNavigationItems(formerViewController.tabNavigationItems, animated: animated)
            }
        }
        // Will remove view controller to be popped.
        _removingViewController.willMove(toParentViewController: nil)
        
        if animated {
            let transform = _removingViewController.view.transform
            let formerTransform = formerViewController.view.transform
            
            formerViewController.view.transform = CGAffineTransform(translationX: -formerViewController.view.bounds.width / 2.0, y: 0.0)
            // View of view-controller to be popped will disappear with animated.
            _removingViewController.beginAppearanceTransition(false, animated: animated)
            formerViewController.beginAppearanceTransition(true, animated: animated)
            // Execute the animation.
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseIn], animations: {
                _removingViewController.view.transform = CGAffineTransform(translationX: _removingViewController.view.bounds.width, y: 0.0)
                formerViewController.view.transform = formerTransform
            }, completion: { [unowned self] finished in
                if finished {
                    // View of view-controller to be popped did disappear.
                    _removingViewController.endAppearanceTransition()
                    formerViewController.endAppearanceTransition()
                    // Remove view of view-controller to be popped.
                    _removingViewController.view.removeFromSuperview()
                    // Remove view controller to be popped.
                    _removingViewController.removeFromParentViewController()
                    // Did remove view controller to be popped.
                    _removingViewController.didMove(toParentViewController: nil)
                    // Restore properties:
                    _removingViewController._tabNavigationController = nil
                    _removingViewController.view.transform = transform
                    
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
            formerViewController.beginAppearanceTransition(false, animated: false)
            _removingViewController.endAppearanceTransition()
            formerViewController.endAppearanceTransition()
            _removingViewController.view.removeFromSuperview()
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
        viewController.loadViewIfNeeded()
        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Call addChildViewController to trigger willMoveTo: method.
        addChildViewController(viewController)
        // Add view of view controller to container controller.
        if viewController.view is UIScrollView {
            _contentScrollView.addSubview(viewController.view)
            _contentScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[view]-bottom-|", options: [], metrics: ["top": viewController.layoutInsets.top, "bottom": viewController.layoutInsets.bottom], views: ["view":viewController.view]))
            if viewController.automaticallyAdjustsScrollViewInsets {
                (viewController.view as! UIScrollView).contentInset = UIEdgeInsets(top: DefaultTabNavigationBarHeight, left: 0.0, bottom: 0.0, right: 0.0)
            }
        } else {
            _contentScrollView.addSubview(viewController.view)
            _contentScrollView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[view]-bottom-|", options: [], metrics: ["top": viewController.layoutInsets.top, "bottom": viewController.layoutInsets.bottom], views: ["view":viewController.view]))
        }
        viewController.view.leadingAnchor.constraint(equalTo: _rootViewControllersContext.viewControllers.last?.view.trailingAnchor ?? _contentScrollView.leadingAnchor).isActive = true
        // Updating trailing constraint.
        if let _trailing = _trailingConstraintOfLastViewController {
            _contentScrollView.removeConstraint(_trailing)
        }
        let _trailing = _contentScrollView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        _trailing.isActive = true
        _trailingConstraintOfLastViewController = _trailing
        
        viewController.view.widthAnchor.constraint(equalTo: _contentScrollView.widthAnchor).isActive = true
        viewController.view.heightAnchor.constraint(equalTo: _contentScrollView.heightAnchor).isActive = true
        
        if !_rootViewControllersContext.viewControllers.contains(viewController) {
            _rootViewControllersContext.viewControllers.append(viewController)
        }
        viewController.didMove(toParentViewController: self)
    }
    
    fileprivate func _addChildViewController(_ viewController: UIViewController, below: UIView) {
        viewController._tabNavigationController = self
        viewController.loadViewIfNeeded()
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
            return _rootViewControllersContext.viewControllers[_rootViewControllersContext.selectedIndex]
        }
        var formerViewController: UIViewController
        if let _viewController = viewController {
            if _viewControllersStack.contains(_viewController) {
                formerViewController = _viewController
            } else {
                return nil
            }
        } else if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {// Count == 1
            formerViewController = _rootViewControllersContext.viewControllers[_rootViewControllersContext.selectedIndex]
        } else {
            formerViewController = _viewControllersStack[_viewControllersStack.index(_viewControllersStack.endIndex, offsetBy: -2)]
        }
        
        return formerViewController
    }
    
    fileprivate func _fetchFormerNavigationTitleItemsAndSetupViewControllersIfNecessary(former viewController: UIViewController) -> [TabNavigationTitleItem] {
        var navigationTitleItems: [TabNavigationTitleItem] = []
        // Add former view controllers.
        if _viewControllersStack.startIndex == _viewControllersStack.index(before: _viewControllersStack.endIndex) {
            let rootViewControllers = _rootViewControllersContext.viewControllers
            _rootViewControllersContext.viewControllers.removeAll()
            for _vc in rootViewControllers {
                _addViewControllerWithoutUpdatingNavigationTitle(_vc)
                navigationTitleItems.append(_vc._tabNavigationTitleItem)
            }
        } else {
            navigationTitleItems = [viewController._tabNavigationTitleItem]
        }
        
        return navigationTitleItems
    }
    
    fileprivate func _setSelectedViewController(at index: Array<UIViewController>.Index, updateNavigationBar: Bool = false, updateNavigationItems: Bool, animated: Bool) {
        guard _earlyCheckingBounds(index, in: _rootViewControllersContext.viewControllers) else { return }
        guard isViewLoaded else {
            _rootViewControllersContext.selectedIndex = index;
            return
        }
        
        let viewController = _rootViewControllersContext.viewControllers[index]
        guard viewController !== _selectedViewController else { return }
        
        _contentScrollView.scrollRectToVisible(viewController.view.frame, animated: animated)
        if updateNavigationBar {
            // Lock the delegate of tab navigation bar.
            let delegate = _tabNavigationBar.delegate
            _tabNavigationBar.delegate = nil
            _tabNavigationBar.setSelectedTitle(at: index, animated: animated)
            _tabNavigationBar.delegate = delegate
        }
        
        _beginsRootViewControllersAppearanceTransition(at: index, updateNavigationItems: updateNavigationItems, animated: animated)
        if !animated { _endsRootViewControllersAppearanceTransitionIfNecessary() }
    }
    
    fileprivate func _beginsRootViewControllersAppearanceTransition(at index: Array<UIViewController>.Index, updateNavigationItems: Bool, animated: Bool) {
        guard _earlyCheckingBounds(index, in: _rootViewControllersContext.viewControllers) else { return }
        
        let viewController = _rootViewControllersContext.viewControllers[index]
        guard viewController !== _selectedViewController else { return }
        
        if let selectedViewController = _selectedViewController {
            selectedViewController.beginAppearanceTransition(false, animated: animated)
            _endingAppearanceViewControllers.update(with: selectedViewController)
        }
        _selectedViewController = viewController
        _selectedViewController!.beginAppearanceTransition(true, animated: animated)
        _endingAppearanceViewControllers.update(with: viewController)
        if updateNavigationItems {
            tabNavigationBar.setNavigationItems(_selectedViewController!.tabNavigationItems, animated: animated)
        }
        _rootViewControllersContext.selectedIndex = index
    }
    
    fileprivate func _endsRootViewControllersAppearanceTransitionIfNecessary() {
        guard !_endingAppearanceViewControllers.isEmpty else { return }
        
        _endingAppearanceViewControllers.forEach { $0.endAppearanceTransition() }
        _endingAppearanceViewControllers.removeAll()
        
        _makeNeededViewControllersPreparing()
    }
    
    fileprivate func _availableTransitionRange() -> CountableClosedRange<Array<UIViewController>.Index> {
        let selectedIndex = _rootViewControllersContext.selectedIndex
        let startIndex = _rootViewControllersContext.viewControllers.index(before: selectedIndex)
        let endIndex = _rootViewControllersContext.viewControllers.index(after: selectedIndex)
        let range = startIndex...endIndex
        let availableRange = range.clamped(to: _rootViewControllersContext.viewControllers.startIndex..._rootViewControllersContext.viewControllers.index(before: _rootViewControllersContext.viewControllers.endIndex))
        return availableRange
    }
    
    fileprivate func _beginsRootViewControllersInteractiveTransition() {
        let availableRange = _availableTransitionRange()
        _viewControllersWaitingForTransition = Array(_rootViewControllersContext.viewControllers[availableRange])
        _viewControllersWaitingForTransition.forEach({ $0.viewWillBeginInteractiveTransition() })
    }
    
    fileprivate func _endsRootViewControllersInteractiveTransitionIfNecessary(at index: Array<UIViewController>.Index) {
        _viewControllersWaitingForTransition.forEach { [unowned self] (viewController) in
            let indexOfViewController =  self._rootViewControllersContext.viewControllers.index(of: viewController)
            let selectedIndex = self._rootViewControllersContext.selectedIndex
            
            if (index == selectedIndex &&  indexOfViewController == selectedIndex)
            || (index != selectedIndex && (indexOfViewController == selectedIndex || indexOfViewController == index)) {
                viewController.viewDidEndInteractiveTransition(appearing: true)
            } else {
                viewController.viewDidEndInteractiveTransition(appearing: false)
            }
        }
        _viewControllersWaitingForTransition.removeAll()
    }
    
    fileprivate func _makeNeededViewControllersPreparing() {
        let availableRange = _availableTransitionRange()
        let rootViewControllers = _rootViewControllersContext.viewControllers
        let selectedIndex = _rootViewControllersContext.selectedIndex
        let viewControllersPreparing = Array(_rootViewControllersContext.viewControllers[availableRange])
        
        viewControllersPreparing.flatMap({ rootViewControllers.index(of: $0) == selectedIndex ? nil : $0 }).forEach({ $0.prepareForTransition() })
    }
}

extension TabNavigationController {
    @objc
    fileprivate func _handleKeyboardWillChangeFrameNotification(_ notification: NSNotification) {
        if let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue, let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? TimeInterval, let curve = notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? UInt {
            // print("Keyboard height: \(keyboardFrame.height)")
            self._keyboardAlignmentViewHeightConstraint.constant = keyboardFrame.height
            UIView.animate(withDuration: duration, delay: 0.0, options: UIViewAnimationOptions(rawValue: curve), animations: { [unowned self] in
                self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
}

extension TabNavigationController {
    // MARK: - Public.
    // MARK: Tab view controllers.
    
    public func setViewControllers<T>(_ viewControllers: Array<T>) where T: UIViewController, T: TabNavigationReadable {
        guard _viewControllersStack.isEmpty else {
            _rootViewControllersContext.viewControllers = viewControllers
            return
        }
        // Remove all the view controllers first.
        while !_rootViewControllersContext.viewControllers.isEmpty {
            removeLastViewController()
        }
        for viewController in viewControllers {
            addViewController(viewController)
        }
    }
    
    public func setSelectedViewController(_ viewController: UIViewController, animated: Bool) {
        if let index = _rootViewControllersContext.viewControllers.index(of: viewController) {
            setSelectedViewController(at: index, animated: animated)
        }
    }
    
    public func setSelectedViewController(at index: Array<UIViewController>.Index, animated: Bool) {
        _setSelectedViewController(at: index, updateNavigationBar: true, updateNavigationItems: !isTabNavigationItemsUpdatingDisabledInRootViewControllers, animated: animated)
    }
    
    public func addViewController<T>(_ viewController: T) where T: UIViewController, T: TabNavigationReadable {
        if isViewLoaded {
            // Add view controller as child view controller if view of tab-navigation controller loaded.
            _addViewControllerWithoutUpdatingNavigationTitle(viewController)
            tabNavigationBar.addNavigationTitleItem(viewController._tabNavigationTitleItem)
        } else {
            _rootViewControllersContext.viewControllers.append(viewController)
        }
    }
    @discardableResult
    public func removeViewController<T>(_ viewController: T) -> (Bool, UIViewController?) where T: UIViewController, T:TabNavigationReadable {
        guard let index = _rootViewControllersContext.viewControllers.index(of: viewController) else {
            return (false, nil)
        }
        
        return removeViewController(at: index)
    }
    @discardableResult
    public func removeFirstViewController() -> (Bool, UIViewController?) {
        guard !_rootViewControllersContext.viewControllers.isEmpty else {
            return (false, nil)
        }
        
        return removeViewController(at: _rootViewControllersContext.viewControllers.startIndex)
    }
    @discardableResult
    public func removeLastViewController() -> (Bool, UIViewController?) {
        guard !_rootViewControllersContext.viewControllers.isEmpty else {
            return (false, nil)
        }
        
        return removeViewController(at: _rootViewControllersContext.viewControllers.index(before: _rootViewControllersContext.viewControllers.endIndex))
    }
    @discardableResult
    public func removeViewController(at index: Array<UIViewController>.Index) -> (Bool, UIViewController?) {
        guard !_rootViewControllersContext.viewControllers.isEmpty else { return (false, nil) }
        guard _earlyCheckingBounds(index, in: _rootViewControllersContext.viewControllers) else { return (false, nil) }
        
        let viewController = _rootViewControllersContext.viewControllers[index]
        guard viewController.isViewLoaded else {
            _rootViewControllersContext.viewControllers.remove(at: index)
            tabNavigationBar.removeNavigaitonTitleItem(at: index)
            return (true, viewController)
        }
        
        viewController.willMove(toParentViewController: nil)
        viewController.beginAppearanceTransition(false, animated: false)
        viewController.endAppearanceTransition()
        viewController.view.removeFromSuperview()
        viewController.removeFromParentViewController()
        viewController.didMove(toParentViewController: nil)
        
        _rootViewControllersContext.viewControllers.remove(at: index)
        tabNavigationBar.removeNavigaitonTitleItem(at: index)
        
        return (true, viewController)
    }
    
    // MARK: Navigation controllers.
    
    public func push(_ viewController: UIViewController, animated: Bool) {
        _pushViewController(viewController, animated: animated)
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
    public func tabNavigationBar(_ tabNavigationBar: TabNavigationBar, willSelectTitleItemAt index: Int, animated: Bool) {
        guard _viewControllersStack.isEmpty else {
            return
        }
        _setSelectedViewController(at: index, updateNavigationItems: !isTabNavigationItemsUpdatingDisabledInRootViewControllers, animated: animated)
    }
    
    public func tabNavigationBar(_ tabNavigationBar: TabNavigationBar, didSelectTitleItemAt index: Int) {
        _endsRootViewControllersAppearanceTransitionIfNecessary()
    }
    
    public func tabNavigationBarDidTouchNavigatiomBackItem(_ tabNavigationBar: TabNavigationBar) {
        pop(animated: true)
    }
}

// MARK: - UIScrollViewDelegate.

extension TabNavigationController: UIScrollViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView.isDecelerating {
            _endsRootViewControllersAppearanceTransitionIfNecessary()
        }
        _beginsRootViewControllersInteractiveTransition()
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        guard _viewControllersStack.isEmpty else {
            return
        }
        _commitTransitionNavigationItemViews(at: Int(scrollView.contentOffset.x / scrollView.bounds.width))
        _endsRootViewControllersAppearanceTransitionIfNecessary()
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let selectedIndex = Int(targetContentOffset[0].x / scrollView.bounds.width)
        _endsRootViewControllersInteractiveTransitionIfNecessary(at: selectedIndex)
        _beginsRootViewControllersAppearanceTransition(at: selectedIndex, updateNavigationItems: false, animated: true)
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard _viewControllersStack.isEmpty else {
            return
        }
        if scrollView.isDragging || scrollView.isDecelerating {
            let index = Int(scrollView.contentOffset.x / scrollView.bounds.width)
            
            if index < _rootViewControllersContext.viewControllers.index(before: _rootViewControllersContext.viewControllers.endIndex)
            && scrollView.contentOffset.x >= 0
            && scrollView.contentOffset.x.truncatingRemainder(dividingBy: scrollView.bounds.width) != 0.0
            && !isTabNavigationItemsUpdatingDisabledInRootViewControllers
            {
                let showingIndex = _rootViewControllersContext.viewControllers.index(after: index)
                let viewController = _rootViewControllersContext.viewControllers[showingIndex]
                
                let formerViewController = _rootViewControllersContext.viewControllers[index]
                let transitionNavigationItemViews = tabNavigationBar.beginTransitionNavigationItems(viewController.tabNavigationItems, on: formerViewController.tabNavigationItems, in: _transitionNavigationItemViewsContext?.navigationItemViews)
                
                _transitionNavigationItemViewsContext = (showingIndex, transitionNavigationItemViews)
            }
            
            tabNavigationBar.setNestedScrollViewContentOffset(scrollView.contentOffset, contentSize: scrollView.contentSize, bounds: scrollView.bounds, transition: _transitionNavigationItemViewsContext?.navigationItemViews)
        }
    }
    
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        _endsRootViewControllersAppearanceTransitionIfNecessary()
    }
    
    private func _commitTransitionNavigationItemViews(at index: Int) {
        if let info = _transitionNavigationItemViewsContext {
            if info.index == index {
                let viewController = _rootViewControllersContext.viewControllers[index]
                tabNavigationBar.commitTransitionNavigatiomItemViews(info.navigationItemViews, navigationItems: viewController.tabNavigationItems, success: true)
            } else {
                tabNavigationBar.commitTransitionNavigatiomItemViews(info.navigationItemViews, navigationItems: [], success: false)
            }
            _transitionNavigationItemViewsContext = nil
        }
    }
}

// MARK: - Status Bar Supporting.
extension TabNavigationController {
    override open var prefersStatusBarHidden: Bool { return true }
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

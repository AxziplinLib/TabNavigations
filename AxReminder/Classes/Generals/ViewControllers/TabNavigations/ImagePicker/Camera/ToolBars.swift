//
//  ToolBars.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

// MARK: - TopBar.

extension CameraViewController {
    @available(iOS 9.0, *)
    public final class TopBar: UIView {
        public var countMeetsFullScreen: Int = 5
        
        internal var didSelectItem  : ItemsSelection?
        internal var willShowActions: ActionsPresentation?
        internal var willHideActions: ActionsDismissal?
        internal var didSelectAction: ActionsSelection?
        
        fileprivate var state: _State = .items(selected: .index(0))
        public var items: [BarItem] = [] { didSet { _updateItemViews(items: items) } }
        fileprivate var _itemsBackup: [BarItem] = []
        fileprivate let _stackContentInset: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 15.0, bottom: 0.0, right: 15.0)
        fileprivate weak var _leadingConstraintOfContentSctollView: NSLayoutConstraint?
        
        fileprivate lazy var _contentScollView: UIScrollView = { () -> UIScrollView in
            let scrollView = UIScrollView()
            scrollView.translatesAutoresizingMaskIntoConstraints = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.alwaysBounceHorizontal = true
            scrollView.bounces = true
            scrollView.scrollsToTop = false
            scrollView.delaysContentTouches = false
            scrollView.isPagingEnabled = true
            return scrollView
        }()
        fileprivate lazy var _stackView: UIStackView = { () -> UIStackView in
            let stackView = UIStackView()
            stackView.backgroundColor = .clear
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.distribution = .equalSpacing
            stackView.alignment = .fill
            return stackView
        }()
        
        override public init(frame: CGRect) {
            super.init(frame: frame)
            _initializer()
        }
        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            _initializer()
        }
        private func _initializer() {
            _setupContentScrollView()
            _setupStackView()
        }
        
        private func _setupContentScrollView() {
            addSubview(_contentScollView)
            let leading = _contentScollView.leadingAnchor.constraint(equalTo: leadingAnchor)
            leading.isActive = true
            _leadingConstraintOfContentSctollView = leading
            _contentScollView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            _contentScollView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            _contentScollView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
            _contentScollView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        }
        
        private func _setupStackView() {
            _contentScollView.addSubview(_stackView)
            _stackView.leadingAnchor.constraint(equalTo: _contentScollView.leadingAnchor, constant: _stackContentInset.left).isActive = true
            _stackView.trailingAnchor.constraint(equalTo: _contentScollView.trailingAnchor, constant: -_stackContentInset.right).isActive = true
            _stackView.topAnchor.constraint(equalTo: _contentScollView.topAnchor, constant: _stackContentInset.top).isActive = true
            _stackView.bottomAnchor.constraint(equalTo: _contentScollView.bottomAnchor, constant: -_stackContentInset.bottom).isActive = true
            _stackView.heightAnchor.constraint(equalTo: heightAnchor, constant: -_stackContentInset.height).isActive = true
        }
    }
}

extension CameraViewController.TopBar {
    internal enum _State {
        case items(selected: Index)
        case actions(index: Index, itemIndex: Index, itemView: UIView)
    }
    
    internal typealias ItemsSelection      = (Int) -> Void // Selected item index.
    internal typealias ActionsPresentation = (Int) -> Void // Selected item index.
    internal typealias ActionsDismissal    = ActionsPresentation
    internal typealias ActionsSelection    = (Int, Int) -> Void // Selected item index, selected action index.
}
extension CameraViewController.TopBar._State {
    enum Index {
        case invalid
        case index(Int)
    }
}

// MARK: Actions.

extension CameraViewController.TopBar {
    fileprivate func _updateItemViews(items barItems: [CameraViewController.BarItem]) {
        _stackView.arrangedSubviews.forEach({ self._stackView.removeArrangedSubview($0); $0.removeFromSuperview() })
        barItems.map({ _itemButton(for: $0) }).forEach({ self._stackView.addArrangedSubview($0) })
        setNeedsLayout()
        layoutIfNeeded()
        
        let count = barItems.count
        switch state {
        case .actions(index: _, itemIndex: _, itemView: let itemView):
            if count <= countMeetsFullScreen {
                _stackView.spacing = (bounds.width - _stackContentInset.width - _stackView.arrangedSubviews.map({ $0.bounds.width }).reduce(itemView.bounds.width, { $0 + $1 })) / CGFloat(count)
            } else {
                _stackView.spacing = (bounds.width - _stackContentInset.width - _stackView.arrangedSubviews.prefix(upTo: countMeetsFullScreen).map({ $0.bounds.width }).reduce(itemView.bounds.width, { $0 + $1 })) / CGFloat(countMeetsFullScreen)
            }
        default:
            if count <= countMeetsFullScreen {
                _stackView.spacing = count == 1 ? 0.0 : (bounds.width - _stackContentInset.width - _stackView.arrangedSubviews.map({ $0.bounds.width }).reduce(0.0, { $0 + $1 })) / CGFloat(count - 1)
            } else {
                _stackView.spacing = (bounds.width - _stackContentInset.width - _stackView.arrangedSubviews.prefix(upTo: countMeetsFullScreen).map({ $0.bounds.width }).reduce(0.0, { $0 + $1 })) / CGFloat(countMeetsFullScreen - 1)
            }
        }
    }
    
    private func _itemButton(for item: CameraViewController.BarItem) -> UIButton {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(_Resource.Config.Camera.Color.highlighted, for: .selected)
        button.adjustsImageWhenDisabled = false
        button.adjustsImageWhenHighlighted = false
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13)
        if let tintColor = item.tintColor { button.tintColor = tintColor }
        if let image = item.image { button.setImage(image, for: .normal) } else {
            button.setTitle(item.title, for: .normal)
        }
        button.addTarget(self, action: #selector(_touchUpInside(_:)), for: .touchUpInside)
        return button
    }
    
    @objc
    private func _touchUpInside(_ sender: UIButton) {
        switch state {
        case .actions(index: .index(let _index), itemIndex: .index(let itemIndex), itemView: _):
            let index = _stackView.arrangedSubviews.index(of: sender) ?? _index
            _itemsBackup[itemIndex].index = index
            didSelectAction?(itemIndex, index)
            _toggle(from: state, to: .items(selected: .index(index)), items: _itemsBackup)
        case .items(selected: _):
            guard let itemIndex = _stackView.arrangedSubviews.index(of: sender) else { break }
            let item = items[itemIndex]
            
            if item.actions.isEmpty {
                didSelectItem?(itemIndex)
            } else {
                _toggle(from: self.state, to: .actions(index: .index(item.index), itemIndex: .index(itemIndex), itemView: sender), items: item.actions)
            }
        default: break
        }
    }
    
    private func _toggle(from: _State, to state: _State, items: [CameraViewController.BarItem], animated: Bool = true) {
        self.state = state
        let duration = 0.5
        switch self.state {
        case .actions(index: .index(let index), itemIndex: .index(let itemIndex), itemView: let itemView):
            var itemViewsToBeRemoved = _stackView.arrangedSubviews
            itemViewsToBeRemoved.forEach({ self._applyTransition(on: $0, transform: $0 === itemView) })
            itemViewsToBeRemoved.remove(at: itemIndex)
            
            _itemsBackup = self.items
            self.items = items
            
            removeConstraintIfNotNil(_leadingConstraintOfContentSctollView)
            let _leading = _contentScollView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: itemView.bounds.width + _stackView.spacing)
            _leading.isActive = true
            _leadingConstraintOfContentSctollView = _leading
            setNeedsLayout()
            layoutIfNeeded()
            
            willShowActions?(itemIndex)
            if animated {
                let itemViewsToBeAdded = _stackView.arrangedSubviews
                itemViewsToBeAdded.forEach({ $0.alpha = 0.0 })
                UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseOut], animations: {
                    itemView.transform = .identity
                    itemViewsToBeRemoved.forEach({ $0.alpha = 0.0 })
                    itemViewsToBeAdded.forEach({ $0.alpha = 1.0 })
                }) { _ in
                    itemViewsToBeRemoved.forEach({ $0.removeFromSuperview() })
                }
            } else {
                itemView.transform = .identity
                itemViewsToBeRemoved.forEach({ $0.removeFromSuperview() })
            }
            _selectItem(at: index)
        case .items(selected: _):
            let itemViewsToBeRemoved = _stackView.arrangedSubviews
            itemViewsToBeRemoved.forEach({ self._applyTransition(on: $0, transform: false) })
            
            switch from {
            case .actions(index: _, itemIndex: .index(let itemIndex), itemView: let itemView):
                self.items = items
                
                removeConstraintIfNotNil(_leadingConstraintOfContentSctollView)
                let _leading = _contentScollView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
                _leading.isActive = true
                _leadingConstraintOfContentSctollView = _leading
                setNeedsLayout()
                layoutIfNeeded()
                
                willHideActions?(itemIndex)
                if animated {
                    let itemViewsToBeAdded = _stackView.arrangedSubviews
                    itemViewsToBeAdded.forEach({ $0.alpha = 0.0 })
                    UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseOut], animations: {
                        itemView.transform = CGAffineTransform(translationX: self._stackView.convert(itemViewsToBeAdded[itemIndex].center, to: self).x - itemView.center.x, y: 0.0)
                        itemViewsToBeRemoved.forEach({ $0.alpha = 0.0 })
                        itemViewsToBeAdded.enumerated().forEach({ $1.alpha = $0 != itemIndex ? 1.0 : 0.0 })
                    }) { _ in
                        itemViewsToBeRemoved.forEach({ $0.removeFromSuperview() })
                        itemViewsToBeAdded[itemIndex].alpha = 1.0
                        itemView.removeFromSuperview()
                    }
                } else {
                    itemView.removeFromSuperview()
                    itemViewsToBeRemoved.forEach({ $0.removeFromSuperview() })
                }
            default: break
            }
        default: break
        }
    }
    
    private func _applyTransition(on itemView: UIView, transform: Bool) {
        let frame = _stackView.convert(itemView.frame, to: self)
        _stackView.removeArrangedSubview(itemView)
        itemView.removeFromSuperview()
        addSubview(itemView)
        if transform {
            itemView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: self._stackContentInset.left).isActive = true
            itemView.transform = CGAffineTransform(translationX: frame.origin.x - self._stackContentInset.left, y: 0.0)
        } else {
            itemView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: frame.origin.x).isActive = true
        }
        itemView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        itemView.heightAnchor.constraint(equalToConstant: frame.height).isActive = true
    }
    
    private func _selectItem(at index: Int) {
        let itemViews = _stackView.arrangedSubviews as! [UIButton]
        itemViews.enumerated().forEach { (idx, itemView) in
            if index == idx {
                itemView.isSelected = true
            } else {
                itemView.isSelected = false
            }
        }
    }
}

extension CameraViewController.TopBar {
    internal func updateImage(_ image: UIImage?, ofItemAtIndex index: Array<CameraViewController.BarItem>.Index) {
        guard index >= _itemsBackup.startIndex && index < _itemsBackup.endIndex else { return }
        
        var barItem = _itemsBackup[index]
        barItem.image = image
        _updateBarItem(at: index, with: barItem)
    }
    private func _updateBarItem(at index: Array<CameraViewController.BarItem>.Index, with barItem: CameraViewController.BarItem) {
        func _updateButton(_ button: UIButton) {
            if let image = barItem.image {
                button.setImage(image, for: .normal)
                button.setTitle(nil, for: .normal)
            } else {
                button.setTitle(barItem.title, for: .normal)
            }
            button.tintColor = barItem.tintColor
        }
        
        // _updateButton(_stackView.arrangedSubviews[index] as! UIButton)
        switch state {
        case .actions(index: _, itemIndex: _, itemView: let itemButton as UIButton):
            _updateButton(itemButton)
            _itemsBackup[index] = barItem
        default:
            items[index] = barItem
        }
    }
}

// MARK: - BarItem.

extension CameraViewController {
    public struct BarItem {
        let title: String
        var image: UIImage?
        var tintColor: UIColor?
        let actions: [BarItem]
        var index: Array<BarItem>.Index
        
        public init(title: String, image: UIImage? = nil, tintColor: UIColor? = nil, actions: [BarItem] = [], index: Array<BarItem>.Index = 0) {
            self.title = title
            self.image = image
            self.tintColor = tintColor
            self.actions = actions
            self.index = index
        }
    }
}
extension CameraViewController.BarItem {
    public init(image: UIImage, actions: [CameraViewController.BarItem] = []) {
        self.init(title: "", image: image, actions: actions)
    }
}

// MARK: - BottomBar.

extension CameraViewController {
    public final class BottomBar: UIView {
        public var shot: UIButton { return _shot }
        private let _shot: UIButton = UIButton(type: .system)
        
        public var toggle: UIButton { return _toggleFace }
        private let _toggleFace: UIButton = UIButton(type: .system)
        
        public var cancel: UIButton { return _cancel }
        private let _cancel: UIButton = UIButton(type: .system)
        
        override public init(frame: CGRect) {
            super.init(frame: frame)
            _initializer()
        }
        
        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            _initializer()
        }
        
        private func _initializer() {
            _shot.setImage(#imageLiteral(resourceName: "shot"), for: .normal)
            _toggleFace.setImage(#imageLiteral(resourceName: "toggle_face"), for: .normal)
            _cancel.setTitle(NSLocalizedString("Cancel", comment: "Cancel"), for: .normal)
            
            _setupConstraints()
        }
        
        private func _setupConstraints() {
            _shot.translatesAutoresizingMaskIntoConstraints = false
            _cancel.translatesAutoresizingMaskIntoConstraints = false
            _toggleFace.translatesAutoresizingMaskIntoConstraints = false
            
            addSubview(_shot)
            addSubview(_cancel)
            addSubview(_toggleFace)
            
            _shot.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            _shot.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -15.0).isActive = true
            _shot.topAnchor.constraint(greaterThanOrEqualTo: topAnchor).isActive = true
            
            _cancel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15.0).isActive = true
            _cancel.centerYAnchor.constraint(equalTo: _shot.centerYAnchor).isActive = true
            // _cancel.trailingAnchor.constraint(greaterThanOrEqualTo: _shot.leadingAnchor).isActive = true
            
            _toggleFace.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15.0).isActive = true
            _toggleFace.centerYAnchor.constraint(equalTo: _shot.centerYAnchor).isActive = true
            // _toggleFace.leadingAnchor.constraint(greaterThanOrEqualTo: _shot.trailingAnchor).isActive = true
        }
    }
}

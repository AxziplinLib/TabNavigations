//
//  ItemAddingCollectionViewController.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import AXPracticalHUD

private let _DefaultReusableViewIdentifier = "_DefaultReusableViewIdentifier"

extension ItemAddingCollectionViewController {
    override var layoutInsets: UIEdgeInsets { return .zero }
}

class ItemAddingCollectionViewController: CollectionViewController {
    lazy fileprivate var itemAddingViewController: ItemAddingViewController = ItemAddingViewController.instance(from: UIStoryboard(name: "Home", bundle: .main))!
    fileprivate var _images: [UIImage] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView!.contentInset = UIEdgeInsets(top: tabNavigationController!.tabNavigationBar.bounds.height, left: 0, bottom: 0, right: 0)
        itemAddingViewController.loadViewIfNeeded()
        itemAddingViewController.imageAdding = { [unowned self] in
            let imagePicker = TabNavigationImagePickerController(delegate: self) { images in
                
            }
            
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    override func viewDidLoadSetup() {
        super.viewDidLoadSetup()
        
        setTabNavigationTitle(["title": "添加事项", "range": 0..<2])
        
        let selectCategory = TabNavigationTitleActionItem(title: "#选择分类#", target: self, selector: #selector(_handleChooseCategory(_:)))
        selectCategory.tintColor = UIColor.application.blue
        tabNavigationController?.tabNavigationBar.addNavigationTitleActionItem(selectCategory)
        
        let cancel = TabNavigationItem(title: "取消", target: self, selector: #selector(_handleCancelAction(_:)))
        cancel.tintColor = UIColor.application.red
        let complete = TabNavigationItem(title: "完成", target: self, selector: #selector(_handleCompleteAction(_:)))
        setTabNavigationItems([complete, cancel])
        
        collectionView!.register(ItemAddingCollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ItemAddingCollectionReusableView.reusedIdentifier)
        collectionView!.register(CollectionReusableView.self, forSupplementaryViewOfKind: UICollectionElementKindSectionFooter, withReuseIdentifier: _DefaultReusableViewIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if itemAddingViewController.isViewLoaded {
            itemAddingViewController.beginAppearanceTransition(true, animated: animated)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if itemAddingViewController.isViewLoaded {
            itemAddingViewController.endAppearanceTransition()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if itemAddingViewController.isViewLoaded {
            itemAddingViewController.beginAppearanceTransition(false, animated: animated)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if itemAddingViewController.isViewLoaded {
            itemAddingViewController.endAppearanceTransition()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Actions.

extension ItemAddingCollectionViewController {
    @objc
    fileprivate func _handleChooseCategory(_ sender: UIButton) {
        view.endEditing(true)
        print(#function)
    }
    
    @objc
    fileprivate func _handleCancelAction(_ sender: UIButton) {
        view.endEditing(true)
        self.tabNavigationController?.dismiss(animated: true, completion: nil)
    }
    
    @objc
    fileprivate func _handleCompleteAction(_ sender: UIButton) {
        view.endEditing(true)
        self.tabNavigationController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: - CollectionViewDateSource.

extension ItemAddingCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionFooter {
            let footer = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: _DefaultReusableViewIdentifier, for: indexPath)
            footer.backgroundColor = .clear
            return footer
        } else {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader, withReuseIdentifier: ItemAddingCollectionReusableView.reusedIdentifier, for: indexPath)
            header.backgroundColor = .clear
            
            addChildViewController(itemAddingViewController)
            itemAddingViewController.loadViewIfNeeded()
            header.addSubview(itemAddingViewController.view)
            itemAddingViewController.view.frame = CGRect(origin: .zero, size: CGSize(width: collectionView.bounds.width, height: ItemAddingViewController.preferedHeight))
            itemAddingViewController.didMove(toParentViewController: self)
            
            
            return header
        }
    }
}

// MARK: - CollectionViewFlowLayoutDelegate.

extension ItemAddingCollectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: ItemAddingViewController.preferedHeight)
    }
}

// MARK: - TabNavigationImagePickerControllerDelegate.

extension ItemAddingCollectionViewController: TabNavigationImagePickerControllerDelegate {
    func imagePickerWillBeginFetchingAssetCollection(_ imagePicker: TabNavigationImagePickerController) {
        AXPracticalHUD.shared().showSimple(in: self.view.window!)
    }
    
    func imagePickerDidFinishFetchingAssetCollection(_ imagePicker: TabNavigationImagePickerController) {
        AXPracticalHUD.shared().hide(true, afterDelay: 1.0, completion: nil)
    }
}

// MARK: - Storyboard Supporting.

extension ItemAddingCollectionViewController {
    public class var storyboardId: String {
        return "_ItemAddingCollectionViewController"
    }
}

extension ItemAddingCollectionViewController: StoryboardLoadable {
    public class func instance(from storyboard: UIStoryboard) -> Self? {
        return _instanceViewControllerFromStoryboard(storyboard)
    }
    // Private hooks.
    private class func _instanceViewControllerFromStoryboard<T>(_ storyboard: UIStoryboard) -> T? {
        return storyboard.instantiateViewController(withIdentifier: storyboardId) as? T
    }
}

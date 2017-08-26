//
//  Assets.swift
//  TabNavigations/ImagePicker
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Photos

open class AssetsViewController: UICollectionViewController {
    fileprivate var _backgroundFilterView: UIView = UIView()
    fileprivate var _captureDisplayView: CameraViewController.DisplayView = CameraViewController.DisplayView()
    fileprivate var _isViewDidAppear: Bool = false
    fileprivate weak var _captureVideoPreviewCell: AssetsCaptureVideoPreviewCollectionCell? {
        didSet {
            _setupVideoPreviewView()
        }
    }
    fileprivate var _photoAssetCollection: PHAssetCollection!
    
    fileprivate var _photoAssets: PHFetchResult<PHAsset>!
    var imagePickerController: TabNavigationImagePickerController { return tabNavigationController as! TabNavigationImagePickerController }
    
    fileprivate let CameraPresentationAnimator:CameraViewController._PresentationAnimator = .presentation
    fileprivate let CameraDismissalAnimator:CameraViewController._PresentationAnimator = .dismissal
    
    convenience public init(collectionViewLayout layout: UICollectionViewLayout, photoAlbum assetCollection: PHAssetCollection) {
        self.init(collectionViewLayout: layout)
        _photoAssetCollection = assetCollection
        
        // Fetch assets from asset collection.
        let option = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        option.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.image.rawValue)")
        _photoAssets = PHAsset.fetchAssets(in: _photoAssetCollection, options: option)
    }
    
    override public init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        _initializer()
    }
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _initializer()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    
    private func _initializer() {
        _backgroundFilterView.backgroundColor = .white
    }
    
    // Life cycle.
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView!.backgroundColor = .clear
        collectionView!.alwaysBounceVertical = true
        
        setTabNavigationTitle(["title": _photoAssetCollection.localizedTitle ?? "", "range": 0..<2])
        // Register asset collection cell.
        collectionView!.register(AssetsCollectionCell.self, forCellWithReuseIdentifier: String(describing: AssetsCollectionCell.self))
        collectionView!.register(AssetsCaptureVideoPreviewCollectionCell.self, forCellWithReuseIdentifier: String(describing: AssetsCaptureVideoPreviewCollectionCell.self))
        
        collectionView!.contentInset = UIEdgeInsets(top: tabNavigationController!.tabNavigationBar.bounds.height, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView!.scrollIndicatorInsets = collectionView!.contentInset
        collectionView!.allowsMultipleSelection = true
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(_handleOrientationDidChange(_:)), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    override open func prepareForTransition() {
        super.prepareForTransition()
        
        /* if let buffer = imagePickerController._lastSampleBuffer {
         _captureDisplayView.blur(UIImage.image(from: buffer)?.lightBlur)
         } */
    }
    
    override open func viewWillBeginInteractiveTransition() {
        super.viewWillBeginInteractiveTransition()
        
        _updateDisplayViews()
    }
    
    override open func viewDidEndInteractiveTransition(appearing: Bool) {
        super.viewDidEndInteractiveTransition(appearing: appearing)
        
        if !appearing {
            _updateDisplayViews(addition: false)
        }
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        _updateDisplayViews()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _isViewDidAppear = true
        _setupVideoPreviewView()
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        _updateDisplayViews(addition: false)
        _isViewDidAppear = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    func showCamera(_ animated: Bool = true, after delay: TimeInterval = 0.0) {
        guard let cameraView = _captureVideoPreviewCell?.cameraView else { return }
        
        if animated {
            cameraView.alpha = 0.0
            UIView.animate(withDuration: 0.25, delay: delay, options: [], animations: {
                cameraView.alpha = 1.0
            }, completion: nil)
        } else {
            if cameraView.alpha != 1.0 {
                cameraView.alpha = 1.0
            }
        }
    }
    
    func hideCamera(_ animated: Bool = true) {
        guard let cameraView = _captureVideoPreviewCell?.cameraView else { return }
        
        if animated {
            UIView.animate(withDuration: 0.25, delay: 0.0, options: [], animations: {
                cameraView.alpha = 0.0
            }, completion: nil)
        } else {
            if cameraView.alpha != 0.0 {
                cameraView.alpha = 0.0
            }
        }
    }
    
    // MARK: Private.
    fileprivate func _updateDisplayViews(addition: Bool = true) {
        if addition {
            imagePickerController._captureDisplayViews.update(with: _captureDisplayView)
        } else {
            imagePickerController._captureDisplayViews.remove(_captureDisplayView)
        }
    }
    
    fileprivate func _setupVideoPreviewView() {
        // guard _isViewDidAppear else { return }
        
        guard _captureDisplayView.superview !== _captureVideoPreviewCell?.contentView else { return }
        _captureDisplayView.translatesAutoresizingMaskIntoConstraints = false
        _captureVideoPreviewCell?.contentView.addSubview(_captureDisplayView)
        _captureVideoPreviewCell?.contentView.leadingAnchor.constraint(equalTo: _captureDisplayView.leadingAnchor).isActive = true
        _captureVideoPreviewCell?.contentView.trailingAnchor.constraint(equalTo: _captureDisplayView.trailingAnchor).isActive = true
        _captureVideoPreviewCell?.contentView.topAnchor.constraint(equalTo: _captureDisplayView.topAnchor).isActive = true
        _captureVideoPreviewCell?.contentView.bottomAnchor.constraint(equalTo: _captureDisplayView.bottomAnchor).isActive = true
        _captureVideoPreviewCell?.contentView.setNeedsLayout()
        _captureVideoPreviewCell?.contentView.layoutIfNeeded()
    }
}

// MARK: Actions.

extension AssetsViewController {
    @objc
    fileprivate func _handleOrientationDidChange(_ sender: NSNotification) {
        collectionView!.collectionViewLayout.invalidateLayout()
    }
}

// MARK: Overrides.

extension AssetsViewController {
    override public var layoutInsets: UIEdgeInsets { return .zero }
}

extension AssetsViewController {
    override open func makeViewScrollToTopIfNecessary(at location: CGPoint) {
        collectionView!.scrollRectToVisible(CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: collectionView!.bounds.width, height: collectionView!.bounds.height - collectionView!.contentInset.top - collectionView!.contentInset.bottom)), animated: true)
    }
}

extension AssetsViewController {
    fileprivate var _DefaultCollectionSectionInset: CGFloat { return _Resource.Config.Assets.Layouts.sectionInsetValue }
    fileprivate var _DefaultCollectionItemPadding : CGFloat { return _Resource.Config.Assets.Layouts.itemPadding }
    fileprivate var _DefaultCollectionItemColumns : CGFloat { return _Resource.Config.Assets.Layouts.itemColumns }
}
extension AssetsViewController: UICollectionViewDelegateFlowLayout {
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Display 4 columns.
        let size_s = (collectionView.bounds.width - _DefaultCollectionSectionInset * 2.0 - _DefaultCollectionItemPadding * (_DefaultCollectionItemColumns - 1.0)) / _DefaultCollectionItemColumns
        return CGSize(width: size_s, height: size_s)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: _DefaultCollectionSectionInset, left: _DefaultCollectionSectionInset, bottom: _DefaultCollectionSectionInset, right: _DefaultCollectionSectionInset)
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return _DefaultCollectionItemPadding
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return _DefaultCollectionItemPadding
    }
}

// MARK: CollectionViewController Delegate And DataSource Supporting.

extension AssetsViewController {
    override open func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _photoAssets.count + 1
    }
    
    override open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AssetsCaptureVideoPreviewCollectionCell.self), for: indexPath) as! AssetsCaptureVideoPreviewCollectionCell
            _captureVideoPreviewCell = cell
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: AssetsCollectionCell.self), for: indexPath) as! AssetsCollectionCell
        
        let asset = _photoAssets.object(at: indexPath.item - 1)
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .opportunistic
        option.resizeMode = .none
        option.isSynchronous = false
        
        let size_ta = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: indexPath)
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: size_ta.width * UIScreen.main.scale, height: size_ta.height * UIScreen.main.scale), contentMode: .aspectFill, options: option) { (image, info) in
            cell.imageView.image = image
        }
        
        return cell
    }
    
    override open func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override open func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let indexPaths = imagePickerController._selectedIndexPathsOfAssets.flatMap { $0.value }
        if indexPaths.count >= imagePickerController.allowedSelectionCounts {
            return false
        }
        return true
    }
    
    override open func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item != 0 else {
            collectionView.deselectItem(at: indexPath, animated: true)
            // Handle camera actions.
            if let cameraViewController = CameraViewController(previewView: imagePickerController._captureVideoPreviewView, input: imagePickerController._captureDeviceInput) {
                cameraViewController.delegate = self
                cameraViewController.transitioningDelegate = self
                
                let cell = collectionView.cellForItem(at: indexPath)!
                CameraPresentationAnimator.previewOriginFrame = cell.convert(cell.bounds, to: collectionView.window!)
                CameraDismissalAnimator.previewOriginFrame = CameraPresentationAnimator.previewOriginFrame
                hideCamera()
                present(cameraViewController, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: NSLocalizedString("Notice", comment: "Notice"), message: "Failed to open camera service, please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            return
        }
        
        if let indexPaths = imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] {
            var _indexPaths = indexPaths
            _indexPaths.append(indexPath)
            imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] = _indexPaths
        } else {
            imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] = [indexPath]
        }
    }
    
    override open func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let indexPaths = imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] {
            var _indexPaths = indexPaths
            if let index = indexPaths.index(of: indexPath) {
                _indexPaths.remove(at: index)
            }
            imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] = _indexPaths
        }
    }
    
    override open func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is AssetsCaptureVideoPreviewCollectionCell && _isViewDidAppear {
            imagePickerController._captureDisplayQueue.async { [weak self] in
                guard let wself = self else { return }
                // wself._captureDisplayView.isDrawingEnabled = true
                wself.imagePickerController._captureDisplayViews.update(with: wself._captureDisplayView)
            }
        }
    }
    
    override open func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if cell is AssetsCaptureVideoPreviewCollectionCell {
            imagePickerController._captureDisplayQueue.async { [weak self] in
                guard let wself = self else { return }
                // wself._captureDisplayView.isDrawingEnabled = false
                wself.imagePickerController._captureDisplayViews.remove(wself._captureDisplayView)
            }
        }
    }
}

// MARK: CameraViewControllerDelegate Supporting.

extension AssetsViewController: CameraViewControllerDelegate {
    open func cameraViewControllerDidCancel(_ cameraViewController: CameraViewController) {
        // _setupVideoPreviewView()
        showCamera()
    }
}

// MARK: UIViewControllerTransitioningDelegate

extension AssetsViewController: UIViewControllerTransitioningDelegate {
    open func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CameraPresentationAnimator
    }
    
    open func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return CameraDismissalAnimator
    }
}

// MARK: UIScrollViewDelegate.

extension AssetsViewController {
    override open func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _backgroundFilterView.frame = CGRect(x: 0.0, y: min(0.0, collectionView!.contentOffset.y), width: tabNavigationController?.tabNavigationBar.bounds.width ?? 0.0, height: tabNavigationController?.tabNavigationBar.bounds.height ?? 0.0)
    }
}

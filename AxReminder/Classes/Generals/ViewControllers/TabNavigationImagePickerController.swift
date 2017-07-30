//
//  TabNavigationImagePickerController.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/27.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Photos

extension TabNavigationImagePickerController {
    public typealias ImagesResultHandler = (([UIImage]) -> Void)
}

@objc
protocol TabNavigationImagePickerControllerDelegate {
    @objc
    optional func imagePickerWillBeginFetchingAssetCollection(_ imagePicker: TabNavigationImagePickerController)
    @objc
    optional func imagePickerDidFinishFetchingAssetCollection(_ imagePicker: TabNavigationImagePickerController)
}

class TabNavigationImagePickerController: TabNavigationController {
    fileprivate lazy var _photoAssetCollections: [PHAssetCollection] = { () -> [PHAssetCollection] in
        let results = TabNavigationImagePickerController.generatePhotoAssetCollections()
        let option = PHFetchOptions()
        option.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.image.rawValue)")
        let assets = results.objects(at: IndexSet(integersIn: 0..<results.count)).filter{ PHAsset.fetchAssets(in: $0, options: option).count > 0 }.sorted { PHAsset.fetchAssets(in: $0, options: option).count > PHAsset.fetchAssets(in: $1, options: option).count
        }
        return assets
    }()
    fileprivate var _selectedIndexPathsOfAssets: [String: [IndexPath]] = [:]
    open var allowedSelectionCounts: Int = 9
    open weak var delegate: TabNavigationImagePickerControllerDelegate?
    
    fileprivate var imagesResult: ImagesResultHandler?
    
    init(delegate: TabNavigationImagePickerControllerDelegate? = nil, imagesResult: ImagesResultHandler? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.imagesResult = imagesResult
        _initializer()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _initializer()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    
    private func _initializer() {
        isTabNavigationItemsUpdatingDisabledInRootViewControllers = true
        // Enumerate the asset collections.
        willBeginFetchingAssetCollection()
        if !shouldIncludeHiddenAssets {
            _photoAssetCollections = _photoAssetCollections.filter{ $0.assetCollectionSubtype != .smartAlbumAllHidden }
        }
        for assetCollection in _photoAssetCollections {
            // Add image collection view controllers.
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            let assetViewController = _AssetsViewController(collectionViewLayout: flowLayout, photoAlbum: assetCollection)
            self.addViewController(assetViewController)
        }
        didFinishFetchingAssetCollection()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor(colorLiteralRed: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)
        tabNavigationBar.isTranslucent = true
        let cancel = TabNavigationItem(title: "取消", target: self, selector: #selector(_handleCancelAction(_:)))
        tabNavigationBar.navigationItems = [cancel]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: Actions.

extension TabNavigationImagePickerController {
    @objc
    fileprivate func _handleCancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
}

// MARK: - Public.

extension TabNavigationImagePickerController {
    open var shouldIncludeHiddenAssets: Bool { return false }
    
    public func requestAuthorizationIfNeeded() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized: break
        default:
            PHPhotoLibrary.requestAuthorization({ (status) in
                // Handle authorization status.
                print("PHPhotoLibrary.requestAuthorization: \(status)")
            })
        }
    }
    
    open class func generatePhotoAssetCollections() -> PHFetchResult<PHAssetCollection> {
        let option = PHFetchOptions()
        option.includeHiddenAssets = true
        option.includeAllBurstAssets = false
        return PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: option)
    }
    
    open func willBeginFetchingAssetCollection() {
        delegate?.imagePickerWillBeginFetchingAssetCollection?(self)
    }
    
    open func didFinishFetchingAssetCollection() {
        delegate?.imagePickerDidFinishFetchingAssetCollection?(self)
    }
}

fileprivate class _AssetsViewController: UICollectionViewController {
    fileprivate var _backgroundFilterView: UIView = UIView()
    var _photoAssetCollection: PHAssetCollection!
    var _photoAssets: PHFetchResult<PHAsset>!
    var imagePickerController: TabNavigationImagePickerController { return tabNavigationController as! TabNavigationImagePickerController }
    
    convenience init(collectionViewLayout layout: UICollectionViewLayout, photoAlbum assetCollection: PHAssetCollection) {
        self.init(collectionViewLayout: layout)
        _photoAssetCollection = assetCollection
        
        // Fetch assets from asset collection.
        let option = PHFetchOptions()
        option.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        option.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.image.rawValue)")
        _photoAssets = PHAsset.fetchAssets(in: _photoAssetCollection, options: option)
    }
    
    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(collectionViewLayout: layout)
        _initializer()
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _initializer()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    
    private func _initializer() {
        _backgroundFilterView.backgroundColor = .white
    }
    
    // Life cycle.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView!.backgroundColor = .clear
        collectionView!.alwaysBounceVertical = true
        
        setTabNavigationTitle(["title": _photoAssetCollection.localizedTitle ?? "", "range": 0..<2])
        // Register asset collection cell.
        collectionView!.register(_AssetsCollectionCell.self, forCellWithReuseIdentifier: String(describing: _AssetsCollectionCell.self))
        
        collectionView!.contentInset = UIEdgeInsets(top: tabNavigationController!.tabNavigationBar.bounds.height, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView!.scrollIndicatorInsets = collectionView!.contentInset
        collectionView!.allowsMultipleSelection = true
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(_handleOrientationDidChange(_:)), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
}

// MARK: Actions.

extension _AssetsViewController {
    @objc
    fileprivate func _handleOrientationDidChange(_ sender: NSNotification) {
        collectionView!.collectionViewLayout.invalidateLayout()
    }
}

// MARK: Overrides.

extension _AssetsViewController {
    override var layoutInsets: UIEdgeInsets { return .zero }
}

extension _AssetsViewController {
    override func makeViewScrollToTopIfNecessary(at location: CGPoint) {
        collectionView!.scrollRectToVisible(CGRect(origin: CGPoint(x: 0.0, y: 0.0), size: CGSize(width: collectionView!.bounds.width, height: collectionView!.bounds.height - collectionView!.contentInset.top - collectionView!.contentInset.bottom)), animated: true)
    }
}

extension _AssetsViewController {
    fileprivate var _DefaultCollectionSectionInset: CGFloat { return 1.0 }
    fileprivate var _DefaultCollectionItemPadding: CGFloat { return 2.0 }
    fileprivate var _DefaultCollectionItemColumns: CGFloat { return 4.0 }
}
extension _AssetsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Display 4 columns.
        let size_s = (collectionView.bounds.width - _DefaultCollectionSectionInset * 2.0 - _DefaultCollectionItemPadding * (_DefaultCollectionItemColumns - 1.0)) / _DefaultCollectionItemColumns
        return CGSize(width: size_s, height: size_s)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: _DefaultCollectionSectionInset, left: _DefaultCollectionSectionInset, bottom: _DefaultCollectionSectionInset, right: _DefaultCollectionSectionInset)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return _DefaultCollectionItemPadding
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return _DefaultCollectionItemPadding
    }
}

// MARK: - CollectionViewController Delegate And DataSource Supporting.

extension _AssetsViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _photoAssets.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: _AssetsCollectionCell.self), for: indexPath) as! _AssetsCollectionCell
        
        let asset = _photoAssets.object(at: indexPath.item)
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
    
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        let indexPaths = imagePickerController._selectedIndexPathsOfAssets.flatMap { $0.value }
        if indexPaths.count >= imagePickerController.allowedSelectionCounts {
            return false
        }
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let indexPaths = imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] {
            var _indexPaths = indexPaths
            _indexPaths.append(indexPath)
            imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] = _indexPaths
        } else {
            imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] = [indexPath]
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let indexPaths = imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] {
            var _indexPaths = indexPaths
            if let index = indexPaths.index(of: indexPath) {
                _indexPaths.remove(at: index)
            }
            imagePickerController._selectedIndexPathsOfAssets[_photoAssetCollection.localIdentifier] = _indexPaths
        }
    }
}

// MARK: UIScrollViewDelegate.

extension _AssetsViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _backgroundFilterView.frame = CGRect(x: 0.0, y: min(0.0, collectionView!.contentOffset.y), width: tabNavigationController?.tabNavigationBar.bounds.width ?? 0.0, height: tabNavigationController?.tabNavigationBar.bounds.height ?? 0.0)
    }
}

// MARK: _AssetCollectionViewController

extension _AssetsViewController {
    class _AssetsCollectionCell: UICollectionViewCell {
        let imageView: UIImageView = UIImageView()
        let _selectionIndicator = UIImageView(image: #imageLiteral(resourceName: "image_selected"))
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            _initializer()
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            _initializer()
        }
        
        private func _initializer() {
            imageView.translatesAutoresizingMaskIntoConstraints = false
            _selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
            
            contentView.addSubview(imageView)
            contentView.addSubview(_selectionIndicator)
            
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            _selectionIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0).isActive = true
            _selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8.0).isActive = true
            
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            _selectionIndicator.backgroundColor = .clear
            isSelected = false
        }
        
        override func prepareForReuse() {
            super.prepareForReuse()
            
            imageView.image = nil
        }
        
        override var isSelected: Bool {
            didSet {
                if !isSelected {
                    self._selectionIndicator.alpha = 0.0
                    _selectionIndicator.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                } else {
                    _selectionIndicator.alpha = 1.0
                    self._selectionIndicator.transform = .identity
                }
            }
        }
    }
}

extension TabNavigationImagePickerController {
    class _CameraViewController: UIViewController {
        
    }
}

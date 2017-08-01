//
//  TabNavigationImagePickerController.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/27.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import Photos
import AVFoundation

// MARK: - TabNavigationImagePickerController.

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
    
    fileprivate var _captureSession: AVCaptureSession!
    fileprivate var _captureDeviceInput: AVCaptureDeviceInput!
    fileprivate var _captureVideoPreviewView: _CameraViewController._CaptureVideoPreviewView!
    
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
        if let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo), let input = (try? AVCaptureDeviceInput(device: device)) {
            _captureDeviceInput = input
            _captureSession = AVCaptureSession()
            if _captureSession.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
                _captureSession.sessionPreset = AVCaptureSessionPresetPhoto
            }
            _captureSession.addInput(_captureDeviceInput)
            _captureVideoPreviewView = _CameraViewController._CaptureVideoPreviewView(session: _captureSession)
            _captureVideoPreviewView.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            _captureVideoPreviewView.translatesAutoresizingMaskIntoConstraints = false
        }
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
        
        _captureSession.startRunning()
    }
    
    deinit {
        _captureSession.stopRunning()
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

// MARK:  Public.

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

// MARK: - _AssetsViewController.

fileprivate class _AssetsViewController: UICollectionViewController {
    fileprivate var _backgroundFilterView: UIView = UIView()
    fileprivate var _isViewDidAppear: Bool = false
    fileprivate weak var _captureVideoPreviewCell: _AssetsCaptureVideoPreviewCollectionCell? {
        didSet {
            _setupVideoPreviewView()
        }
    }
    var _photoAssetCollection: PHAssetCollection!
    
    var _photoAssets: PHFetchResult<PHAsset>!
    var imagePickerController: TabNavigationImagePickerController { return tabNavigationController as! TabNavigationImagePickerController }
    
    let _cameraPresentationAnimator:_CameraViewController._PresentationAnimator = .presentation
    let _cameraDismissalAnimator:_CameraViewController._PresentationAnimator = .dismissal
    
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
        collectionView!.register(_AssetsCaptureVideoPreviewCollectionCell.self, forCellWithReuseIdentifier: String(describing: _AssetsCaptureVideoPreviewCollectionCell.self))
        
        collectionView!.contentInset = UIEdgeInsets(top: tabNavigationController!.tabNavigationBar.bounds.height, left: 0.0, bottom: 0.0, right: 0.0)
        collectionView!.scrollIndicatorInsets = collectionView!.contentInset
        collectionView!.allowsMultipleSelection = true
        
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(_handleOrientationDidChange(_:)), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        _isViewDidAppear = true
        _setupVideoPreviewView()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        _isViewDidAppear = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    
    // MARK: Private.
    fileprivate func _setupVideoPreviewView() {
        guard _isViewDidAppear else { return }
        
        if let previewView = imagePickerController._captureVideoPreviewView {
            previewView.translatesAutoresizingMaskIntoConstraints = false
            _captureVideoPreviewCell?.contentView.addSubview(previewView)
            _captureVideoPreviewCell?.contentView.leadingAnchor.constraint(equalTo: previewView.leadingAnchor).isActive = true
            _captureVideoPreviewCell?.contentView.trailingAnchor.constraint(equalTo: previewView.trailingAnchor).isActive = true
            _captureVideoPreviewCell?.contentView.topAnchor.constraint(equalTo: previewView.topAnchor).isActive = true
            _captureVideoPreviewCell?.contentView.bottomAnchor.constraint(equalTo: previewView.bottomAnchor).isActive = true
            _captureVideoPreviewCell?.contentView.setNeedsLayout()
            _captureVideoPreviewCell?.contentView.layoutIfNeeded()
        }
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

// MARK: CollectionViewController Delegate And DataSource Supporting.

extension _AssetsViewController {
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _photoAssets.count + 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: _AssetsCaptureVideoPreviewCollectionCell.self), for: indexPath) as! _AssetsCaptureVideoPreviewCollectionCell
            _captureVideoPreviewCell = cell
            return cell
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: _AssetsCollectionCell.self), for: indexPath) as! _AssetsCollectionCell
        
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
        guard indexPath.item != 0 else {
            collectionView.deselectItem(at: indexPath, animated: true)
            // Handle camera actions.
            if let cameraViewController = _CameraViewController(previewView: imagePickerController._captureVideoPreviewView, input: imagePickerController._captureDeviceInput) {
                cameraViewController.delegate = self
                cameraViewController.transitioningDelegate = self
                
                let cell = collectionView.cellForItem(at: indexPath)!
                _cameraPresentationAnimator.previewOriginFrame = cell.convert(cell.bounds, to: collectionView.window!)
                _cameraDismissalAnimator.previewOriginFrame = _cameraPresentationAnimator.previewOriginFrame
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

// MARK: _CameraViewControllerDelegate Supporting.

extension _AssetsViewController: _CameraViewControllerDelegate {
    func cameraViewControllerDidCancel(_ cameraViewController: _CameraViewController) {
        _setupVideoPreviewView()
    }
}

// MARK: UIViewControllerTransitioningDelegate

extension _AssetsViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return _cameraPresentationAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return _cameraDismissalAnimator
    }
}

// MARK: UIScrollViewDelegate.

extension _AssetsViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        _backgroundFilterView.frame = CGRect(x: 0.0, y: min(0.0, collectionView!.contentOffset.y), width: tabNavigationController?.tabNavigationBar.bounds.width ?? 0.0, height: tabNavigationController?.tabNavigationBar.bounds.height ?? 0.0)
    }
}

// MARK: _AssetsCollectionCell.

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

// MARK: _AssetsCaptureVideoPreviewCollectionCell.

extension _AssetsViewController {
    class _AssetsCaptureVideoPreviewCollectionCell: UICollectionViewCell {
        let cameraView: UIImageView = UIImageView(image: #imageLiteral(resourceName: "camera"))
        let placeholder: UIImageView = UIImageView()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            _initializer()
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            _initializer()
        }
        private func _initializer() {
            contentView.clipsToBounds = true
            contentView.backgroundColor = .black
            placeholder.backgroundColor = .clear
            cameraView.tintColor = UIColor.white.withAlphaComponent(0.8)
            
            placeholder.translatesAutoresizingMaskIntoConstraints = false
            cameraView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(placeholder)
            addSubview(cameraView)
            
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[placeholder]|", options: [], metrics: nil, views: ["placeholder":placeholder]))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[placeholder]|", options: [], metrics: nil, views: ["placeholder":placeholder]))
            cameraView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            cameraView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
    }
}

// MARK: - _CameraViewController.

@objc
fileprivate protocol _CameraViewControllerDelegate {
    @objc optional func cameraViewControllerDidCancel(_ cameraViewController: _CameraViewController)
}

@available(iOS 9.0, *)
fileprivate class _CameraViewController: UIViewController {
    weak var delegate: _CameraViewControllerDelegate?
    var stopSessionWhenDisposed: Bool = false
    
    var _session: AVCaptureSession!
    var _input: AVCaptureDeviceInput!
    var _output: AVCapturePhotoOutput!
    
    var _previewView: _CaptureVideoPreviewView!
    
    // MARK: Tool Views.
    
    lazy var _topBar: _CameraViewController._TopBar = { () -> _TopBar in
        let topBar = _TopBar()
        topBar.tintColor = .white
        topBar.backgroundColor = .black
        topBar.translatesAutoresizingMaskIntoConstraints = false
        return topBar
    }()
    lazy var _bottomBar: _CameraViewController._BottomBar = { () -> _BottomBar in
        let bottomBar = _BottomBar()
        bottomBar.tintColor = .white
        bottomBar.backgroundColor = .black
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        return bottomBar
    }()
    
    // MARK: Initializer.
    init?(previewView: _CaptureVideoPreviewView? = nil, session: AVCaptureSession? = nil, input: AVCaptureDeviceInput? = nil) {
        guard let __input = input ?? (try? AVCaptureDeviceInput(device: AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo))) else {
            return nil
        }
        _session = session ?? previewView?.previewLayer.session ?? AVCaptureSession()
        if previewView?.previewLayer.session === _session {
            _previewView = previewView
        }
        _input = __input
        _output = AVCapturePhotoOutput()
        
        super.init(nibName: nil, bundle: nil)
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
        _configureSession()
        if _previewView == nil {
            _previewView = _CaptureVideoPreviewView(session: _session)
        }
    }
    
    // MARK: LifeCycle.
    override func loadView() {
        super.loadView()
        view.addSubview(_previewView)
        _previewView.translatesAutoresizingMaskIntoConstraints = false
        _previewView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        _previewView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        _previewView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        _previewView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        _setupTopBar()
        _setupBottomBar()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start the session when view will appear if necessary.
        if !_session.isRunning {
            _session.startRunning()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop the session when view did disappear.
        if stopSessionWhenDisposed {
            _session.stopRunning()
        }
    }
    
    // MARK: Private.
    
    private func _configureSession() {
        if _session.inputs.isEmpty || _session.canAddInput(_input) {
            _session.addInput(_input)
        }
        if _session.outputs.isEmpty || _session.canAddOutput(_output) {
            _session.addOutput(_output)
        }
    }
    
    private func _setupTopBar() {
        view.addSubview(_topBar)
        _topBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        _topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        _topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        _topBar.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
    }
    
    private func _setupBottomBar() {
        _bottomBar._shot.addTarget(self, action: #selector(_handleShot(_:)), for: .touchUpInside)
        _bottomBar._toggleFace.addTarget(self, action: #selector(_handleToggleFace(_:)), for: .touchUpInside)
        _bottomBar._cancel.addTarget(self, action: #selector(_handleCancel(_:)), for: .touchUpInside)
        
        view.addSubview(_bottomBar)
        _bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        _bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        _bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        _bottomBar.heightAnchor.constraint(equalToConstant: 96.0).isActive = true
    }
}

// MARK: Actions. 

extension _CameraViewController {
    @objc
    fileprivate func _handleShot(_ sender: UIButton) {
        
    }
    
    @objc
    fileprivate func _handleToggleFace(_ sender: UIButton) {
        
    }
    
    @objc
    fileprivate func _handleCancel(_ sender: UIButton) {
        dismiss(animated: true) { [unowned self] in
            self.delegate?.cameraViewControllerDidCancel?(self)
        }
    }
}

// MARK: Status Bar Supporting.

extension _CameraViewController {
    override var prefersStatusBarHidden: Bool { return true }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

// MARK: _CaptureVideoPreviewView.

extension _CameraViewController {
    class _CaptureVideoPreviewView: UIView {
        override class var layerClass: AnyClass { return AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { return layer as! AVCaptureVideoPreviewLayer }
        
        init(session: AVCaptureSession) {
            super.init(frame: .zero)
            previewLayer.session = session
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: _TopBar.

extension _CameraViewController {
    @available(iOS 9.0, *)
    class _TopBar: UIView {
        lazy var _stackView: UIStackView = { () -> UIStackView in
            let stackView = UIStackView()
            stackView.backgroundColor = .clear
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.axis = .horizontal
            stackView.distribution = .equalSpacing
            stackView.alignment = .center
            return stackView
        }()
        lazy var _flash: UIButton = { () -> UIButton in
            let flash = UIButton(type: .custom)
            flash.translatesAutoresizingMaskIntoConstraints = false
            flash.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
            flash.adjustsImageWhenDisabled = false
            flash.adjustsImageWhenHighlighted = false
            flash.setImage(#imageLiteral(resourceName: "flash_auto"), for: .normal)
            return flash
        }()
        lazy var _flash2: UIButton = { () -> UIButton in
            let flash = UIButton(type: .custom)
            flash.translatesAutoresizingMaskIntoConstraints = false
            flash.setContentHuggingPriority(UILayoutPriorityRequired, for: .horizontal)
            flash.adjustsImageWhenDisabled = false
            flash.adjustsImageWhenHighlighted = false
            flash.setImage(#imageLiteral(resourceName: "flash_on"), for: .normal)
            return flash
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            _initializer()
        }
        required init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            _initializer()
        }
        private func _initializer() {
            _setupStackView()
            _setupContentViews()
        }
        
        private func _setupStackView() {
            addSubview(_stackView)
            _stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15.0).isActive = true
            _stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -15.0).isActive = true
            _stackView.topAnchor.constraint(equalTo: topAnchor).isActive = true
            _stackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        
        private func _setupContentViews() {
            _stackView.addArrangedSubview(_flash)
            _stackView.addArrangedSubview(_flash2)
        }
    }
}

// MARK: _BottomBar.

extension _CameraViewController {
    class _BottomBar: UIView {
        let _shot: UIButton = UIButton(type: .system)
        let _toggleFace: UIButton = UIButton(type: .system)
        let _cancel: UIButton = UIButton(type: .system)
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            _initializer()
        }
        
        required init?(coder aDecoder: NSCoder) {
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

extension _CameraViewController {
    class _PresentationAnimator: NSObject {
        var isDismissal: Bool = false
        var previewOriginFrame: CGRect = .zero
        
        class var presentation: _PresentationAnimator { return _PresentationAnimator() }
        class var dismissal: _PresentationAnimator {
            let dismissal = _PresentationAnimator()
            dismissal.isDismissal = true
            return dismissal
        }
    }
}

extension _CameraViewController._PresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isDismissal ? 0.25 : 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        let containerView = transitionContext.containerView
        let view = transitionContext.view(forKey: isDismissal ? .from : .to)!
        let viewController = transitionContext.viewController(forKey: isDismissal ? .from : .to)! as! _CameraViewController
        let finalFrame = transitionContext.finalFrame(for: viewController)
        
        containerView.addSubview(view)
        let scale = CGPoint(x: previewOriginFrame.width / finalFrame.width, y: previewOriginFrame.height / finalFrame.height)
        let translation = CGPoint(x: previewOriginFrame.midX - finalFrame.midX, y: previewOriginFrame.midY - finalFrame.midY)
        
        if isDismissal {
            containerView.insertSubview(transitionContext.view(forKey: .to)!, at: 0)
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [], animations: {
                view.transform = CGAffineTransform(scaleX: scale.x, y: scale.y).translatedBy(x: translation.x / scale.x, y: translation.y / scale.y)
                viewController._topBar.alpha = 0.0
                viewController._bottomBar.alpha = 0.0
            }) { (finished) in
                if finished {
                    transitionContext.completeTransition(true)
                }
            }
        } else {
            view.transform = CGAffineTransform(scaleX: scale.x, y: scale.y).translatedBy(x: translation.x / scale.x, y: translation.y / scale.y)
            viewController._topBar.alpha = 0.0
            viewController._bottomBar.alpha = 0.0
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
                view.transform = .identity
                viewController._topBar.alpha = 1.0
                viewController._bottomBar.alpha = 1.0
            }) { (finished) in
                if finished {
                    transitionContext.completeTransition(true)
                }
            }
        }
    }
}

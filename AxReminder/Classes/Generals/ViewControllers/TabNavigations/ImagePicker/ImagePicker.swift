//
//  ImagePicker.swift
//  TabNavigations/ImagePicker
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

@objc public protocol TabNavigationImagePickerControllerDelegate {
    @objc
    optional func imagePickerWillBeginFetchingAssetCollection(_ imagePicker: TabNavigationImagePickerController)
    @objc
    optional func imagePickerDidFinishFetchingAssetCollection(_ imagePicker: TabNavigationImagePickerController)
}

open class TabNavigationImagePickerController: TabNavigationController {
    fileprivate lazy var _photoAssetCollections: [PHAssetCollection] = { () -> [PHAssetCollection] in
        let results = TabNavigationImagePickerController.generatePhotoAssetCollections()
        let option = PHFetchOptions()
        option.predicate = NSPredicate(format: "mediaType == \(PHAssetMediaType.image.rawValue)")
        let assets = results.objects(at: IndexSet(integersIn: 0..<results.count)).filter{ PHAsset.fetchAssets(in: $0, options: option).count > 0 }.sorted { PHAsset.fetchAssets(in: $0, options: option).count > PHAsset.fetchAssets(in: $1, options: option).count
        }
        return assets
    }()
    // ---
    internal    var _selectedIndexPathsOfAssets: [String: [IndexPath]] = [:]
    open        var allowedSelectionCounts     : Int = 9
    open weak   var delegate                   : TabNavigationImagePickerControllerDelegate?
    // ---
    fileprivate var _captureSession            : AVCaptureSession!
    fileprivate let _captureSessionQueue       = DispatchQueue(label: "com.imagepicker.session")
    internal    var _captureDeviceInput        : AVCaptureDeviceInput!
    fileprivate let _captureDisplayOutput      = AVCaptureVideoDataOutput()
    internal    var _captureDisplayViews       : Set<CameraViewController.DisplayView> = []
    internal    let _captureDisplayQueue       = DispatchQueue(label: "com.imagepicker.display.render")
    internal    var _captureVideoPreviewView   : CameraViewController.PreviewView!
    // ---
    fileprivate var _lastSampleBuffer          : CMSampleBuffer!
    // ---
    fileprivate var imagesResult               : ImagesResultHandler?
    
    public init(delegate: TabNavigationImagePickerControllerDelegate? = nil, imagesResult: ImagesResultHandler? = nil) {
        super.init(nibName: nil, bundle: nil)
        self.delegate = delegate
        self.imagesResult = imagesResult
        _initializer()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _initializer()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    
    private func _initializer() {
        isTabNavigationItemsUpdatingDisabledInRootViewControllers = true
        // Enumerate the asset collections.
        willBeginFetchingAssetCollection()
        _initSession()
        if !shouldIncludeHiddenAssets {
            _photoAssetCollections = _photoAssetCollections.filter{ $0.assetCollectionSubtype != .smartAlbumAllHidden }
        }
        for assetCollection in _photoAssetCollections {
            // Add image collection view controllers.
            let flowLayout = UICollectionViewFlowLayout()
            flowLayout.scrollDirection = .vertical
            let assetViewController = AssetsViewController(collectionViewLayout: flowLayout, photoAlbum: assetCollection)
            self.addViewController(assetViewController)
            // _captureDisplayViews.append(assetViewController._captureDisplayView)
        }
        didFinishFetchingAssetCollection()
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor(colorLiteralRed: 0.976, green: 0.976, blue: 0.976, alpha: 1.0)
        tabNavigationBar.isTranslucent = true
        let cancel = TabNavigationItem(title: "取消", target: self, selector: #selector(_handleCancelAction(_:)))
        tabNavigationBar.navigationItems = [cancel]
        
        _captureSession?.startRunning()
    }
    
    deinit {
        _captureSession?.stopRunning()
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: Private.

extension TabNavigationImagePickerController {
    fileprivate func _initSession() {
        _captureSessionQueue.async { [weak self] in
            guard let wself = self else { return }
            if let device = type(of: wself).defaultDeviceOfCaptureSessionInputs() {
                do {
                    wself._captureDeviceInput = try AVCaptureDeviceInput(device: device)
                    
                    wself._captureDisplayOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
                    wself._captureDisplayOutput.setSampleBufferDelegate(wself, queue: wself._captureDisplayQueue)
                    wself._captureDisplayOutput.alwaysDiscardsLateVideoFrames = true
                    
                    wself._captureSession = AVCaptureSession()
                    if wself._captureSession.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
                        wself._captureSession.sessionPreset = AVCaptureSessionPresetPhoto
                    }
                    if wself._captureSession.canAddInput(wself._captureDeviceInput) {
                        wself._captureSession.addInput(wself._captureDeviceInput)
                    }
                    if wself._captureSession.canAddOutput(wself._captureDisplayOutput) {
                        wself._captureSession.addOutput(wself._captureDisplayOutput)
                    }
                    
                    DispatchQueue.main.async {
                        wself._captureVideoPreviewView = CameraViewController.PreviewView(session: wself._captureSession)
                        wself._captureVideoPreviewView.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
                        wself._captureVideoPreviewView.translatesAutoresizingMaskIntoConstraints = false
                    }
                } catch let error {
                    print("The input for the specific device is not avaiable: \(error)")
                }
            } else {
                print("The current default device of the specific media type is not available.")
            }
        }
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
    
    open class func defaultDeviceOfCaptureSessionInputs() -> AVCaptureDevice? {
        guard let device = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo) else { return nil }
        // Configure the default device.
        DispatchQueue(label: "com.device.initializer.config").async {
            do {
                try device.lockForConfiguration()
                
                device.isSubjectAreaChangeMonitoringEnabled = true
                
                if device.isFlashModeSupported(.auto) {
                    device.flashMode = .auto
                }
                
                device.unlockForConfiguration()
            } catch {
                print(error)
            }
        }
        return device
    }
    
    open func willBeginFetchingAssetCollection() {
        delegate?.imagePickerWillBeginFetchingAssetCollection?(self)
    }
    
    open func didFinishFetchingAssetCollection() {
        delegate?.imagePickerDidFinishFetchingAssetCollection?(self)
    }
}

extension TabNavigationImagePickerController {
    fileprivate class var resourceBundlePath: String { return String(describing: self) + ".bundle/" }
}

// MARK: AVCaptureVideoDataOutputSampleBufferDelegate.

extension TabNavigationImagePickerController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        // print("Count of display views: \(_captureDisplayViews.count)")
        // _lastSampleBuffer = sampleBuffer
        guard RunLoop.main.currentMode != .UITrackingRunLoopMode else {
            self._captureDisplayViews.forEach({ (displayView) in
                if !displayView.blured {
                    let image = UIImage.image(from: sampleBuffer)?.lightBlur
                    displayView.blur(image, duration: 0.05)
                }
            })
            return
        }
        autoreleasepool{ _captureDisplayQueue.async { [weak self] in self?._captureDisplayViews.forEach({ if $0.blured { $0.unBlur() }; $0.draw(buffer: sampleBuffer) }) } }
    }
}

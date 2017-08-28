//
//  Camera.swift
//  TabNavigations/ImagePicker
//
//  Created by devedbox on 2017/8/24.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation

@objc public protocol CameraViewControllerDelegate {
    @objc optional func cameraViewControllerDidCancel(_ cameraViewController: CameraViewController)
}

@available(iOS 9.0, *)
open class CameraViewController: UIViewController {
    open weak var delegate: CameraViewControllerDelegate?
    open   var stopSessionWhenDisposed: Bool = false
    public var configurationQueue: DispatchQueue { return _sessionQueue }
    /// Sample buffer delegates queue.
    fileprivate
    var _sampleBufferDelegates: NSHashTable<AVCaptureVideoDataOutputSampleBufferDelegate> = NSHashTable.weakObjects()
    
    private var _session: AVCaptureSession!
    private var _input  : AVCaptureDeviceInput!
    private var _output : AVCapturePhotoOutput!
    
    public var previewView: CaptureVideoPreviewView! { return _previewView }
    fileprivate var _previewView: CaptureVideoPreviewView!
    
    // MARK: Tool Views.
    
    private let _flashConfigs: [(title: String, image: UIImage)] = [("自动", #imageLiteral(resourceName: "flash_auto")), ("打开", #imageLiteral(resourceName: "flash_on")), ("关闭", #imageLiteral(resourceName: "flash_off"))]
    private let _hdrConfigs: [(title: String, image: UIImage)] = [("自动", UIImage(named: _Resource.bundle+"HDR_auto")!), ("打开", UIImage(named: _Resource.bundle+"HDR_on")!), ("关闭", UIImage(named: _Resource.bundle+"HDR_off")!)]
    public var topBar: TopBar { return _topBar }
    fileprivate lazy var _topBar: TopBar = { () -> TopBar in
        let topBar = TopBar()
        topBar.tintColor = .white
        topBar.backgroundColor = .black
        topBar.translatesAutoresizingMaskIntoConstraints = false
        return topBar
    }()
    public var bottomBar: BottomBar { return _bottomBar }
    fileprivate lazy var _bottomBar: BottomBar = { () -> BottomBar in
        let bottomBar = BottomBar()
        bottomBar.tintColor = .white
        bottomBar.backgroundColor = .black
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        return bottomBar
    }()
    
    // MARK: Initializer.
    public init?(previewView: CaptureVideoPreviewView? = nil, session: AVCaptureSession? = nil, input: AVCaptureDeviceInput? = nil) {
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
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        _initializer()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    
    private func _initializer() {
        _configureSession()
        if _previewView == nil {
            _previewView = PreviewView(session: _session)
        }
    }
    
    // MARK: LifeCycle.
    override open func loadView() {
        super.loadView()
        view.addSubview(_previewView)
        _previewView.isUserInteractionEnabled = true
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
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        _previewView.infoContentInsets = UIEdgeInsets(top: _topBar.bounds.height, left: 0.0, bottom: _bottomBar.bounds.height, right: 0.0)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Start the session when view will appear if necessary.
        if !_session.isRunning {
            _session.startRunning()
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop the session when view did disappear.
        if stopSessionWhenDisposed {
            _session.stopRunning()
        }
    }
    
    // MARK: Private.
    
    private func _initSession() throws {
        // Initialize the device input for the session.
        var adevice: AVCaptureDevice!
        if #available(iOS 10.0, *) {
            adevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
        } else {
            adevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
        }
        guard let device = adevice else { throw CameraError.initializing(.noneOfCaptureDevice) }
        
        _input = try AVCaptureDeviceInput(device: device)
        // Configure the display out put.
        _displayOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
        _displayOutput.setSampleBufferDelegate(self, queue: _displayQueue)
        _displayOutput.alwaysDiscardsLateVideoFrames = true
        // Initialize and configure the session of the capture.
        _session = AVCaptureSession()
        if _session.canSetSessionPreset(AVCaptureSessionPresetPhoto) {
            _session.sessionPreset = AVCaptureSessionPresetPhoto
        }
        
    }
    
    private func _configureSession() {
        _sessionQueue.async { [weak self] in autoreleasepool{
            guard let wself = self else { return }
            if wself._session.canAddInput(wself._input) {
                wself._session.addInput(wself._input)
            }
            if wself._session.canAddOutput(wself._output) {
                wself._session.addOutput(wself._output)
            }
            if wself._session.canAddOutput(wself._displayOutput) {
                wself._session.addOutput(wself._displayOutput)
            }
        } }
    }
    
    private func _setupTopBar() {
        view.addSubview(_topBar)
        _topBar.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        _topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        _topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        _topBar.heightAnchor.constraint(equalToConstant: 44.0).isActive = true
        // Set up items.
        let flash = BarItem(image: #imageLiteral(resourceName: "flash_auto"), actions: _flashConfigs.map({ BarItem(title: $0.title) }))
        let hdr = BarItem(image: _hdrConfigs.first!.image, actions: _hdrConfigs.map({ BarItem(title: $0.title) }))
        _topBar.items = [flash, hdr, BarItem(title: "item2"), BarItem(title: "item3"), BarItem(title: "item4"), BarItem(title: "item5")]
        _topBar.didSelectAction = { [unowned self] itemIndex, selectedIndex in
            switch itemIndex {
            case 0: // Flash.
                self._topBar.updateImage(self._flashConfigs[selectedIndex].image, ofItemAtIndex: itemIndex)
            case 1: // HDR.
                self._topBar.updateImage(self._hdrConfigs[selectedIndex].image, ofItemAtIndex: itemIndex)
            default: break
            }
        }
    }
    
    private func _setupBottomBar() {
        _bottomBar.shot.addTarget(self, action: #selector(_handleShot(_:)), for: .touchUpInside)
        _bottomBar.toggle.addTarget(self, action: #selector(_handleToggleFace(_:)), for: .touchUpInside)
        _bottomBar.cancel.addTarget(self, action: #selector(_handleCancel(_:)), for: .touchUpInside)
        
        view.addSubview(_bottomBar)
        _bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        _bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        _bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        _bottomBar.heightAnchor.constraint(equalToConstant: 96.0).isActive = true
    }
}

// MARK: Actions.

extension CameraViewController {
    @objc
    fileprivate func _handleShot(_ sender: UIButton) {
        
    }
    
    @objc fileprivate func _handleToggleFace(_ sender: UIButton) { let _ = try? _previewView.toggle() }
    
    @objc
    fileprivate func _handleCancel(_ sender: UIButton) {
        dismiss(animated: true) { [unowned self] in
            self.delegate?.cameraViewControllerDidCancel?(self)
        }
    }
}

// MARK: Status Bar Supporting.

extension CameraViewController {
    override open var prefersStatusBarHidden: Bool { return true }
    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation { return .fade }
}

// MARK: - CaptureVideoPreviewView.

extension CameraViewController {
    public final class PreviewView: CaptureVideoPreviewView {}
}

// MARK: - CaptureVideoDisplayView.

extension CameraViewController {
    public final class DisplayView: CaptureVideoDisplayView {}
}

// MARK: - Sample buffer delegates.

extension CameraViewController {
    /// Get all the sample buffer delegate as `[AVCaptureVideoDataOutputSampleBufferDelegate]`.
    /// Do not add or remove delegates using the the result since the result is copied.
    ///
    public var  sampleBufferDelegates: [AVCaptureVideoDataOutputSampleBufferDelegate] { return _sampleBufferDelegates.allObjects }
    /// Replace the old managed sample buffer delegates with the new delegates.
    /// 
    /// - Parameter sampleBufferDelegates: The new delegates queue to replace with.
    ///
    public func set(sampleBufferDelegates delegates: [AVCaptureVideoDataOutputSampleBufferDelegate]) {
        removeAllSampleBufferDelegates()
        add(sampleBufferDelegates: delegates)
    }
    /// Add a delegates queue to the managed delegates queue without changing the orders.
    ///
    /// - Parameter sampleBufferDelegates: The new delegates queue to add.
    ///
    public func add(sampleBufferDelegates delegates: [AVCaptureVideoDataOutputSampleBufferDelegate]) {
        delegates.forEach({ [unowned self] in self._sampleBufferDelegates.add($0) })
    }
    /// Add a new sample buffer delegate to the managed delegates queue.
    ///
    /// - Parameter sampleBufferDelegate: A instance of AVCaptureVideoDataOutputSampleBufferDelegate to be added.
    ///
    public func add(sampleBufferDelegate delegate: AVCaptureVideoDataOutputSampleBufferDelegate?) {
        _sampleBufferDelegates.add(delegate)
    }
    /// Remove a sample buffer from the managed delegates queue.
    ///
    /// - Parameter sampleBufferDelegate: A instance of AVCaptureVideoDataOutputSampleBufferDelegate to be removed.
    ///
    public func remove(sampleBufferDelegate delegate: AVCaptureVideoDataOutputSampleBufferDelegate?) {
        _sampleBufferDelegates.remove(delegate)
    }
    /// Remove all the managed sample buffer delegates.
    public func removeAllSampleBufferDelegates() {
        _sampleBufferDelegates.removeAllObjects()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate.

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        sampleBufferDelegates.forEach({ $0.captureOutput?(captureOutput, didOutputSampleBuffer: sampleBuffer, from: connection) })
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput!, didDrop sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        sampleBufferDelegates.forEach({ $0.captureOutput?(captureOutput, didDrop: sampleBuffer, from: connection) })
    }
}

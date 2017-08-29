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
/// A type subclassing `UIViewController` to manage the data, session, inputs and outputs of camera capture device.
///
@available(iOS 9.0, *)
open class CameraViewController: UIViewController {
    weak
    open   var delegate               : CameraViewControllerDelegate?
    open   var stopSessionWhenDisposed: Bool = false
    /// Sample buffer delegates queue.
    fileprivate
    var _sampleBufferDelegates: NSHashTable<AVCaptureVideoDataOutputSampleBufferDelegate> = NSHashTable.weakObjects()
    // ------------------------------------
    // Capture session, inputs and outputs.
    // ------------------------------------
    public      var  captureSession        : AVCaptureSession!        { return _session               }
    fileprivate var _session               : AVCaptureSession!        { didSet { _initPreviewView() } }
    public      var  captureSessionQueue   : DispatchQueue            { return _sessionQueue          }
    fileprivate let _sessionQueue          : DispatchQueue            = DispatchQueue(label: "com.config.session.camera")
    public      var  captureDeviceInput    : AVCaptureDeviceInput!    { return _input                 }
    fileprivate var _input                 : AVCaptureDeviceInput!
    @available(iOS 10.0, *)
    public      var  capturePhotoOutput    : AVCapturePhotoOutput!    { return _photoOutput as! AVCapturePhotoOutput  }
    fileprivate var _photoOutput           : Any! = { if #available(iOS 10.0, *) { return AVCapturePhotoOutput() } else { return nil } }()
    public      var  captureDisplayQueue   : DispatchQueue            { return _displayQueue          }
    fileprivate let _displayQueue          : DispatchQueue            = DispatchQueue(label: "com.render.display.camera")
    public      var  captureVideoDataOutput: AVCaptureVideoDataOutput { return _displayOutput         }
    fileprivate var _displayOutput         : AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
    // ------------------------------------
    // Capture video preview view.
    // ------------------------------------
    public      var  previewView: CaptureVideoPreviewView! { return _previewView }
    fileprivate var _previewView: CaptureVideoPreviewView!
    // ------------------------------------
    // Flash and hrd items configs.
    // ------------------------------------
    private let _flashConfigs: [(title: String, image: UIImage)] = [("自动", UIImage(named: _Resource.bundle+"flash_auto")!), ("打开", UIImage(named: _Resource.bundle+"flash_on")!), ("关闭", UIImage(named: _Resource.bundle+"flash_off")!)]
    private let _hdrConfigs  : [(title: String, image: UIImage)] = [("自动", UIImage(named: _Resource.bundle+"HDR_auto")!), ("打开", UIImage(named: _Resource.bundle+"HDR_on")!), ("关闭", UIImage(named: _Resource.bundle+"HDR_off")!)]
    // ------------------------------------
    // Top and bottom tool bars.
    // ------------------------------------
    public           var  topBar: TopBar   { return _topBar }
    fileprivate lazy var _topBar: TopBar = { () -> TopBar in
        let topBar = TopBar()
        topBar.tintColor = .white
        topBar.backgroundColor = .black
        topBar.translatesAutoresizingMaskIntoConstraints = false
        return topBar
    }()
    
    public           var  bottomBar: BottomBar   { return _bottomBar }
    fileprivate lazy var _bottomBar: BottomBar = { () -> BottomBar in
        let bottomBar = BottomBar()
        bottomBar.tintColor = .white
        bottomBar.backgroundColor = .black
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        return bottomBar
    }()
    
    private var _startingOfSession: SessionStarting
    
    // MARK: Initializer.
    public init?(session: AVCaptureSession? = nil, starting: SessionStarting = .never) throws {
        self._startingOfSession = starting
        self._session = session
        super.init(nibName: nil, bundle: nil)
        try _initSession()
        // Start the session immediately if the starting mode is `.immediately`.
        switch _startingOfSession {
        case .immediately:
            if !_session.isRunning {
                _session.startRunning()
            }
        default: break
        }
    }
    
    public init() {
        fatalError("Using designated initializer to create instance.")
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError("Using designated initializer to create instance.")
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("Using designated initializer to create instance.")
    }
    
    deinit {
        switch _startingOfSession {
        case .immediately: fallthrough
        case .at(_)  :
            if  _session.isRunning, stopSessionWhenDisposed {
                _session.stopRunning()
            }
        default: break
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
        
        // Start the session immediately if the starting mode is `.at(.loading)`.
        switch _startingOfSession {
        case .at(.loading):
            if !_session.isRunning {
                _session.startRunning()
            }
        default: break
        }
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .black
        // Start the session immediately if the starting mode is `.at(.loaded)`.
        switch _startingOfSession {
        case .at(.loaded):
            if !_session.isRunning {
                _session.startRunning()
            }
        default: break
        }
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        _previewView.infoContentInsets = UIEdgeInsets(top: _topBar.bounds.height, left: 0.0, bottom: _bottomBar.bounds.height, right: 0.0)
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start the session immediately if the starting mode is `.at(.willAppear)`.
        switch _startingOfSession {
        case .at(.willAppear):
            if !_session.isRunning {
                _session.startRunning()
            }
        default: break
        }
    }
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Start the session immediately if the starting mode is `.at(.didAppear)`.
        switch _startingOfSession {
        case .at(.didAppear):
            if !_session.isRunning {
                _session.startRunning()
            }
        default: break
        }
    }
    
    override open func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        // Stop the session when view did disappear.
        /* if stopSessionWhenDisposed {
            _session.stopRunning()
        } */
    }
    
    // MARK: Private.
    
    /// Create session and device input if session is nil and device inputs of session is empty.
    private func _initSession() throws {
        func create_add_input() throws {
            var adevice:  AVCaptureDevice!
            if #available(iOS 10.0, *) {
                adevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
            } else {
                adevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
            }
            guard let device = adevice else { throw CameraError.initializing(.noneOfCaptureDevice) }
            
            _input = try AVCaptureDeviceInput(device: device)
            _session =  AVCaptureSession()
            if  _session.canAddInput (_input) {
                _session.addInput    (_input)
            } else { throw CameraError.initializing(.sessionCannotAddInput) }
        }
        // Configure the display out put.
        _displayOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA]
        _displayOutput.setSampleBufferDelegate(self, queue: _displayQueue)
        _displayOutput.alwaysDiscardsLateVideoFrames = true
        // Initialize and configure the session of the capture.
        if  _session == nil {
            // Initialize the device input for the session.
            try create_add_input()
        } else {
            // Find the available device inputs.
            let deviceInputs = _session.inputs.flatMap({ ($0 is AVCaptureDeviceInput && ($0 as! AVCaptureDeviceInput).device.hasMediaType(AVMediaTypeVideo)) ? $0 : nil }) as! [AVCaptureDeviceInput]
            if  deviceInputs.isEmpty {
                try create_add_input()
            } else if deviceInputs.startIndex == deviceInputs.index(before: deviceInputs.endIndex) {
                // Has only one video device inputs.
                _input = deviceInputs.first
            }
        }
        _initPreviewView() // Call the initialzer of preview view obviously.
        // Configure session.
        if #available(iOS 10.0, *) {
            if  _session.canAddOutput(capturePhotoOutput) {
                _session.addOutput   (capturePhotoOutput)
            } else { throw CameraError.initializing(.sessionCannotAddOutput) }
        }
        if  _session.canAddOutput(_displayOutput) {
            _session.addOutput   (_displayOutput)
        } else { throw CameraError.initializing(.sessionCannotAddOutput) }
    }
    /// Initialize the preview view if the session is not nil and inputs of the session is not empty.
    private func _initPreviewView() {
        guard _previewView?.previewLayer.session !== _session && _session != nil && !_session.inputs.filter({ ($0 is AVCaptureDeviceInput && ($0 as! AVCaptureDeviceInput).device.hasMediaType(AVMediaTypeVideo)) }).isEmpty else { return }
        
        _previewView = PreviewView(session: _session)
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

// MARK: - Public.

extension CameraViewController {
    public class var `default`: CameraViewController! { return try! CameraViewController(session: nil, starting: .at(.loaded)) }
}

// MARK: Actions.

extension CameraViewController {
    @objc
    fileprivate func _handleShot(_ sender: UIButton) {
        
    }
    
    @objc fileprivate func _handleToggleFace(_ sender: UIButton) {
        _sessionQueue.async { [unowned self] in
            let _ = try? self._previewView.toggle()
        }
        // Add transition animation.
        let transition = CATransition()
        // cube, suckEffect, oglFlip, rippleEffect, pageCurl, pageUnCurl, cameraIrisHollowOpen, cameraIrisHollowClose
        transition.type = "oglFlip"
        transition.subtype = kCATransitionFromLeft
        transition.duration = 0.25 * 2.0
        self.previewView.layer.add(transition, forKey: "transition")
    }
    
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

// MARK: - Session

extension CameraViewController {
    /// A type representing the starting time of the session.
    public enum SessionStarting {
        /// A type representing the life cycle of view of the view controller.
        public enum ViewLifeCycle {
            /// Indicates the view is during loading at calling `loadView()`.
            case loading
            /// Indicates the view is loaded at calling of `viewDidLoad()`.
            case loaded
            /// Indicates the view is about to show at calling of `viewWillAppear(_:)`
            case willAppear
            /// Indicates the view is showed at calling of `viewDidAppear(_:)`.
            case didAppear
        }
        /// Indicates the session is never starting or stopping.
        case never
        /// Indicates the session will start at initializing and stop at disposed.
        case immediately
        /// Indicates the session will start at the point of the  life cycle of the view and stop at disposed.
        case at(ViewLifeCycle)
    }
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

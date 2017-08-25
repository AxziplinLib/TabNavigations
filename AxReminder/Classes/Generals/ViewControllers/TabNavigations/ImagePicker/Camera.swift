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
    open var stopSessionWhenDisposed: Bool = false
    
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
            _previewView = CaptureVideoPreviewView(session: _session)
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

// MARK: Camera configs.

extension CameraViewController {
    public var position: AVCaptureDevicePosition { return _previewView.videoDevice?.position ?? .unspecified }
    
    @discardableResult
    public func toggle() -> Bool {
        switch position {
        case .back:
            return toggle(to: .front)
        default:
            return toggle(to: .back)
        }
    }
    @discardableResult
    public func toggle(to pos: AVCaptureDevicePosition) -> Bool {
        guard pos != position && pos != .unspecified else { return false }
        guard let session = _previewView.previewLayer.session else { return false }
        
        // Get new device.
        var devices: [AVCaptureDevice] = []
        if #available(iOS 10.0, *) {
            var deviceTypes: [AVCaptureDeviceType] = [.builtInWideAngleCamera, .builtInTelephotoCamera]
            if #available(iOS 10.2, *) {
                deviceTypes.append(.builtInDualCamera)
            } else {
                deviceTypes.append(.builtInDuoCamera)
            }
            if let _devices = AVCaptureDeviceDiscoverySession(deviceTypes: deviceTypes, mediaType: AVMediaTypeVideo, position: pos).devices { devices = _devices }
        } else {
            if let _devices = AVCaptureDevice.devices() as? [AVCaptureDevice] { devices = _devices }
        }
        guard !devices.isEmpty else { return false }
        
        let targetDevices = devices.flatMap({ $0.position == pos && $0.hasMediaType(AVMediaTypeVideo) ? $0 : nil })
        guard targetDevices.count == 1 else { return false }// Only one device for the specified position.
        
        let newDevice = targetDevices[0]
        guard let newDeviceInput = try? AVCaptureDeviceInput(device: newDevice) else {  return false }
        
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        // Remove all the device inputs if any.
        session.inputs.flatMap({ ($0 is AVCaptureDeviceInput && ($0 as! AVCaptureDeviceInput).device.hasMediaType(AVMediaTypeVideo)) ? $0 : nil }).forEach({ session.removeInput($0 as! AVCaptureInput) })
        // Add the new device input.
        if session.canAddInput(newDeviceInput) { session.addInput(newDeviceInput) }
        
        let _transition = CATransition()
        // cube, suckEffect, oglFlip, rippleEffect, pageCurl, pageUnCurl, cameraIrisHollowOpen, cameraIrisHollowClose
        _transition.type = "oglFlip"
        _transition.subtype = kCATransitionFromLeft
        _transition.duration = 0.25 * 2.0
        _previewView.previewLayer.add(_transition, forKey: "transition")
        
        return true
    }
}

// MARK: Actions.

extension CameraViewController {
    @objc
    fileprivate func _handleShot(_ sender: UIButton) {
        
    }
    
    @objc fileprivate func _handleToggleFace(_ sender: UIButton) { toggle() }
    
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
    @available(iOS 9.0, *)
    public final class CaptureVideoPreviewView: UIView {// CAReplicatorLayer
        override public class var layerClass: AnyClass { return AVCaptureVideoPreviewLayer.self }
        public var previewLayer: AVCaptureVideoPreviewLayer { return layer as! AVCaptureVideoPreviewLayer }
        public var videoDevice: AVCaptureDevice? {
            return (previewLayer.session.inputs as! [AVCaptureDeviceInput]).filter{ $0.device.hasMediaType(AVMediaTypeVideo) }.first?.device
        }
        public var infoContentInsets: UIEdgeInsets = .zero {
            didSet { _setupInfoStackView() }
        }
        // Only support String or UIImage object.
        public var humanReadingInfos: [HumanReadingInfo] = [] {
            willSet { _updateHumanReadingInfos(newValue) }
        }
        public let configurationQueue: DispatchQueue = DispatchQueue(label: "com.device_configuration.video_preview.camera_vc")
        
        fileprivate lazy var _infoStackView: UIStackView = { () -> UIStackView in
            let stackView = UIStackView()
            stackView.isUserInteractionEnabled = false
            stackView.translatesAutoresizingMaskIntoConstraints = false
            stackView.alignment = .center
            stackView.axis = .vertical
            stackView.distribution = .equalSpacing
            stackView.spacing = 10.0
            return stackView
        }()
        
        fileprivate weak var _focusTapGesture: UITapGestureRecognizer!
        fileprivate weak var _focusLongPressGesture: UILongPressGestureRecognizer!
        fileprivate weak var _exposurePanGesture: UIPanGestureRecognizer!
        
        fileprivate let _focusIndicator   : UIImageView = UIImageView(image: UIImage(named: _Resource.bundle+"auto_focus"))
        fileprivate let _exposureIndicator: UIImageView = UIImageView(image: UIImage(named: _Resource.bundle+"sun_shape_light"))
        fileprivate let _co_focusIndicator: UIImageView = UIImageView(image: UIImage(named: _Resource.bundle+"co_auto_focus"))
        
        fileprivate let _exposureSliders : (top: UIImageView, bottom: UIImageView)           = (UIImageView(), UIImageView())
        fileprivate var _exposureCenters : (isoBinding: CGPoint, translation: CGPoint)       = (.zero, .zero)
        fileprivate var _exposureSettings: (duration: CMTime, iso: Float, targetBias: Float) = (AVCaptureExposureDurationCurrent, 0.0, 0.0)
        fileprivate let _exposureSizes   : (top: CGSize, middle: CGSize, bottom: CGSize)     = (CGSize(width: 28.0, height: 28.0), CGSize(width: 25.0, height: 25.0), CGSize(width: 16.0, height: 16.0))
        
        fileprivate var _focusBeginning     : Date = Date()
        fileprivate var _co_focusBeginning  : Date = Date()
        fileprivate let _grace_du           : Double = 0.35
        fileprivate let _paddingOfFoexposure    : CGFloat = 5.0
        fileprivate let _lengthOfSliderSpace: CGFloat = 150.0
        
        // Device observing keypaths.
        private var _deviceObservingKeyPaths: [String] = []
        
        public init(session: AVCaptureSession) {
            super.init(frame: .zero)
            previewLayer.session = session
            _initializer()
        }
        
        required public init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
            
            _exposureIndicator.removeObserver(self, forKeyPath: "center")
            _deviceObservingKeyPaths.forEach{ videoDevice?.removeObserver(self, forKeyPath: $0, context: nil) }
        }
        
        // MARK: Override.
        
        override public func willMove(toSuperview newSuperview: UIView?) {
            super.willMove(toSuperview: newSuperview)
            
            if let _ = newSuperview {
                _focusIndicator.isHidden = true
                _exposureIndicator.isHidden = true
                _co_focusIndicator.isHidden = true
            }
        }
        
        // MARK: Private.
        private func _initializer() {
            _setupIndicators()
            _setupInfoStackView()
            
            _setupFoexposureGestures()
            
            _deviceObservingKeyPaths = ["adjustingFocus", "focusMode", "flashActive", "exposureDuration", "ISO", "exposureTargetBias",  "exposureTargetOffset"]
            _observeProperties()
            _observeNotifications()
        }
        
        private func _setupInfoStackView() {
            if _infoStackView.superview === self {
                _infoStackView.removeFromSuperview()
            }
            
            addSubview(_infoStackView)
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-left-[_infoStackView]-right-|", options: [], metrics: ["left": infoContentInsets.left, "right": infoContentInsets.right], views: ["_infoStackView": _infoStackView]))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-top-[_infoStackView]-(>=bottom)-|", options: [], metrics: ["top" : infoContentInsets.top + _infoStackView.spacing, "bottom" : infoContentInsets.bottom], views: ["_infoStackView": _infoStackView]))
        }
        
        private func _setupIndicators() {
            addSubview(_focusIndicator)
            addSubview(_exposureIndicator)
            addSubview(_co_focusIndicator)
            addSubview(_exposureSliders.top)
            addSubview(_exposureSliders.bottom)
            
            _focusIndicator.isHidden = true
            _exposureIndicator.isHidden = true
            _co_focusIndicator.isHidden = true
            _exposureSliders.top.backgroundColor = _Resource.Config.Camera.Color.highlighted
            _exposureSliders.bottom.backgroundColor = _Resource.Config.Camera.Color.highlighted
            _exposureSliders.top.isHidden = true
            _exposureSliders.bottom.isHidden = true
            _exposureSliders.top.alpha = 0.0
            _exposureSliders.bottom.alpha = 0.0
        }
        
        private func _setupFoexposureGestures() {
            let tap = UITapGestureRecognizer(target: self, action: #selector(_handleTapToConfigureDevice(_:)))
            addGestureRecognizer(tap)
            _focusTapGesture = tap
            
            let longPress = UILongPressGestureRecognizer(target: self, action: #selector(_handleLongPressToConfigureDevice(_:)))
            addGestureRecognizer(longPress)
            _focusLongPressGesture = longPress
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(_handlePanToConfigureDevice(_:)))
            addGestureRecognizer(pan)
            _exposurePanGesture = pan
        }
        
        private func _observeProperties() {
            _exposureIndicator.addObserver(self, forKeyPath: "center", options: .new, context: nil)
            _deviceObservingKeyPaths.forEach{ videoDevice?.addObserver(self, forKeyPath: $0, options: .new, context: nil) }
        }
        private func _observeNotifications() {
            NotificationCenter.default.addObserver(self, selector: #selector(_handleCaptureDeviceSubjectAreaDidChange(_:)), name: .AVCaptureDeviceSubjectAreaDidChange, object: nil)
        }
        
        private func _updateHumanReadingInfos(_ newInfos: [HumanReadingInfo] = []) {
            @discardableResult
            func _infoView(`for` info: HumanReadingInfo, updatedInfoView: _HumanReadingInfoView? = nil) -> _HumanReadingInfoView? {
                let infoView = updatedInfoView ?? _HumanReadingInfoView(type: info.type)
                if updatedInfoView == nil {
                    infoView.translatesAutoresizingMaskIntoConstraints = false
                    infoView.layer.cornerRadius = 2.0
                    infoView.layer.masksToBounds = true
                    infoView.clipsToBounds = true
                }
                let imageViewTag = 0x2
                let labelViewTag = 0x3
                
                switch info {
                case let (_, image) as (HumanReading, UIImage):
                    let imageView = infoView.viewWithTag(imageViewTag) as? _ImageView ?? _ImageView(image: image)
                    imageView.tag = imageViewTag
                    imageView.contentMode = .scaleAspectFit
                    imageView.translatesAutoresizingMaskIntoConstraints = false
                    imageView.removeFromSuperview()
                    infoView.backgroundColor = .clear
                    infoView.addSubview(imageView)
                    imageView.centerXAnchor.constraint(equalTo: infoView.centerXAnchor).isActive = true
                    imageView.centerYAnchor.constraint(equalTo: infoView.centerYAnchor).isActive = true
                    imageView.topAnchor.constraint(equalTo: infoView.topAnchor).isActive = true
                    imageView.bottomAnchor.constraint(equalTo: infoView.bottomAnchor).isActive = true
                    imageView.leadingAnchor.constraint(equalTo: infoView.leadingAnchor).isActive = true
                    imageView.trailingAnchor.constraint(equalTo: infoView.trailingAnchor).isActive = true
                case let (_, content) as (HumanReading, String):
                    let label = infoView.viewWithTag(labelViewTag) as? UILabel ?? UILabel()
                    label.tag = labelViewTag
                    label.translatesAutoresizingMaskIntoConstraints = false
                    label.font = UIFont.systemFont(ofSize: 14)
                    label.textColor = UIColor.black.withAlphaComponent(0.88)
                    label.text = content
                    label.removeFromSuperview()
                    infoView.backgroundColor = _Resource.Config.Camera.Color.highlighted
                    infoView.addSubview(label)
                    label.topAnchor.constraint(equalTo: infoView.topAnchor, constant: 2.0).isActive = true
                    label.bottomAnchor.constraint(equalTo: infoView.bottomAnchor, constant: -2.0).isActive = true
                    label.leadingAnchor.constraint(equalTo: infoView.leadingAnchor, constant: 8.0).isActive = true
                    label.trailingAnchor.constraint(equalTo: infoView.trailingAnchor, constant: -8.0).isActive = true
                default: return nil
                }
                
                return infoView
            }
            
            let duration = 0.5
            let arrangedViews = _infoStackView.arrangedSubviews as! [_HumanReadingInfoView]
            let newInfoTypes = newInfos.map{ $0.type }
            let oldInfoTypes = humanReadingInfos.map{ $0.type }
            let padding = _infoStackView.spacing
            let stackOffset = infoContentInsets.top + padding
            let originalFrameInfos   : [(type: HumanReading, frame: CGRect)] = arrangedViews.map{ ($0.type, $0.frame) }
            var infoViewsToBeRemoved : [_HumanReadingInfoView] = []
            var infoViewsToBeRemained: [_HumanReadingInfoView] = []
            let infoViewsToBeAdded   : [_HumanReadingInfoView] = newInfos.flatMap({ oldInfoTypes.contains($0.type) ? nil: $0 }).flatMap({ _infoView(for: $0) })
            arrangedViews.forEach { [unowned self] infoView in
                if newInfoTypes.contains(infoView.type) {
                    infoViewsToBeRemained.append(infoView)
                } else {
                    infoViewsToBeRemoved.append(infoView)
                    let frame = CGRect(origin: CGPoint(x: infoView.frame.origin.x, y: infoView.frame.origin.y + stackOffset), size: infoView.bounds.size)
                    self._infoStackView.removeArrangedSubview(infoView)
                    infoView.removeFromSuperview()
                    self.insertSubview(infoView, belowSubview: self._infoStackView)
                    infoView.topAnchor.constraint(equalTo: self.topAnchor, constant: frame.origin.y).isActive = true
                    infoView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
                }
            }
            
            let reversedNewInfoTypes = Array(newInfoTypes.reversed())
            infoViewsToBeAdded.reversed().forEach { [unowned self] (infoView) in
                infoView.alpha = 0.0
                let index = reversedNewInfoTypes.index(where: { $0 == infoView.type })!
                self._infoStackView.insertArrangedSubview(infoView, at: index)
                self._infoStackView.sendSubview(toBack: infoView)
            }
            _infoStackView.layoutIfNeeded()
            infoViewsToBeAdded.forEach({ $0.transform = CGAffineTransform(translationX: 0.0, y: -$0.frame.height - padding) })
            infoViewsToBeRemained.forEach { (infoView) in
                let info = newInfos.filter{ $0.type == infoView.type }.first!
                _infoView(for: info, updatedInfoView: infoView)
                let originalFrame = originalFrameInfos.filter({ $0.type == infoView.type }).first!.frame
                infoView.transform = CGAffineTransform(translationX: 0.0, y: originalFrame.minY - infoView.frame.minY)
            }
            
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 1.0, initialSpringVelocity: 1.0, options: [.curveEaseOut], animations: {
                infoViewsToBeRemoved.forEach({ (infoView) in
                    infoView.alpha = 0.0
                    infoView.transform = CGAffineTransform(translationX: 0.0, y: -infoView.frame.height-padding)
                })
                infoViewsToBeAdded.forEach({ (infoView) in
                    infoView.alpha = 1.0
                    infoView.transform = .identity
                })
                infoViewsToBeRemained.forEach{ $0.transform = .identity }
            }) { (_) in
                infoViewsToBeRemoved.forEach{ $0.removeFromSuperview() }
            }
        }
    }
}

public protocol HumanReadable {}
extension HumanReadable {
    public var contents: String? { return nil }
    public var image: UIImage? { return nil }
}

extension String: HumanReadable {
    public var contents: String { return self }
}
extension UIImage: HumanReadable {
    public var image: UIImage { return self }
}

public extension CameraViewController.CaptureVideoPreviewView {
    enum HumanReading {
        case autoModesLocked
        case flashOn
        case hdrOn
        case exposureTargetOffset
        case customExposure
    }
    
    public typealias HumanReadingInfo = (type: HumanReading, content: HumanReadable)
}

// MARK: Actions.

extension CameraViewController.CaptureVideoPreviewView {
    @objc
    fileprivate func _handleCaptureDeviceSubjectAreaDidChange(_ notification: NSNotification) {
        if videoDevice?.focusMode != .continuousAutoFocus {
            _focus(using: .continuousAutoFocus, exposure: .continuousAutoExposure, at: CGPoint(x: 0.5, y: 0.5))
        }
    }
    
    @objc
    fileprivate func _handleTapToConfigureDevice(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        
        let location = sender.location(in: self)
        let point = previewLayer.captureDevicePointOfInterest(for: location)
        
        humanReadingInfos = humanReadingInfos.filter{ $0.type != .autoModesLocked }
        
        _focus(using: .autoFocus, exposure: .autoExpose, at: point)
        _animateIndicators(show: true, mode: .autoFocus, at: location)
    }
    
    @objc
    fileprivate func _handleLongPressToConfigureDevice(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .possible: fallthrough
        case .began:
            let location = sender.location(in: self)
            let pointOfInterest = previewLayer.captureDevicePointOfInterest(for: location)
            // _lockFocusAndExpose(at: previewLayer.captureDevicePointOfInterest(for: location))
            _focus(using: .autoFocus, exposure: .autoExpose, at: pointOfInterest, monitorSubjectAreaChange: false)
            _animateScalingContinuousFocusIndicator(at: location)
            if !humanReadingInfos.contains{ $0.type == .autoModesLocked } {
                humanReadingInfos = [[(HumanReading.autoModesLocked, "自动曝光/自动对焦锁定")], humanReadingInfos.filter({ $0.type != .autoModesLocked })].joined().reversed()
            }
        case .changed: break
        // print("Long press gesture is changing.")
        case .failed: fallthrough
        case .cancelled: fallthrough
        default:
            guard let device = videoDevice else { break }
            
            _animateFoexposureIndicators(true, at: _co_focusIndicator.center, scale: _co_focusIndicator.bounds.width / _focusIndicator.bounds.width) { [unowned self] in
                if device.focusMode == .locked {
                    self._pinFoexposureIndicators()
                }
            }
        }
    }
    
    @objc
    fileprivate func _handlePanToConfigureDevice(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .possible: fallthrough
        case .began:
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_pinFoexposureIndicators), object: nil)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(_animateHideExposureSlidersIfNeeded), object: nil)
            
            _exposureCenters.translation = _exposureIndicator.center
            
            _resetPinnedFoexposureIndicatorsByAnimatedIfVisible()
            _animateShowExposureSlidersIfNeeded()
        case .changed:
            _ensureVisibleOfFoexposureIndicator()
            _ensureVisibleOfExposureSliders()
            
            let center = CGPoint(x: _exposureCenters.translation.x, y: _exposureCenters.translation.y + sender.translation(in: self).y * 0.1)
            if  center.y >= _focusIndicator.center.y - _lengthOfSliderSpace * 0.5 && center.y <= _focusIndicator.center.y + _lengthOfSliderSpace * 0.5 {
                _exposureIndicator.center = center
            }
        case .failed: fallthrough
        case .cancelled: fallthrough
        default:
            self.perform(#selector(_pinFoexposureIndicators), with: nil, afterDelay: 0.5, inModes: [RunLoopMode.commonModes])
            self.perform(#selector(_animateHideExposureSlidersIfNeeded), with: nil, afterDelay: 1.0, inModes: [RunLoopMode.commonModes])
            
            _exposureCenters.translation = _exposureIndicator.center
        }
    }
    
    override public func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "adjustingFocus" {
            guard (object as? AVCaptureDevice) === videoDevice else { return }
            if let adjustingFocus = change?[.newKey] as? Bool, let device = videoDevice {
                // print("is adjusting focus: " + adjustingFocus.description)
                let location = previewLayer.pointForCaptureDevicePoint(ofInterest: device.focusPointOfInterest)
                if device.focusMode == .autoFocus {
                    if _focusLongPressGesture.state == .changed {
                        _animateScalingContinuousFocusIndicator(at: location)
                    }
                } else {
                    _animateIndicators(show: adjustingFocus, mode: device.focusMode, at: location)
                }
            }
        } else if keyPath == "focusMode" {
            guard (object as? AVCaptureDevice) === videoDevice else { return }
            if let focusMode = change?[.newKey] as? Int, let device = videoDevice {
                // print("new focus mode: " + focusMode.description)
                if AVCaptureFocusMode(rawValue: focusMode) == .locked && !device.isAdjustingFocus && _focusLongPressGesture.state != .changed {
                    _animateIndicators(show: true, mode: .locked, at: .zero)
                }
            }
        } else if keyPath == "flashActive" {
            guard (object as? AVCaptureDevice) === videoDevice else { return }
            if let isFlashActive = change?[.newKey] as? Bool {
                // print("new flash mode: " + isFlashActive.description)
                if isFlashActive {
                    if !humanReadingInfos.contains{ $0.type == .flashOn } {
                        humanReadingInfos = [humanReadingInfos.filter({ $0.type != .flashOn }), [(HumanReading.flashOn, UIImage(named: _Resource.bundle+"flash_info")!)]].joined().reversed()
                    }
                } else {
                    humanReadingInfos = humanReadingInfos.filter{ $0.type != .flashOn }
                }
            }
        } else if keyPath == "exposureDuration" || keyPath == "ISO" || keyPath == "exposureTargetBias" {
            guard (object as? AVCaptureDevice) === videoDevice else { return }
            guard let device = videoDevice else { return }
            if device.exposureMode != .custom {
                // print("Begin updating exposure settings and centers.")
                humanReadingInfos = humanReadingInfos.filter{ $0.type != .exposureTargetOffset && $0.type != .customExposure }
                _exposureCenters.isoBinding = _exposureIndicator.center
                _exposureSettings.duration = device.exposureDuration
                _exposureSettings.iso = max(min(device.iso, device.activeFormat.maxISO), device.activeFormat.minISO)
                _exposureSettings.targetBias = max(min(device.exposureTargetBias, device.maxExposureTargetBias), device.minExposureTargetBias)
            }
        } else if keyPath == "exposureTargetOffset" {
            guard (object as? AVCaptureDevice) === videoDevice else { return }
            guard let exposureTargetOffset = change?[.newKey] as? Float, let device = videoDevice else { return }
            if device.exposureMode == .custom {
                humanReadingInfos = [humanReadingInfos.filter({ $0.type != .exposureTargetOffset }), [(HumanReading.exposureTargetOffset, "Exposure target offset: \(exposureTargetOffset)")]].joined().reversed()
            }
        } else if keyPath == "center" {
            guard (object as? AVCaptureDevice) === videoDevice else { return }
            _updateSizeOfExposureIndicator()
            _updatePositionsOfExposureSliders()
            if #available(iOS 8.0, *) {
                _exposeUsingCustoms()
            }
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    private func _focus(using focusMode: AVCaptureFocusMode, exposure: AVCaptureExposureMode, at point: CGPoint, monitorSubjectAreaChange: Bool = true) {
        guard let device = videoDevice else { return }
        
        configurationQueue.async {
            do {
                try device.lockForConfiguration()
                
                // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                // Call set(Focus/Exposure)Mode() to apply the new point of interest.
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode) {
                    device.focusPointOfInterest = point
                    device.focusMode = focusMode
                }
                
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposure) {
                    device.exposurePointOfInterest = point
                    device.exposureMode = exposure
                }
                
                /* if device.isAutoFocusRangeRestrictionSupported {
                 device.autoFocusRangeRestriction = .far
                 } */
                
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                
                device.unlockForConfiguration()
            } catch let error {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    @available(iOS 8.0, *)
    private func _exposeUsingCustoms() {
        guard let device = videoDevice else { return }
        guard _exposurePanGesture.state == .changed else { return }
        
        configurationQueue.async { [weak self] in
            guard let wself = self else { return }
            do {
                try device.lockForConfiguration()
                
                if device.isExposureModeSupported(.custom) {
                    device.exposureMode = .custom
                    
                    let preferedTimescale = max(device.activeFormat.minExposureDuration.timescale, device.activeFormat.maxExposureDuration.timescale)
                    if wself._exposureIndicator.center.y < wself._focusIndicator.center.y /*wself._exposurePanGesture.translation(in: wself).y <= 0*/ {
                        let beginsPositon = wself._focusIndicator.center.y - wself._lengthOfSliderSpace * 0.5
                        let flag = max(0.0, (wself._exposureCenters.isoBinding.y - wself._exposureIndicator.center.y)) / (wself._exposureCenters.isoBinding.y - beginsPositon)
                        // print("Custom exposure \(wself._exposureSettings.iso + (device.activeFormat.maxISO - wself._exposureSettings.iso) * Float(flag)), max: \(device.activeFormat.maxISO)")
                        // let maxExposureSec = Double(device.activeFormat.maxExposureDuration.value) / Double(device.activeFormat.maxExposureDuration.timescale)
                        let relativeExposureSec = Double(wself._exposureSettings.duration.value) / Double(wself._exposureSettings.duration.timescale)
                        // let seconds = min(maxExposureSec, relativeExposureSec + (maxExposureSec - relativeExposureSec) * Double(flag))
                        // let duration = CMTime(seconds: seconds, preferredTimescale: preferedTimescale)
                        // print("Duration: \(duration), max: \(device.activeFormat.maxExposureDuration)")
                        let iso = min(device.activeFormat.maxISO, wself._exposureSettings.iso + (device.activeFormat.maxISO - wself._exposureSettings.iso) * pow(Float(flag), 2.0))
                        let targetBias = max(device.minExposureTargetBias, wself._exposureSettings.targetBias - (wself._exposureSettings.targetBias - device.minExposureTargetBias) * pow(Float(flag), 2.0))
                        DispatchQueue.main.async {
                            wself.humanReadingInfos = [wself.humanReadingInfos.filter({ $0.type != .customExposure }), [(HumanReading.customExposure, "Duration: \(String(format: "%.9f", relativeExposureSec)), iso: \(iso), targetBias: \(targetBias)")]].joined().reversed()
                        }
                        
                        device.setExposureModeCustomWithDuration(wself._exposureSettings.duration, iso: iso, completionHandler: nil)
                        device.setExposureTargetBias(targetBias, completionHandler: nil)
                    } else {
                        let endsPosition = wself._focusIndicator.center.y + wself._lengthOfSliderSpace * 0.5
                        let flag = max(0.0, (wself._exposureIndicator.center.y - wself._exposureCenters.isoBinding.y)) / (endsPosition - wself._exposureCenters.isoBinding.y)
                        // print("Custom exposure \(wself._exposureSettings.iso - (wself._exposureSettings.iso - device.activeFormat.minISO) * Float(flag))， min: \(device.activeFormat.minISO)")
                        let minExposureSec = Double(device.activeFormat.minExposureDuration.value) / Double(device.activeFormat.minExposureDuration.timescale)
                        let relativeExposureSec = Double(wself._exposureSettings.duration.value) / Double(wself._exposureSettings.duration.timescale)
                        let seconds = max(minExposureSec, relativeExposureSec - (relativeExposureSec - minExposureSec) * Double(flag))
                        let duration = CMTime(seconds: seconds, preferredTimescale: preferedTimescale)
                        // print("Duration: \(duration), min: \(device.activeFormat.minExposureDuration)")
                        let iso = max(device.activeFormat.minISO, wself._exposureSettings.iso - (wself._exposureSettings.iso - device.activeFormat.minISO) * Float(flag))
                        let targetBias = min(device.maxExposureTargetBias, wself._exposureSettings.targetBias + (device.maxExposureTargetBias - wself._exposureSettings.targetBias) * Float(flag))
                        DispatchQueue.main.async {
                            wself.humanReadingInfos = [wself.humanReadingInfos.filter({ $0.type != .customExposure }), [(HumanReading.customExposure, "Duration: \(String(format: "%.9f", seconds)), iso: \(iso), targetBias: \(targetBias)")]].joined().reversed()
                        }
                        
                        device.setExposureModeCustomWithDuration(duration, iso: iso, completionHandler: nil)
                        device.setExposureTargetBias(targetBias, completionHandler: nil)
                    }
                    
                    device.isSubjectAreaChangeMonitoringEnabled = false
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
    
    private func _animateIndicators(show: Bool = true, mode: AVCaptureFocusMode, at point: CGPoint) {
        switch mode {
        case .continuousAutoFocus:
            _animateContinuousFocusIndicator(show, at: point)
        case .autoFocus:
            _animateFoexposureIndicators(show, at: point)
        default:
            _pinFoexposureIndicators()
        }
    }
    
    private func _animateScalingContinuousFocusIndicator(at point: CGPoint) {
        // Hide Foexposure indicators first.
        _focusIndicator.isHidden = true
        _exposureIndicator.isHidden = true
        _exposureSliders.top.isHidden = true
        _exposureSliders.bottom.isHidden = true
        // Un twinkle the content of _co_focus indicator.
        _untwinkle(content: _co_focusIndicator)
        // Animate show the cotinuous focus indicator.
        _animateContinuousFocusIndicator(true, at: point, checkingIsHidden: false)
    }
    
    private func _animateContinuousFocusIndicator(_ show: Bool, at point: CGPoint, checkingIsHidden: Bool = true, twinkle twinkleContent: Bool = true) {
        if show {
            if checkingIsHidden {
                guard _co_focusIndicator.isHidden else { return }
            }
            
            _co_focusBeginning = Date()
            _focusIndicator.isHidden = true
            _exposureIndicator.isHidden = true
            _exposureSliders.top.isHidden = true
            _exposureSliders.bottom.isHidden = true
            _co_focusIndicator.isHidden = false
            _co_focusIndicator.center = point
            _co_focusIndicator.alpha = 0.0
            
            let scale: CGFloat = 1.5
            _co_focusIndicator.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(__animateHideContinuousFocusIndicator), object: nil)
            UIView.animate(withDuration: 0.1, animations: { [unowned self] in
                self._co_focusIndicator.alpha = 1.0
            }) { [unowned self] _ in
                UIView.animate(withDuration: 0.2, animations: { [unowned self] in
                    self._co_focusIndicator.transform = .identity
                }) { [unowned self] _ in
                    if twinkleContent {
                        self._twinkle(content: self._co_focusIndicator)
                    }
                }
            }
        } else {
            let delay = max(0.0, _grace_du - Date().timeIntervalSince(_co_focusBeginning))
            // print("delay: \(delay), grace: \(_grace_du) offset: \(Date().timeIntervalSince(_co_focusBeginning))")
            self.perform(#selector(__animateHideContinuousFocusIndicator), with: nil, afterDelay: delay, inModes: [RunLoopMode.commonModes])
        }
    }
    
    @objc
    private func __animateHideContinuousFocusIndicator() {
        guard !_co_focusIndicator.isHidden else { return }
        
        self._untwinkle(content: self._co_focusIndicator)
        UIView.animate(withDuration: 0.25, delay: 0.5, options: [], animations: { [unowned self] in
            self._co_focusIndicator.alpha = 0.0
        }) { [unowned self] _ in
            self._co_focusIndicator.isHidden = true
        }
    }
    
    private func _animateFoexposureIndicators(_ show: Bool, at point: CGPoint, scale: CGFloat = 1.5, showsCompletion: (() -> Void)? = nil) {
        if show {
            _focusBeginning = Date()
            _co_focusIndicator.isHidden = true
            _focusIndicator.isHidden = false
            _exposureIndicator.isHidden = false
            _focusIndicator.alpha = 0.0
            _exposureIndicator.alpha = 0.0
            _focusIndicator.center = point
            
            _focusIndicator.transform = CGAffineTransform(scaleX: scale, y: scale)
            _exposureIndicator.frame = CGRect(origin: .zero, size: _exposureSizes.middle)
            switch point.x {
            case 0...(bounds.width - _focusIndicator.bounds.width * 0.5 - (_paddingOfFoexposure + _exposureIndicator.bounds.width)):
                _exposureIndicator.center = CGPoint(x: point.x + _focusIndicator.bounds.width * 0.5 + _paddingOfFoexposure + _exposureIndicator.bounds.width * 0.5, y: point.y)
                _updatePositionsOfExposureSliders()
                _exposureIndicator.transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: _focusIndicator.bounds.width * 0.5 * (scale - 1.0), y: 0.0)
                _exposureSliders.top.transform = _exposureIndicator.transform
                _exposureSliders.bottom.transform = _exposureIndicator.transform
            default:
                _exposureIndicator.center = CGPoint(x: point.x - _focusIndicator.bounds.width * 0.5 - _paddingOfFoexposure - _exposureIndicator.bounds.width * 0.5, y: point.y)
                _updatePositionsOfExposureSliders()
                _exposureIndicator.transform = CGAffineTransform(scaleX: scale, y: scale).translatedBy(x: -_focusIndicator.bounds.width * 0.5 * (scale - 1.0), y: 0.0)
                _exposureSliders.top.transform = _exposureIndicator.transform
                _exposureSliders.bottom.transform = _exposureIndicator.transform
            }
            
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(__animateHideFoexposureIndicators), object: nil)
            UIView.animate(withDuration: 0.1, animations: { [unowned self] in
                self._focusIndicator.alpha = 1.0
                self._exposureIndicator.alpha = 1.0
            }) { [unowned self] (_) in
                UIView.animate(withDuration: 0.25, animations: { [unowned self] in
                    self._focusIndicator.transform = .identity
                    self._exposureIndicator.transform = .identity
                    self._exposureSliders.top.transform = .identity
                    self._exposureSliders.bottom.transform = .identity
                }) { [unowned self] (_) in
                    self._twinkle(content: self._focusIndicator)
                    showsCompletion?()
                }
            }
        } else {
            let delay = max(0.0, _grace_du - Date().timeIntervalSince(_focusBeginning))
            self.perform(#selector(__animateHideFoexposureIndicators), with: nil, afterDelay: delay, inModes: [RunLoopMode.commonModes])
        }
    }
    
    @objc
    private func __animateHideFoexposureIndicators() {
        _animateHideExposureSlidersIfNeeded()
        
        self._untwinkle(content: self._focusIndicator)
        self._untwinkle(content: self._exposureIndicator)
        UIView.animate(withDuration: 0.25, delay: 0.5, options: [], animations: { [unowned self] in
            self._focusIndicator.alpha = 0.0
            self._exposureIndicator.alpha = 0.0
        }) { [unowned self] _ in
            self._focusIndicator.isHidden = true
            self._exposureIndicator.isHidden = true
        }
    }
    
    @objc
    private func _pinFoexposureIndicators() {
        _untwinkle(content: _focusIndicator)
        _untwinkle(content: _exposureIndicator)
        
        UIView.animate(withDuration: 0.25, delay: 0.5, options: [], animations: { [unowned self] in
            self._focusIndicator.alpha = 0.5
            self._exposureIndicator.alpha = 0.5
            }, completion: nil)
    }
    
    private func _resetPinnedFoexposureIndicatorsByAnimatedIfVisible() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [], animations: { [unowned self] in
            self._focusIndicator.alpha = 1.0
            self._exposureIndicator.alpha = 1.0
            }, completion: nil)
    }
    
    private func _animateShowExposureSlidersIfNeeded() {
        _exposureSliders.top.isHidden = false
        _exposureSliders.bottom.isHidden = false
        
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [], animations: { [unowned self] in
            self._exposureSliders.top.alpha = 1.0
            self._exposureSliders.bottom.alpha = 1.0
        })
    }
    
    private func _ensureVisibleOfFoexposureIndicator() {
        if _exposureIndicator.alpha != 1.0 || _exposureIndicator.isHidden {
            _exposureIndicator.isHidden = false
            _exposureIndicator.alpha = 1.0
        }; if _focusIndicator.alpha != 1.0 || _focusIndicator.isHidden {
            _focusIndicator.isHidden = false
            _focusIndicator.alpha = 1.0
        }
    }
    private func _ensureVisibleOfExposureSliders() {
        if _exposureSliders.top.alpha != 1.0 || _exposureSliders.top.isHidden {
            _exposureSliders.top.isHidden = false
            _exposureSliders.top.alpha = 1.0
        }; if _exposureSliders.bottom.alpha != 1.0 || _exposureSliders.bottom.isHidden {
            _exposureSliders.bottom.isHidden = false
            _exposureSliders.bottom.alpha = 1.0
        }
    }
    
    @objc
    private func _animateHideExposureSlidersIfNeeded() {
        UIView.animate(withDuration: 0.25, delay: 0.0, options: [], animations: { [unowned self] in
            self._exposureSliders.top.alpha = 0.0
            self._exposureSliders.bottom.alpha = 0.0
        }) { [unowned self] (_) in
            self._exposureSliders.top.isHidden = true
            self._exposureSliders.bottom.isHidden = true
        }
    }
    
    private func _updatePositionsOfExposureSliders() {
        let topBeginsY = _focusIndicator.center.y - _lengthOfSliderSpace * 0.5
        let topEndsY = _exposureIndicator.frame.minY - 2.0
        let bottomBeginsY = _exposureIndicator.frame.maxY + 2.0
        let bottomEndsY = _focusIndicator.center.y + _lengthOfSliderSpace * 0.5
        
        _exposureSliders.top.frame = CGRect(origin: CGPoint(x: 0.0, y: topBeginsY), size: CGSize(width: 1.0, height: max(0.0, topEndsY - topBeginsY)))
        _exposureSliders.bottom.frame = CGRect(origin: CGPoint(x: 0.0, y: bottomBeginsY), size: CGSize(width: 1.0, height: max(0.0, bottomEndsY - bottomBeginsY)))
        var topCenter = _exposureSliders.top.center
        var bottomCenter = _exposureSliders.bottom.center
        topCenter.x = _exposureIndicator.center.x
        bottomCenter.x = _exposureIndicator.center.x
        _exposureSliders.top.center = topCenter
        _exposureSliders.bottom.center = bottomCenter
    }
    
    private func _updateSizeOfExposureIndicator() {
        let center = _exposureIndicator.center
        
        if center.y <= _focusIndicator.center.y {
            let width = min(_exposureSizes.top.width, _exposureSizes.middle.width + (_exposureSizes.top.width - _exposureSizes.middle.width) * (_focusIndicator.center.y - center.y) / (_lengthOfSliderSpace * 0.5))
            let height = min(_exposureSizes.top.height, _exposureSizes.middle.height + (_exposureSizes.top.height - _exposureSizes.middle.height) * (_focusIndicator.center.y - center.y) / (_lengthOfSliderSpace * 0.5))
            let originx = _exposureIndicator.frame.origin.x - (width - _exposureIndicator.bounds.width) * 0.5
            let originy = _exposureIndicator.frame.origin.y - (height - _exposureIndicator.bounds.height) * 0.5
            _exposureIndicator.frame = CGRect(x: originx, y: originy, width: width, height: height)
        } else {
            let width = max(_exposureSizes.bottom.width, _exposureSizes.middle.width - (_exposureSizes.middle.width - _exposureSizes.bottom.width) * (center.y - _focusIndicator.center.y) / (_lengthOfSliderSpace * 0.5))
            let height = max(_exposureSizes.bottom.height, _exposureSizes.middle.height - (_exposureSizes.middle.height - _exposureSizes.bottom.height) * (center.y - _focusIndicator.center.y) / (_lengthOfSliderSpace * 0.5))
            let originx = _exposureIndicator.frame.origin.x + (_exposureIndicator.bounds.width - width) * 0.5
            let originy = _exposureIndicator.frame.origin.y + (_exposureIndicator.bounds.height - height) * 0.5
            _exposureIndicator.frame = CGRect(x: originx, y: originy, width: width, height: height)
        }
    }
    
    private func _twinkle(content view: UIView) {
        _untwinkle(content: view)
        
        let twinkle = CABasicAnimation(keyPath: "opacity")
        twinkle.fromValue = 1.0
        twinkle.toValue = 0.5
        twinkle.duration = 0.2
        twinkle.isRemovedOnCompletion = false
        twinkle.fillMode = kCAFillModeForwards
        twinkle.autoreverses = true
        twinkle.repeatCount = Float.greatestFiniteMagnitude
        
        view.layer.add(twinkle, forKey: "twinkle")
    }
    private func _untwinkle(content view: UIView) { view.layer.removeAnimation(forKey: "twinkle") }
}

extension CameraViewController.CaptureVideoPreviewView {
    internal class _ImageView: UIImageView {
        override var intrinsicContentSize: CGSize { return image?.size ?? .zero }
        override var image: UIImage? {
            didSet { invalidateIntrinsicContentSize() }
        }
    }
}

extension CameraViewController.CaptureVideoPreviewView {
    internal class _HumanReadingInfoView: UIView {
        let type: HumanReading
        init(type: HumanReading) {
            self.type = type
            super.init(frame: .zero)
        }
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

// MARK: - TopBar.

extension CameraViewController {
    @available(iOS 9.0, *)
    public final class TopBar: UIView {
        public var countMeetsFullScreen: Int = 5
        
        fileprivate var didSelectItem  : ItemsSelection?
        fileprivate var willShowActions: ActionsPresentation?
        fileprivate var willHideActions: ActionsDismissal?
        fileprivate var didSelectAction: ActionsSelection?
        
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
    
    fileprivate typealias ItemsSelection      = (Int) -> Void // Selected item index.
    fileprivate typealias ActionsPresentation = (Int) -> Void // Selected item index.
    fileprivate typealias ActionsDismissal    = ActionsPresentation
    fileprivate typealias ActionsSelection    = (Int, Int) -> Void // Selected item index, selected action index.
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
    fileprivate func updateImage(_ image: UIImage?, ofItemAtIndex index: Array<CameraViewController.BarItem>.Index) {
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

// MARK: - CaptureVideoDisplayView.

extension CameraViewController {
    // @available(*, unavailable)
    public final class CaptureVideoDisplayView: GLKView {
        // fileprivate class var `default`: Self { return CaptureVideoDisplayView() }
        public var eaglContext: EAGLContext { return _eaglContext }
        fileprivate let _eaglContext = EAGLContext(api: .openGLES3)!
        
        public var ciContext: CIContext! { return _ciContext }
        fileprivate var _ciContext: CIContext!
        
        public var blured: Bool { return _blured }
        internal var isDrawingEnabled: Bool = true
        private var _blured: Bool = false
        private let _blur: UIImageView = UIImageView()
        private var _extent  : CGRect = .zero
        private var _drawRect: CGRect = .zero
        private var _drawRectNeedsUpdate: Bool = false
        private let _queue = DispatchQueue(label: "com.capture.display.render")
        
        convenience public init() {
            self.init(frame: .zero)
        }
        override public init(frame: CGRect) {
            super.init(frame: frame, context: _eaglContext)
            _initializer()
        }
        required public init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        override public func layoutSubviews() {
            super.layoutSubviews()
            _drawRectNeedsUpdate = true
        }
        private func _initializer() {
            _ciContext = CIContext(eaglContext: _eaglContext, options: [kCIContextWorkingColorSpace: NSNull()])
            enableSetNeedsDisplay = false
            // because the native video image from the back camera is in UIDeviceOrientationLandscapeLeft (i.e. the home button is on the right),
            // we need to apply a clockwise 90 degree transform so that we can draw the video preview as if we were in a landscape-oriented view;
            // if you're using the front camera and you want to have a mirrored preview (so that the user is seeing themselves in the mirror),
            // you need to apply an additional horizontal flip (by concatenating CGAffineTransformMakeScale(-1.0, 1.0) to the rotation transform)
            transform = CGAffineTransform(rotationAngle: CGFloat.pi * 0.5)
            // bind the frame buffer to get the frame buffer width and height;
            // the bounds used by CIContext when drawing to a GLKView are in pixels (not points),
            // hence the need to read from the frame buffer's width and height;
            // in addition, since we will be accessing the bounds in another queue (_captureSessionQueue),
            // we want to obtain this piece of information so that we won't be
            // accessing _videoPreviewView's properties from another thread/queue
            // bindDrawable()
            _blur.transform = CGAffineTransform(rotationAngle: -CGFloat.pi * 0.5)
            _blur.contentMode = .scaleAspectFill
            _blur.backgroundColor = .clear
            _blur.translatesAutoresizingMaskIntoConstraints = false
            addSubview(_blur)
            _blur.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
            _blur.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
            _blur.topAnchor.constraint(equalTo: topAnchor).isActive = true
            _blur.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        }
        
        public func draw(buffer: CMSampleBuffer) {
            guard isDrawingEnabled else { return }
            autoreleasepool{ _queue.async { [weak self] in
                let _imgbuffer = CMSampleBufferGetImageBuffer(buffer)
                guard _imgbuffer != nil && self != nil && self?.bounds.width != 0.0 && self?.bounds.height != 0.0 else {
                    self?.deleteDrawable()
                    return
                }
                let imageBuffer = _imgbuffer!
                let wself = self!
                let sourceImage = CIImage(cvPixelBuffer: imageBuffer)
                let drawRect = wself._drawRect(for: sourceImage.extent)
                wself.bindDrawable()
                EAGLContext.setCurrent(wself._eaglContext)
                // Clear eagl view to black
                glClearColor(0.0, 0.0, 0.0, 1.0)
                glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
                // Set the blend mode to "source over" so that CI will use that
                glEnable(GLenum(GL_BLEND))
                glBlendFunc(GLenum(GL_ONE), GLenum(GL_ONE_MINUS_SRC_ALPHA))
                let _bounds = CGRect(origin: wself.bounds.origin, size: CGSize(width: wself.bounds.width * UIScreen.main.scale, height: wself.bounds.height * UIScreen.main.scale))
                wself._ciContext.draw(sourceImage, in: _bounds, from: drawRect)
                wself.display()
                } }
        }
        
        public func blur(_ image: UIImage?, animated: Bool = true, duration: TimeInterval = 0.15) {
            guard !blured else { return }
            _blured = true
            if Thread.current.isMainThread {
                __blur(image, animated: animated, duration: duration)
            } else { DispatchQueue.main.async { [weak self] in
                self?.__blur(image, animated: animated, duration: duration)
                } }
        }
        
        public func unBlur(_ animated: Bool = true, duration: TimeInterval = 0.15) {
            guard blured else { return }
            _blured = false
            if Thread.current.isMainThread {
                __blur(nil, animated: animated, duration: duration)
            } else { DispatchQueue.main.async { [weak self] in
                self?.__blur(nil, animated: animated, duration: duration)
                } }
        }
        
        private func __blur(_ image: UIImage?, animated: Bool, duration: TimeInterval = 0.15) {
            if image != nil || !animated {
                _blur.image = image
            }
            if animated {
                _blur.alpha = image == nil ? 1.0 : 0.0
                UIView.animate(withDuration: duration, animations: { [unowned self] in
                    self._blur.alpha = image == nil ? 0.0 : 1.0
                    }, completion: { [unowned self] (_) in
                        self._blur.alpha = 1.0
                        if image == nil {
                            self._blur.image = nil
                        }
                })
            }
        }
        
        private func _drawRect(`for` sourceExtent: CGRect) -> CGRect {
            if _extent == sourceExtent && !_drawRectNeedsUpdate {
                return _drawRect
            }
            _extent = sourceExtent
            
            let sourceAspect = _extent.width / _extent.height
            let previewAspect = bounds.width / bounds.height
            // we want to maintain the aspect radio of the screen size, so we clip the video image
            _drawRect = sourceExtent
            if sourceAspect > previewAspect {
                // use full height of the video image, and center crop the width
                _drawRect.origin.x += (_drawRect.width - _drawRect.height * previewAspect) * 0.5
                _drawRect.size.width = _drawRect.height * previewAspect
            } else {
                // use full width of the video image, and center crop the height
                _drawRect.origin.y += (_drawRect.height - _drawRect.width / previewAspect) * 0.5
                _drawRect.size.height = _drawRect.width / previewAspect
            }
            _drawRectNeedsUpdate = false
            return _drawRect
        }
    }
}

extension CameraViewController {
    internal final class _PresentationAnimator: NSObject {
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

extension CameraViewController._PresentationAnimator: UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return isDismissal ? 0.35 : 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let duration = transitionDuration(using: transitionContext)
        let containerView = transitionContext.containerView
        let view = transitionContext.view(forKey: isDismissal ? .from : .to)!
        let viewController = transitionContext.viewController(forKey: isDismissal ? .from : .to)! as! CameraViewController
        let imagePicker = transitionContext.viewController(forKey: isDismissal ? .to: .from) as! TabNavigationImagePickerController
        let finalFrame = transitionContext.finalFrame(for: viewController)
        
        containerView.addSubview(view)
        let scale = CGPoint(x: previewOriginFrame.width / finalFrame.width, y: previewOriginFrame.height / finalFrame.height)
        let translation = CGPoint(x: previewOriginFrame.midX - finalFrame.midX, y: previewOriginFrame.midY - finalFrame.midY)
        
        if isDismissal {
            containerView.insertSubview(transitionContext.view(forKey: .to)!, at: 0)
            let displayView = CameraViewController.CaptureVideoDisplayView()
            displayView.frame = view.bounds
            containerView.insertSubview(displayView, belowSubview: view)
            imagePicker._captureDisplayViews.update(with: displayView)
            let backgroundColor = view.backgroundColor
            view.backgroundColor = .clear
            
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.9, initialSpringVelocity: 1.0, options: [], animations: {
                view.transform = CGAffineTransform(scaleX: scale.x, y: scale.y).translatedBy(x: translation.x / scale.x, y: translation.y / scale.y)
                displayView.frame = self.previewOriginFrame
                viewController._topBar.alpha = 0.0
                viewController._previewView.alpha = 0.0
                viewController._bottomBar.alpha = 0.0
            }) { (_) in
                if let index = imagePicker._captureDisplayViews.index(of: displayView) {
                    imagePicker._captureDisplayViews.remove(at: index)
                }
                view.backgroundColor = backgroundColor
                viewController._previewView.alpha = 1.0
                transitionContext.completeTransition(true)
            }
            /* UIView.animate(withDuration: duration * 0.8, delay: duration * 0.2, options: [], animations: {
             viewController._previewView.alpha = 0.0
             }) { (_) in
             viewController._previewView.alpha = 1.0
             } */
        } else {
            view.transform = CGAffineTransform(scaleX: scale.x, y: scale.y).translatedBy(x: translation.x / scale.x, y: translation.y / scale.y)
            viewController._topBar.alpha = 0.0
            viewController._bottomBar.alpha = 0.0
            UIView.animate(withDuration: duration, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
                view.transform = .identity
                viewController._topBar.alpha = 1.0
                viewController._bottomBar.alpha = 1.0
            }) { (_) in
                transitionContext.completeTransition(true)
            }
        }
    }
}

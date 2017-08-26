//
//  Previews.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import GLKit
import AVFoundation

// MARK: - CaptureVideoPreviewView.

@available(iOS 9.0, *)
open class CaptureVideoPreviewView: UIView {
    override open class var layerClass: AnyClass { return AVCaptureVideoPreviewLayer.self }
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
    
    fileprivate let _focusIndicator     : UIImageView = UIImageView(image: UIImage(named: _Resource.bundle+"auto_focus"))
    fileprivate let _exposureIndicator  : UIImageView = UIImageView(image: UIImage(named: _Resource.bundle+"sun_shape_light"))
    fileprivate let _co_focusIndicator  : UIImageView = UIImageView(image: UIImage(named: _Resource.bundle+"co_auto_focus"))
    
    fileprivate let _exposureSliders    : (top: UIImageView, bottom: UIImageView)           = (UIImageView(), UIImageView())
    fileprivate var _exposureCenters    : (isoBinding: CGPoint, translation: CGPoint)       = (.zero, .zero)
    fileprivate var _exposureSettings   : (duration: CMTime, iso: Float, targetBias: Float) = (AVCaptureExposureDurationCurrent, 0.0, 0.0)
    fileprivate let _exposureSizes      : (top: CGSize, middle: CGSize, bottom: CGSize)     = (CGSize(width: 28.0, height: 28.0), CGSize(width: 25.0, height: 25.0), CGSize(width: 16.0, height: 16.0))
    
    fileprivate var _focusBeginning     : Date = Date()
    fileprivate var _co_focusBeginning  : Date = Date()
    fileprivate let _grace_du           : Double = 0.35
    fileprivate let _paddingOfFoexposure: CGFloat = 5.0
    fileprivate let _lengthOfSliderSpace: CGFloat = 150.0
    
    // Device observing keypaths.
    fileprivate let _deviceObservingKeyPaths = ["adjustingFocus", "focusMode", "flashActive", "exposureDuration", "ISO", "exposureTargetBias",  "exposureTargetOffset"]
    
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
        if let device = videoDevice { observe(device: device, removing: true) }
    }
    
    // MARK: Override.
    
    override open func willMove(toSuperview newSuperview: UIView?) {
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
        if let device = videoDevice { observe(device: device) }
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

extension CaptureVideoPreviewView {
    /// Add/Remove the key-path observing info to observe the device 
    /// for the changes of environments of the device if any to update
    /// the corresponding ui or other infos.
    ///
    /// - Parameter device  : The device to be added or removed.
    /// - Parameter removing: True to remove the observed key-paths, otherwise, 
    ///                       add the key-paths to it.
    internal func observe(device: AVCaptureDevice, removing: Bool = false) {
        if removing {
            _deviceObservingKeyPaths.forEach{ device.removeObserver(self, forKeyPath: $0, context: nil) }
        } else {
            _deviceObservingKeyPaths.forEach{ device.addObserver(self, forKeyPath: $0, options: .new, context: nil) }
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

public extension CaptureVideoPreviewView {
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

extension CaptureVideoPreviewView {
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
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
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

extension CaptureVideoPreviewView {
    internal class _ImageView: UIImageView {
        override var intrinsicContentSize: CGSize { return image?.size ?? .zero }
        override var image: UIImage? {
            didSet { invalidateIntrinsicContentSize() }
        }
    }
}

extension CaptureVideoPreviewView {
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

// MARK: - CaptureVideoDisplayView.

open class CaptureVideoDisplayView: GLKView {
    // fileprivate class var `default`: Self { return CaptureVideoDisplayView() }
    public var eaglContext: EAGLContext { return _eaglContext }
    fileprivate let _eaglContext = EAGLContext(api: .openGLES3)!
    
    public var ciContext: CIContext! { return _ciContext }
    fileprivate var _ciContext: CIContext!
    
    open var blured: Bool { return _blured }
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
    override open func layoutSubviews() {
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
    
    open func draw(buffer: CMSampleBuffer) {
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
    
    open func blur(_ image: UIImage?, animated: Bool = true, duration: TimeInterval = 0.15) {
        guard !blured else { return }
        _blured = true
        if Thread.current.isMainThread {
            __blur(image, animated: animated, duration: duration)
        } else { DispatchQueue.main.async { [weak self] in
            self?.__blur(image, animated: animated, duration: duration)
            } }
    }
    
    open func unBlur(_ animated: Bool = true, duration: TimeInterval = 0.15) {
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

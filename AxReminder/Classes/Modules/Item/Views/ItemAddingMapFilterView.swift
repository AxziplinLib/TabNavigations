//
//  ItemAddingMapFilterView.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/19.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

private let RadiusMinimalThreshold: CGFloat = 20.0

extension ItemAddingMapFilterView {
    enum DrawingMode {
        case inside
        case outside
    }
}

class ItemAddingMapFilterView: UIView {
    fileprivate var _handlerView: UIView
    public var widthOfHandler: CGFloat = 20.0 {
        didSet {
            _handlerView.layer.cornerRadius = widthOfHandler * 0.5
            _handlerView.layer.masksToBounds = true
        }
    }
    public var radius: CGFloat = 50.0 {
        didSet {
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    public var drawingMode: DrawingMode = .outside {
        didSet {
            setNeedsDisplay()
        }
    }
    
    override init(frame: CGRect) {
        _handlerView = UIView()
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        _handlerView = UIView()
        super.init(coder: aDecoder)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        _initializer()
    }
    private func _initializer() {
        backgroundColor = .clear
        
        _handlerView.backgroundColor = .black
        _handlerView.layer.cornerRadius = widthOfHandler * 0.5
        _handlerView.layer.masksToBounds = true
        _handlerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(_handleSliderPanGesture(_:))))
        
        addSubview(_handlerView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = CGSize(width: radius*2.0, height: radius*2.0)
        let origin = CGPoint(x: bounds.width * 0.5 - size.width * 0.5, y: bounds.height * 0.5 - size.height * 0.5)
        let frame = CGRect(origin: origin, size: size)
        
        _handlerView.frame = CGRect(origin: .zero, size: CGSize(width: widthOfHandler, height: widthOfHandler))
        _handlerView.center = CGPoint(x: bounds.width * 0.5 + frame.width * 0.5 - 5.0 * 0.5, y: bounds.height * 0.5)
        
        setNeedsDisplay()
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if _handlerView.frame.contains(point) {
            return _handlerView
        }
        return nil
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let _center = CGPoint(x: bounds.width * 0.5, y: bounds.height * 0.5)
        
        context.setFillColor(UIColor.application.blue.withAlphaComponent(0.15).cgColor)
        
        if drawingMode == .outside {
            let outterPath = CGPath(rect: bounds, transform: nil)
            context.addPath(outterPath)
            context.fillPath()
        }
        
        context.addArc(center: _center, radius: radius - 2.5, startAngle: 0.0, endAngle: CGFloat.pi * 2.0, clockwise: true)
        
        if drawingMode == .outside {
            context.setBlendMode(.clear)
        }
        context.fillPath()
        
        if drawingMode == .outside {
            context.setBlendMode(.normal)
        }
        
        context.beginPath()
        context.setLineWidth(5.0)
        context.setStrokeColor(UIColor.application.blue.cgColor)
        context.addArc(center: _center, radius: radius - 2.5, startAngle: 0.0, endAngle: CGFloat.pi * 2.0, clockwise: true)
        context.strokePath()
        
        context.beginPath()
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineDash(phase: 2.0, lengths: [4.0, 2.0])
        context.setStrokeColor(UIColor.black.cgColor)
        context.move(to: _center)
        context.addLine(to: _handlerView.center)
        context.strokePath()
    }
    
    // MARK: - Private.
    
    @objc
    private func _handleSliderPanGesture(_ sender: UIPanGestureRecognizer) {
        switch sender.state {
        case .changed:
            self.radius = min(bounds.height * 0.5, max(RadiusMinimalThreshold, sender.location(in: self).x - center.x))
        default: break
        }
    }
}

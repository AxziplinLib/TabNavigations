//
//  ItemAddingMapFilterView.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/19.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

private let RadiusMinimalThreshold: CGFloat = 20.0

class ItemAddingMapFilterView: UIView {
    fileprivate var _circleView: UIView
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
    
    override init(frame: CGRect) {
        _circleView = UIView()
        _handlerView = UIView()
        super.init(frame: frame)
    }
    required init?(coder aDecoder: NSCoder) {
        _circleView = UIView()
        _handlerView = UIView()
        super.init(coder: aDecoder)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        _initializer()
    }
    private func _initializer() {
        _circleView.isUserInteractionEnabled = false
        _circleView.backgroundColor = UIColor.clear
        _circleView.layer.borderWidth = 5.0
        _circleView.layer.borderColor = UIColor.application.blue.cgColor
        
        _handlerView.backgroundColor = .black
        _handlerView.layer.cornerRadius = widthOfHandler * 0.5
        _handlerView.layer.masksToBounds = true
        _handlerView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(_handleSliderPanGesture(_:))))
        
        addSubview(_circleView)
        addSubview(_handlerView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let size = CGSize(width: radius*2.0, height: radius*2.0)
        let origin = CGPoint(x: bounds.width * 0.5 - size.width * 0.5, y: bounds.height * 0.5 - size.height * 0.5)
        _circleView.frame = CGRect(origin: origin, size: size)
        _circleView.layer.cornerRadius = radius
        _circleView.layer.masksToBounds = true
        
        _handlerView.frame = CGRect(origin: .zero, size: CGSize(width: widthOfHandler, height: widthOfHandler))
        _handlerView.center = CGPoint(x: _circleView.center.x + _circleView.bounds.width * 0.5 - _circleView.layer.borderWidth * 0.5, y: _circleView.center.y)
        
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
        context.setFillColor(UIColor.application.blue.withAlphaComponent(0.05).cgColor)
        
        let outterPath = CGPath(rect: bounds, transform: nil)
        context.addPath(outterPath)
        context.fillPath()
        
        let innerPath = CGPath(roundedRect: _circleView.frame, cornerWidth: radius, cornerHeight: radius, transform: nil)
        context.addPath(innerPath)
        
        context.setBlendMode(.clear)
        context.fillPath()
        
        // context.beginPath()
        context.setLineWidth(1.0)
        context.setLineDash(phase: 1.0, lengths: [1.0, 2])
        context.setStrokeColor(UIColor.black.cgColor)
        context.move(to: _circleView.center)
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

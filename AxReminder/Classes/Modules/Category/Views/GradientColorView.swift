//
//  GradientColorView.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/7.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class GradientColorView: UIView {
    private var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    var beginsColor: UIColor = .clear {
        didSet {
            gradientLayer.colors = [beginsColor.cgColor, endsColor.cgColor]
        }
    }
    var endsColor: UIColor = .clear {
        didSet {
            gradientLayer.colors = [beginsColor.cgColor, endsColor.cgColor]
        }
    }
    
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    // MARK: - Initiaizer
    override init(frame: CGRect) {
        super.init(frame: frame)
        _initializer()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    
    private func _initializer() {
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1.0)
        gradientLayer.colors = [beginsColor, endsColor]
    }
}

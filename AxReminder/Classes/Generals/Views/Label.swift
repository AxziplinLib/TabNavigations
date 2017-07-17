//
//  Label.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/13.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import YYText

class Label: UILabel {
    override var isHidden: Bool {
        get { return super.isHidden }
        set {
            super.isHidden = newValue
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return isHidden ? .zero : super.intrinsicContentSize
    }
}

class AxLabel: YYLabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if preferredMaxLayoutWidth != bounds.width {
            preferredMaxLayoutWidth = bounds.width
        }
    }
}

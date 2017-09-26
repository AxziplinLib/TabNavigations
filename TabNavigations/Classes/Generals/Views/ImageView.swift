//
//  ImageView.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/13.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

extension ImageView {
    public enum ContentFits: Int {
        case width
        case height
    }
}
@IBDesignable
public class ImageView: UIImageView {
    @IBInspectable
    public var contentFits: ContentFits = .width {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    public override var intrinsicContentSize: CGSize {
        guard let img = image else {
            return super.intrinsicContentSize
        }
        let size = img.size
        if contentFits == .width {
            let width = bounds.width
            let height = size.height * (width / size.width)
            return CGSize(width: width, height: height)
        } else {
            let height = bounds.height
            let width = size.width * (height / size.height)
            return CGSize(width: width, height: height)
        }
    }
}

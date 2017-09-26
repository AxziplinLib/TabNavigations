//
//  TextView.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/18.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

@IBDesignable
class TextView: UITextView {
    @IBInspectable
    public var placeholder: String? {
        get { return _placeholderLabel.text }
        set { _placeholderLabel.text = newValue
            _refresh()
        }
    }
    @IBInspectable
    public var attributedPlaceholder: NSAttributedString? {
        get { return _placeholderLabel.attributedText }
        set { _placeholderLabel.attributedText = newValue
            _refresh()
        }
    }
    
    private var _placeholderLabel: UILabel = { () -> UILabel in
        let label = UILabel()
        label.backgroundColor = .clear
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        _initializer()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        _initializer()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        _initializer()
    }
    
    private func _initializer() {
        textContainer.lineFragmentPadding = 0.0
        textContainer.widthTracksTextView = true
        _placeholderLabel.font = self.font
        _placeholderLabel.textColor = UIColor(white: 0.7, alpha: 1.0)
        addSubview(_placeholderLabel)
        _placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        _placeholderLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        _placeholderLabel.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor).isActive = true
    }
    
    override var text: String! {
        didSet {
            _refresh()
        }
    }
    override var font: UIFont? {
        didSet {
            _placeholderLabel.font = font
        }
    }
    
    override var delegate: UITextViewDelegate? {
        get {
            _refresh()
            return super.delegate
        }
        set { super.delegate = newValue }
    }
    
    private func _refresh() {
        if !text.isEmpty {
            _placeholderLabel.alpha = 0.0
        } else {
            _placeholderLabel.alpha = 1.0
        }
    }
}

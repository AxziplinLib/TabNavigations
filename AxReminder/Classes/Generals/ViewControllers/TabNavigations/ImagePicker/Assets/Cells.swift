//
//  Cells.swift
//  AxReminder
//
//  Created by devedbox on 2017/8/26.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

// MARK: _AssetsCollectionCell.

extension AssetsViewController {
    public final class AssetsCollectionCell: UICollectionViewCell {
        public var imageView: UIImageView { return _imageView }
        private let _imageView: UIImageView = UIImageView()
        
        private let _selectionIndicator = UIImageView(image: #imageLiteral(resourceName: "image_selected"))
        
        override public init(frame: CGRect) {
            super.init(frame: frame)
            _initializer()
        }
        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            _initializer()
        }
        
        private func _initializer() {
            _imageView.translatesAutoresizingMaskIntoConstraints = false
            _selectionIndicator.translatesAutoresizingMaskIntoConstraints = false
            
            contentView.addSubview(_imageView)
            contentView.addSubview(_selectionIndicator)
            
            _imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
            _imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
            _imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
            _imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
            _selectionIndicator.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8.0).isActive = true
            _selectionIndicator.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8.0).isActive = true
            
            _imageView.contentMode = .scaleAspectFill
            _imageView.clipsToBounds = true
            _selectionIndicator.backgroundColor = .clear
            isSelected = false
        }
        
        override public func prepareForReuse() {
            super.prepareForReuse()
            
            _imageView.image = nil
        }
        
        override public var isSelected: Bool {
            didSet {
                if !isSelected {
                    self._selectionIndicator.alpha = 0.0
                    _selectionIndicator.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                } else {
                    _selectionIndicator.alpha = 1.0
                    self._selectionIndicator.transform = .identity
                }
            }
        }
    }
}

// MARK: _AssetsCaptureVideoPreviewCollectionCell.

extension AssetsViewController {
    public final class AssetsCaptureVideoPreviewCollectionCell: UICollectionViewCell {
        public var cameraView: UIImageView { return _cameraView }
        private let _cameraView: UIImageView = UIImageView(image: #imageLiteral(resourceName: "camera"))
        
        public var placeholder: UIImageView { return _placeholder }
        private let _placeholder: UIImageView = UIImageView()
        
        override public init(frame: CGRect) {
            super.init(frame: frame)
            _initializer()
        }
        required public init?(coder aDecoder: NSCoder) {
            super.init(coder: aDecoder)
            _initializer()
        }
        private func _initializer() {
            contentView.clipsToBounds = true
            contentView.backgroundColor = .black
            _placeholder.backgroundColor = .clear
            _cameraView.tintColor = UIColor.white.withAlphaComponent(0.8)
            
            _placeholder.translatesAutoresizingMaskIntoConstraints = false
            _cameraView.translatesAutoresizingMaskIntoConstraints = false
            addSubview(_placeholder)
            addSubview(_cameraView)
            
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[placeholder]|", options: [], metrics: nil, views: ["placeholder":_placeholder]))
            addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[placeholder]|", options: [], metrics: nil, views: ["placeholder":_placeholder]))
            _cameraView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
            _cameraView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        }
    }
}

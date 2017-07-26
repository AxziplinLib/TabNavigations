//
//  ItemAddingImageCollectionViewCell.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/25.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

extension ItemAddingImageCollectionViewCell {
    override var reuseIdentifier: String { return "_ItemAddingImageCollectionViewCell" }
}

class ItemAddingImageCollectionViewCell: CollectionViewCell {
    @IBOutlet public weak var imageView: UIImageView!
}

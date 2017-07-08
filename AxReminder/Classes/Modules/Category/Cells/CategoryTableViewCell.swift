//
//  CategoryTableViewCell.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/7.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

extension CategoryTableViewCell {
    public class var reusedIdentifier: String { return "_CategoryTableViewCell" }
}

class CategoryTableViewCell: TableViewCell {
    @IBOutlet weak var backGradientView: GradientColorView!
    @IBOutlet weak var frontGradientView: GradientColorView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var seachButton: UIButton!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var remainLabel: UILabel!
    @IBOutlet weak var timingLabel: UILabel!
    
    var beginsColor: UIColor! {
        didSet {
            backGradientView.beginsColor = beginsColor
            frontGradientView.beginsColor = beginsColor
        }
    }
    var endsColor: UIColor! {
        didSet {
            backGradientView.endsColor = endsColor
            frontGradientView.endsColor = endsColor
        }
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        backGradientView.layer.cornerRadius = 12.0
        backGradientView.layer.masksToBounds = true
        frontGradientView.layer.cornerRadius = 10.8
        frontGradientView.layer.masksToBounds = true
        seachButton.layer.cornerRadius = 5.0
        seachButton.layer.masksToBounds = true
    }
}

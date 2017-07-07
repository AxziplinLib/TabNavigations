//
//  SettingsTableViewCell.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/7.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class SettingsTableViewCell: TableViewCell {
    @IBOutlet weak var backgroundContentView: UIView?
    
    // MARK: - Overrides.
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundContentView?.clipsToBounds = false
        
        backgroundContentView?.layer.shadowColor = UIColor(white: 0.0, alpha: 0.1).cgColor
        backgroundContentView?.layer.shadowOpacity = 1.0
        // backgroundContentView?.layer.shadowRadius = 6.0
        backgroundContentView?.layer.cornerRadius = 8.0
        backgroundContentView?.layer.shadowOffset = .zero
    }
}

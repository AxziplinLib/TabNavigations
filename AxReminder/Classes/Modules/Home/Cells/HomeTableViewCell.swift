//
//  HomeTableViewCell.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/28.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

extension HomeTableViewCell {
    override public class var reusedIdentifier: String { return "_HomeTableViweCell" }
}

extension HomeTableViewCell {
}

class HomeTableViewCell: TableViewCell {
    @IBOutlet weak var readedIndicator: UIButton!
    @IBOutlet weak var contentLabel: AxLabel!
    @IBOutlet weak var contentImageView: ImageView!
    @IBOutlet weak var createTimeLabel: Label!
    @IBOutlet weak var deadlineTimeLabel: Label!
    @IBOutlet weak var locationLabel: Label!
    @IBOutlet weak var locationIndicatorLabel: Label!
    
    @IBOutlet private weak var _imageTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var _timingTopConstraint: NSLayoutConstraint!
    @IBOutlet private weak var _locationTopConstraint: NSLayoutConstraint!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        contentLabel.text = nil
        contentLabel.attributedText = nil
    }
    
    public var showsImageContent: Bool = true {
        didSet {
            if showsImageContent {
                _imageTopConstraint.constant = 8.0
                contentImageView.isHidden = false
            } else {
                _imageTopConstraint.constant = 0.0
                contentImageView.isHidden = true
            }
        }
    }
    
    public var showsTimingContent: Bool = true {
        didSet {
            if showsTimingContent {
                _timingTopConstraint.constant = 6.0
                createTimeLabel.isHidden = false
                deadlineTimeLabel.isHidden = false
            } else {
                _timingTopConstraint.constant = 0.0
                createTimeLabel.isHidden = true
                deadlineTimeLabel.isHidden = true
            }
        }
    }
    
    public var showsLocationContent: Bool = true {
        didSet {
            if showsLocationContent {
                _locationTopConstraint.constant = 2.0
                locationLabel.isHidden = false
                locationIndicatorLabel.isHidden = false
            } else {
                _locationTopConstraint.constant = 0.0
                locationLabel.isHidden = true
                locationIndicatorLabel.isHidden = true
            }
        }
    }
}

//
//  ItemAddingTextViewTableViewCell.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/18.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

extension ItemAddingTextViewTableViewCell {
    override public class var reusedIdentifier: String { return "_ItemAddingTextViewTableViewCell" }
}

class ItemAddingTextViewTableViewCell: TableViewCell {
    @IBOutlet weak var textView: TextView!
}

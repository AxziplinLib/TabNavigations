//
//  CategoryAddingTableViewCell.swift
//  AxReminder
//
//  Created by devedbox on 2017/7/12.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit

class CategoryAddingTableViewCell: TableViewCell { }

extension CategoryAddingTextFieldTableViewCell {
    override public class var reusedIdentifier: String { return "_CategoryAddingTextFieldTableViewCell" }
}
class CategoryAddingTextFieldTableViewCell: CategoryAddingTableViewCell {
    @IBOutlet weak var textfield: UITextField!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        textfield.attributedPlaceholder = NSAttributedString(string: textfield.placeholder ?? "", attributes: [NSForegroundColorAttributeName: UIColor(hex: "9B9B9B")])
    }
}

extension CategoryAddingColorTableViewCell {
    override public class var reusedIdentifier: String { return "_CategoryAddingColorTableViewCell" }
}
class CategoryAddingColorTableViewCell: CategoryAddingTableViewCell {
    @IBOutlet weak var gradientColorView: GradientColorView!
    @IBOutlet weak var previewLabel: UILabel!
    @IBOutlet weak var selectionImg: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Ignored unanimated.
        UIView.animate(withDuration: 0.25, animations: { [unowned self] in
            self.selectionImg.alpha = selected ? 1.0 : 0.0
        })
    }
}

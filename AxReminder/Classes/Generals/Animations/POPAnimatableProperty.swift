//
//  POPAnimatableProperty.swift
//  AxReminder
//
//  Created by devedbox on 2017/6/27.
//  Copyright © 2017年 devedbox. All rights reserved.
//

import UIKit
import pop

extension POPAnimatableProperty {
    // Animatable property for font size of label.
    class func labelFontSize(named fontName: String?) -> POPAnimatableProperty {
        let property = POPAnimatableProperty.property(withName: "FONT") { prop in
            prop?.readBlock = { obj, vlus in
                let label = obj as! UILabel
                let values = vlus
                
                values![0] = label.font.pointSize
            }
            
            prop?.writeBlock = { obj, vlus in
                let label = obj as! UILabel
                let values = vlus
                
                let fontSize: CGFloat = values![0]
                label.font = fontName == nil ? UIFont.systemFont(ofSize: fontSize) : UIFont(name: fontName!, size: fontSize)
                
            }
            
            prop?.threshold = 0.01
        } as! POPAnimatableProperty
        return property
    }
    
    // Animatable property for title color of button.
    class func buttonTitleColor(`for` state: UIControlState) -> POPAnimatableProperty {
        let property = POPAnimatableProperty.property(withName: "TITLECOLOR") { prop in
            prop?.readBlock = { obj, vlus in
                let button = obj as! UIButton
                let values = vlus
                
                let stateColor = button.titleColor(for: state)
                
                var red: CGFloat = 0.0
                var green: CGFloat = 0.0
                var blue: CGFloat = 0.0
                var alpha: CGFloat = 0.0
                
                stateColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                values![0] = red
                values![1] = green
                values![2] = blue
                values![3] = alpha
            }
            
            prop?.writeBlock = { obj, vlus in
                let button = obj as! UIButton
                let values = vlus
                
                button.setTitleColor(UIColor(red: values![0], green: values![1], blue: values![2], alpha: values![3]), for: state)
                
            }
            
            prop?.threshold = 0.01
            } as! POPAnimatableProperty
        return property
    }
}

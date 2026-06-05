//
//  UILabel+Extensions.swift
//  Actifit
//
//  Created by Ali Jaber on 03/07/2023.
//

import Foundation
import UIKit

extension UILabel {
    func underLine() {
        guard let text = self.text else { return }
        
        let attributedString = NSMutableAttributedString(string: text)
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: NSRange(location: 0, length: attributedString.length))
        self.attributedText = attributedString
    }
}

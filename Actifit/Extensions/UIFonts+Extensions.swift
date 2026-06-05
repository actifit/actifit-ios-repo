//
//  UIFonts+Extensions.swift
//  Actifit
//
//  Created by Ali Jaber on 04/07/2023.
//

import Foundation
import UIKit
extension UIFont {
    static func boldFont(ofSize fontSize: CGFloat) -> UIFont {
        guard let boldFont = UIFont(name: "Helvetica-Bold", size: fontSize) else {
            return UIFont.systemFont(ofSize: fontSize, weight: .bold)
        }
        return boldFont
    }
    
    var italicBold: UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits([.traitItalic, .traitBold]) {
            return UIFont(descriptor: descriptor, size: 0)
        }
        return self
    }
}

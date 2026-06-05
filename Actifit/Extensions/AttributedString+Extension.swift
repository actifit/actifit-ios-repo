//
//  AttributedString+Extension.swift
//  Actifit
//
//  Created by Hitender kumar on 13/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import Foundation
import UIKit
import FontAwesome_swift
extension NSAttributedString {
    func heightFor(boundingWidth : CGFloat) -> CGFloat {
        let rect = self.boundingRect(with: CGSize.init(width: boundingWidth, height: CGFloat.greatestFiniteMagnitude), options: NSStringDrawingOptions.usesLineFragmentOrigin, context: nil)
        return rect.height
    }
    
    static func generateFontAwesomeString(code: String, size: CGFloat) -> NSAttributedString {
        return NSAttributedString(string: code, attributes: [.font : UIFont.fontAwesome(ofSize: size, style: .solid) ] )
    }
}



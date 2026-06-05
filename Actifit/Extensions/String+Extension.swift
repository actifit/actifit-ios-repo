//
//  String+Extension.swift
//  Actifit
//
//  Created by Hitender kumar on 13/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import Foundation
import UIKit

extension String {
    func attributedString(font : UIFont, textColor : UIColor) -> NSMutableAttributedString {
        let attributedStr = NSMutableAttributedString.init(string: self)
        attributedStr.addAttributes([NSAttributedStringKey.font : font, NSAttributedStringKey.foregroundColor : textColor], range: NSRange.init(location: 0, length: attributedStr.length))
        return attributedStr
    }
    
    func contains(find: String) -> Bool{
        return self.range(of: find) != nil
    }
    
    func containsIgnoringCase(find: String) -> Bool{
        return self.range(of: find, options: .caseInsensitive) != nil
    }
    
    func utf8Data() -> Data {
        return self.data(using: String.Encoding.utf8)!
    }
    
    func byTrimming(string : String) -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet.init(charactersIn: string))
    }
    func date(withFormat format: String = "yyyy-MM-dd") -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.date(from: self)
    }
    
    func dateComponents(withFormat format: String = "yyyy-MM-dd", components: Set<Calendar.Component> = [.day, .month, .year]) -> DateComponents? {
        return self.date(withFormat: format)?.dateComponents(components: components)
    }
    
}


extension String {
    func formatToThreeDecimalPlaces() -> String? {
        guard let doubleValue = Double(self) else {
                  return nil // Return nil if the string is not a valid number
              }

              let numberFormatter = NumberFormatter()
              numberFormatter.numberStyle = .decimal
              numberFormatter.maximumFractionDigits = 3
              numberFormatter.minimumFractionDigits = 3

              return numberFormatter.string(from: NSNumber(value: doubleValue))
    }
}

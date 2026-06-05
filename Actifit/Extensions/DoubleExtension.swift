//
//  DoubleExtension.swift
//  Actifit
//
//  Created by Ali Jaber on 03/04/2024.
//

import Foundation

extension Double {
  static func parse(from string: String) -> Double? {
    let decimalDigits = CharacterSet(charactersIn: "0123456789.")
    let cleanedString = string.components(separatedBy: decimalDigits.inverted).joined()
    return Double(cleanedString)
  }
}

//
//  AccountData.swift
//  Actifit
//
//  Created by Ali Jaber on 01/08/2023.
//

import Foundation
struct Blurt: Codable {
    let id: Int?
    let name: String?
    let balance: String?

    var balanceWithoutNaming: Double? {
        if let components = balance?.components(separatedBy: " ") {
            
            if components.count == 2, let doubleValue = Double(components[0]) {
                return doubleValue
            }
            
            return nil
            
        } else {
            return nil
        }
    }
}

struct BlurtObject: Codable {
    let blurt: Blurt

    enum CodingKeys: String, CodingKey {
        case blurt = "BLURT"
    }
}

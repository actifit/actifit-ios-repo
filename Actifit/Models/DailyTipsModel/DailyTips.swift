//
//  DailyTips.swift
//  Actifit
//
//  Created by Ali Jaber on 03/08/2023.
//

import Foundation
struct DailyTipsModel: Codable {
    let id: String?
    let tip: String?
    let rank: Int?
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case tip
        case rank
    }
    
}

//
//  AfitTokenModel.swift
//  Actifit
//
//  Created by Ali Jaber on 01/08/2023.
//

import Foundation
struct AfitTokenModel: Codable {
    let id: String?
    let user: String?
    let tokens: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case user
        case tokens
    }
}

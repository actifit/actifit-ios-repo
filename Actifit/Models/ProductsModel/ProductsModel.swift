//
//  ProductsModel.swift
//  Actifit
//
//  Created by Ali Jaber on 08/08/2023.
//

import Foundation

struct Product: Codable {
    let id: String?
    let name: String?
    let providerName: String?
    let active: Bool?
    let type: String?
    let price: [PriceModel]?
    let description: String?
    let count: Int?
    let onSale: Bool?
    let image: String?
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case name
        case providerName
        case active
        case type
        case price
        case description
        case count
        case onSale
        case image
    }
}

struct PriceModel: Codable {
    let currency: String?
    let price: Double?
    let actifitPercentCut: Int?
//    enum CodingKeys: String, CodingKey {
//        case currency
//        case price
//        case actifitPercentCut = "actifit_percent_cut"
//    }
}

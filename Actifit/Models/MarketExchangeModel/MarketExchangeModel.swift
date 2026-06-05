//
//  MarketExchangeModel.swift
//  Actifit
//
//  Created by Ali Jaber on 31/08/2023.
//

import Foundation
struct ExchangeMarketModel: Codable {
    let chain: String?
    let exchange: String?
    let link: String?
    let icon: String?
    let pairs: [Pairs]?
}

struct Pairs: Codable {
    let name: String?
    let link: String?
}


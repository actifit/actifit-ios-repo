//
//  HiveEngineBalanceResponse.swift
//  Actifit
//
//  Created by Ali Jaber on 18/11/2023.
//

import Foundation
struct HiveEngineBalanceResponse: Codable {

    let jsonrpc: String?
    let id: Int?
    let result: [TokenInfo]?
}

    struct TokenInfo: Codable {
        let id: Int?
        let account: String?
        let symbol: String?
        let balance: String?
        let stake: String?
        let pendingUnstake: String?
        let delegationsIn: String?
        let delegationsOut: String?
        let pendingUndelegations: String?
    }

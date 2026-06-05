//
//  GetChainInfoResponse.swift
//  Actifit
//
//  Created by Ali Jaber on 21/11/2023.
//

import Foundation
struct BlockchainInfoResponse: Codable {
    let hive: BlockchainDetail?
    let steem: BlockchainDetail?
    let blurt: BlockchainDetail?
    
    enum CodingKeys: String, CodingKey {
        case hive = "HIVE"
        case steem = "STEEM"
        case blurt = "BLURT"
    }
    
}

struct BlockchainDetail: Codable {
    let headBlockNumber: Int?
    let headBlockId: String?
    let totalPow: Int?
    let numPowWitnesses: Int?
    let virtualSupply: String?
    let currentSupply: String?
    let initHbdSupply: String?
    let currentHbdWupply: String?
    let confidentialSupply: String?
    let initSbdSupply: String?
    let currentSbdSupply: String?
    let confidentialSbdSupply: String?
    let totalVestingFundHive: String?
    let totalVestingShares: String?
    let pendingRewardedVestingShares: String?
    let pendingRewardedVestingHive: String?
}

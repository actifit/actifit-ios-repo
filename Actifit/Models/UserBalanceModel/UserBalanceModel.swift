//
//  UserBalanceModel.swift
//  Actifit
//
//  Created by Ali Jaber on 20/11/2023.
//

import Foundation
struct HiveObject: Codable {
    let hive: HiveDetails
    
    enum CodingKeys: String, CodingKey {
        case hive = "HIVE"
    }
}

struct HiveDetails: Codable {
//    let id: Int?
//    let name: String?
    let balance: String?
//    let savings_balance: String?
    let hbd_balance: String?
    let savings_hbd_balance: String?
//    let savings_hbd_seconds: String?
//    let savings_hbd_last_interest_payment: String?
//    let savings_withdraw_requests: Int?
//    let reward_hbd_balance: String?
//    let reward_hive_balance: String?
//    let reward_vesting_balance: String?
//    let reward_vesting_hive: String?
    let vesting_shares: String?
    let delegated_vesting_shares: String?
    let received_vesting_shares: String?
    let vesting_withdraw_rate: String?
    let post_voting_power: String?
//    let posting_rewards: Int?

}


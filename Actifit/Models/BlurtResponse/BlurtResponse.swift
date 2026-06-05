//
//  BlurtResponse.swift
//  Actifit
//
//  Created by Ali Jaber on 21/11/2023.
//

import Foundation

struct BlurtResponse: Codable {
    let blurt: BlurtDetails
    
    enum CodingKeys: String, CodingKey {
        case blurt = "BLURT"
    }
}


struct BlurtDetails: Codable {
    let id: Int?
    let balance: String?
    let savingsBalance: String?
    let hbdBalance: String?
    let savingsHbdBalance: String?
    let rewardHbdBalance: String?
    let rewardHiveBalance: String?
    let rewardVesitngBalance: String?
    let rewardVestingBalance: String?
    let vestingShares: String?
    let delegatedVestingShares: String?
    let receivedVestingShares: String?
    let vestingWithdrawRate: String?
    let postVotingPower: String?
    let nextVestingWithDrawal: String?
    let vestingBalance: String?
    let reputation: String?
    let rewardBlurtBalance: String?
    let rewardVestingBlurt: String?
    
    enum CodingKeys: String, CodingKey {
        case id, balance, reputation
        case savingsBalance = "savings_balance"
        case hbdBalance = "hbd_balance"
        case savingsHbdBalance = "savings_hbd_balance"
        case rewardHbdBalance = "reward_hbd_balance"
        case rewardHiveBalance = "reward_hive_balance"
        case rewardVesitngBalance = "reward_vesting_balance"
        case rewardVestingBalance = "reward_vesting_hive"
        case vestingShares = "vesting_shares"
        case delegatedVestingShares = "delegated_vesting_shares"
        case receivedVestingShares = "received_vesting_shares"
        case vestingWithdrawRate = "vesting_withdraw_rate"
        case postVotingPower = "post_voting_power"
        case nextVestingWithDrawal = "next_vesting_withdrawal"
        case vestingBalance =  "vesting_balance"
        case rewardBlurtBalance = "reward_blurt_balance"
        case rewardVestingBlurt = "reward_vesting_blurt"
        
    }
    
}

struct AccountPermission: Codable {
    let weightThreshold: Int
    let accountAuths: [String]
    let keyAuths: [[String]]
    
    enum CodingKeys: String, CodingKey {
        case weightThreshold = "weight_threshold"
        case accountAuths = "account_auths"
        case keyAuths = "key_auths"
    }
}

struct Manabar: Codable {
    let currentMana: Int
    let lastUpdateTime: Int
    
    enum CodingKeys: String, CodingKey {
        case currentMana = "current_mana"
        case lastUpdateTime = "last_update_time"
    }
}

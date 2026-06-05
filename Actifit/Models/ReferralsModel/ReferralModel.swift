//
//  ReferralModel.swift
//  Actifit
//
//  Created by Ali Jaber on 30/08/2023.
//

import Foundation

struct ReferralObject: Codable {
 //   let usdInvest: Int?
    //let steemInvest: Double?
   // let afitReward: Double?
   
    let memo: String?
    let date: String?
    let accountCreated: Bool?
    let referrer: String?
    //let referrerAfitReward: Float?
    let paymentConfirmed: Bool?
    let confirmingText: String?
    enum CodingKeys: String, CodingKey {
       // case usdInvest = "usd_invest"
      //  case steemInvest = "steem_invest"
       // case afitReward = "afit_reward"
        case memo
        case date
        case accountCreated = "account_created"
        case referrer
        //case referrerAfitReward = "referrer_afit_reward"
        case paymentConfirmed = "payment_confirmed"
        case confirmingText = "confirming_tx"
    }
}

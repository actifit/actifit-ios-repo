//
//  TransactionTipResponse.swift
//  Actifit
//
//  Created by Ali Jaber on 18/11/2023.
//

import Foundation
struct TipResponse: Codable {
    let status: String
    let tipAmount: Double
    let senderTokenCount: Double
    let recipientTokenCount: Double
}

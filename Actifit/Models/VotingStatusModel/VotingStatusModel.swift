//
//  VotingStatusModel.swift
//  Actifit
//
//  Created by Ali Jaber on 27/07/2023.
//

import Foundation
struct VotingStatusModel: Codable {
    let status: Status?
    let vp: Double?
    let rewardStart: String?

}

struct Status: Codable {
    let id: String?
    let isVoting: Bool?
    let votingStart: String?
    let votingEnd: String?

}

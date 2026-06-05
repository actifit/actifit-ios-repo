//
//  LeaderboardModel.swift
//  Actifit
//
//  Created by Ali Jaber on 11/09/2024.
//

import Foundation
struct LeaderboardModel: Codable {
    let leaderRank: Int
    let userProfilePic: String
    let author: String
    let activityCount: [String]
    let url: String
}

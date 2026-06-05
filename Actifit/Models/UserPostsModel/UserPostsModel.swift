//
//  UserPostsModel.swift
//  Actifit
//
//  Created by Ali Jaber on 16/08/2024.
//

import Foundation

struct HiveUserPosts: Codable {
    let id: String
    let jsonrpc: String
    let result: [Post]
}

// Post model
struct Post: Codable {
//    let activeVotes: [ActiveVote]
    let author: String
//    let authorPayoutValue: String
//    let authorReputation: Double
//    let authorRole: String
//    let authorTitle: String
//    let beneficiaries: [Beneficiary]
//    let blacklists: [String]
//    let body: String
//    let category: String
//    let children: Int
//    let community: String
//    let communityTitle: String
    let created: String
//    let curatorPayoutValue: String
//    let depth: Int
//    let isPaidout: Bool
    let jsonMetadata: JsonMetadata
//    let maxAcceptedPayout: String
//    let netRshares: Int
//    let payout: Double
//    let payoutAt: String
//    let pendingPayoutValue: String
//    let percentHbd: Int
    let permlink: String
//    let postID: Int
//    let promoted: String
//    let reblogs: Int
//    let replies: [String]
//    let stats: Stats
//    let title: String
//    let updated: String
//    let url: String

}


// JsonMetadata model
struct JsonMetadata: Codable {
    let actiCrVal: String?
    let actifitUserID: [String]?
    let activityDate: [String]?
    let activityType: [String]?
    let app: String?
    let appType: String?
    let bodyfat: [String]?
    let chest: [String]?
    let chestUnit: [String]?
    let community: [String]?
    let dataTrackingSource: [String]?
    let detailedActivity: [String]?
    let height: [String]?
    let heightUnit: [String]?
    let image: [String]?
    let stepCount: [String]?
    let tags: [String]?
    let thighs: [String]?
    let thighsUnit: [String]?
    let timezone: [String]?
    let users: [String]?
    let waist: [String]?
    let waistUnit: [String]?
    let weight: [String]?
    let weightUnit: [String]?

}

// Stats model
struct Stats: Codable {
    let flagWeight: Double?
    let gray: Bool?
    let hide: Bool?
    let totalVotes: Int?

}

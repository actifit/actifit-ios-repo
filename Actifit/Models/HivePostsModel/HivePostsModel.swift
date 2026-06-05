//
//  HivePostsModel.swift
//  Actifit
//
//  Created by Ali Jaber on 08/04/2024.
//

import Foundation
struct HivePosts: Codable {
    let id: Int?
    let jsonrpc: String?
    let result: [PostsResults]
}

struct PostsResults: Codable {
    let author: String?
    let blacklists: [String]?
    let body: String?
    let category: String?
    let children: Int?
    let created: String?
    let curatorPayoutValue: String?
    let depth: Int?
    let isPaidout: Bool?
    let maxAcceptedPayout: String?
    let netRshares: Int?
    let payout: Double?
    let payoutAt: String?
    let pendingPayoutValue: String?
    let percentHbd: Int?
    let permlink: String?
    let postId: Int?
    let promoted: String?
    let reblogs: Int?
    let replies: [String]?
    let title: String?
    let updated: String?
    let url: String?
    let authorPayoutValue: String?
    let totalPayoutValue: String?

    enum CodingKeys: String, CodingKey {
        case author
        case blacklists
        case body
        case category
        case children
        case created
        case curatorPayoutValue = "curator_payout_value"
        case depth
        case isPaidout = "is_paidout"
        case maxAcceptedPayout = "max_accepted_payout"
        case netRshares = "net_rshares"
        case payout
        case payoutAt = "payout_at"
        case pendingPayoutValue = "pending_payout_value"
        case percentHbd = "percent_hbd"
        case permlink
        case postId = "post_id"
        case promoted
        case reblogs
        case replies
        case title
        case updated
        case url
        case authorPayoutValue = "author_payout_value"
        case totalPayoutValue = "total_payout_value"
    }
}

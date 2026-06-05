//
//  SocialPosts.swift
//  Actifit
//
//  Created by Ali Jaber on 20/09/2024.
//

import Foundation
import Foundation

// Root Model
struct SocialPostModel: Codable, Equatable {
    let id: Int
    let jsonrpc: String
    let result: [SocialPost]
}

// Post Model
struct SocialPost: Codable, Equatable {
    static func == (lhs: SocialPost, rhs: SocialPost) -> Bool {
        return lhs.postId == rhs.postId
    }

    let activeVotes: [Vote]?
    let author: String
    let authorPayoutValue: String?
//    let authorReputation: Double?
//    let authorRole: String?
    let authorTitle: String
//    let beneficiaries: [String]
//    let blacklists: [String]
    let body: String
    let category: String?
    let children: Int
//    let community: String?
    let communityTitle: String?
    let created: String?
//    let curatorPayoutValue: String?
//    let depth: Int?
    let isPaidout: Bool?
    let jsonMetadata: Metadata
//    let maxAcceptedPayout: String?
//    let netRshares: Int?
//    let payout: Double?
//    let payoutAt: String?
   let pendingPayoutValue: String?
//    let percentHbd: Int?
    let permlink: String
    let postId: Int?
//    let promoted: String?
//    let reblogs: Int?
//    let replies: [String]
    //let stats: PostStats?
    let title: String
//    let updated: String?
    let url: String
    let totalPayoutValue: String?
}

// Vote Model
struct Vote: Codable {
    let rshares: Int?
    let voter: String?
}

// Metadata Model
struct Metadata: Codable {
    let activityType: [String]?
    let stepCount: [String]
    let tags: [String]?
    let image: [String]?
    let images: [String]?

    enum CodingKeys: String, CodingKey {
        case activityType
        case stepCount
        case tags
        case image
        case images
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode activityType and tags normally
        do {
            activityType = try container.decodeIfPresent([String].self, forKey: .activityType)
        } catch {
            print("Failed to decode activityType: \(error)")
            activityType = nil
        }

        do {
            tags = try container.decodeIfPresent([String].self, forKey: .tags)
        } catch {
            print("Failed to decode tags: \(error)")
            tags = nil
        }

        do {
            image = try container.decodeIfPresent([String].self, forKey: .image)
        } catch {
            print("Failed to decode image: \(error)")
            image = nil
        }

        do {
            images = try container.decodeIfPresent([String].self, forKey: .images)
        } catch {
            print("Failed to decode images: \(error)")
            images = nil
        }

        // Custom decoding for stepCount to handle both string and int cases
        do {
            if let stepCountString = try? container.decode([String].self, forKey: .stepCount) {
                stepCount = stepCountString
            } else if let stepCountInt = try? container.decode([Int].self, forKey: .stepCount) {
                stepCount = stepCountInt.map { String($0) }
            } else {
                stepCount = ["0"]
            }
        } catch {
            print("Failed to decode stepCount: \(error)")
            stepCount = ["0"]
        }
    }
}

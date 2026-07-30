//
//  HivePostComment.swift
//  Actifit
//
//  Created by Ali Jaber on 08/04/2024.
//

import Foundation

// Codable model for ActiveVote
class PostComments: Codable, Equatable {
    static func == (lhs: PostComments, rhs: PostComments) -> Bool {
        return lhs.author == rhs.author && lhs.permlink == rhs.permlink
    }

    let activeVotes: [ActiveVote]?
    let author: String
    let body: String
    let children: Int
    let created: String
    let id: Int
    let jsonMetadata: JSONMetadata?
    let permlink: String
    let netVotes: Int?
    var isSnap: Bool = false
    enum CodingKeys: String, CodingKey {
        case activeVotes// = "active_votes"
        case author
        case body
        case children
        case created
        case id
        case jsonMetadata// = "json_metadata"
        case permlink
        case netVotes// = "net_votes"
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode all the other properties as usual
        activeVotes = try? container.decode([ActiveVote].self, forKey: .activeVotes)
        author = try container.decode(String.self, forKey: .author)
        body = try container.decode(String.self, forKey: .body)
        children = try container.decode(Int.self, forKey: .children)
        created = try container.decode(String.self, forKey: .created)
        // Current Hive nodes no longer return `id` on condenser_api.get_content_replies, so a
        // required decode here threw and failed the WHOLE reply list (empty discussions). Decode
        // it when present, default to 0 otherwise.
        id = (try? container.decode(Int.self, forKey: .id)) ?? 0
        permlink = try container.decode(String.self, forKey: .permlink)
        netVotes = try? container.decode(Int.self, forKey: .netVotes)

        // Custom decoding for jsonMetadata
        // First, try to decode it as a JSONMetadata object
        if let metadata = try? container.decode(JSONMetadata.self, forKey: .jsonMetadata) {
            self.jsonMetadata = metadata
        }
        // If that fails, try to decode it as a string and then parse it as JSON
        else if let jsonString = try? container.decode(String.self, forKey: .jsonMetadata) {
            let data = jsonString.data(using: .utf8)
            if let jsonData = data {
                do {
                    self.jsonMetadata = try JSONDecoder().decode(JSONMetadata.self, from: jsonData)
                } catch {
                    print("Error decoding JSONMetadata from string: \(error)")
                    self.jsonMetadata = nil
                }
            } else {
                print("Invalid JSON string format")
                self.jsonMetadata = nil
            }
        } else {
            print("json_metadata could not be decoded as JSONMetadata or String")
            self.jsonMetadata = nil
        }
    }
    func updateSnapStatus(isSnap: Bool) {
        self.isSnap = isSnap
    }
}

struct ActiveVote: Codable {
    let voter: String?
    let percent: Int?
    let reputation: Int?
    let rshares: Int?
    let time: String?
    let weight: Int?
}

struct ActiveVotesResponse: Codable {
    let activeVotes: [ActiveVote]?
}

// Codable model for JSONRPCResponse
struct HivePostComment: Codable {
    let id: Int
    let jsonrpc: String
    let result: [PostComments]
}

struct JSONMetadata: Codable {
    let activityType: [String]?
    let stepCount: [Int]?
    let tags: [String]?

    enum CodingKeys: String, CodingKey {
        case activityType = "activity_type"
        case stepCount = "step_count"
        case tags
    }

    init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            activityType = try? container.decode([String].self, forKey: .activityType)
            tags = try? container.decode([String].self, forKey: .tags)

            // Custom decoding for stepCount
            if let singleStepCount = try? container.decode(Int.self, forKey: .stepCount) {
                // If it’s an integer, wrap it in an array
                self.stepCount = [singleStepCount]
            } else if let multipleStepCounts = try? container.decode([Int].self, forKey: .stepCount) {
                // If it’s an array of integers, assign it directly
                self.stepCount = multipleStepCounts
            } else {
                // If neither works, set it to nil
                self.stepCount = nil
            }
        }
}



//
//  AllHiveEngineTokenResponse.swift
//  Actifit
//
//  Created by Ali Jaber on 20/11/2023.
//

import Foundation
struct AllHiveEngineTokensResponse:Codable {
    let jsonrpc: String?
    let id: Int?
    let result: [TokenModel]?
}

struct TokenModel: Codable {
    let id: Int?
    let issuer: String?
    let symbol: String?
    let name: String?
    let metadata: String?


    mutating func extractIconURL() -> String {
        if let range = metadata?.range(of: "\"icon\":\"") {
            // Get the substring starting from the end of the icon key
            let substring = metadata?[range.upperBound...]
            
            // Find the end of the icon URL
            if let endRange = substring?.range(of: "\"") {
                // Extract the icon URL
                let iconURL = String(substring?[..<endRange.lowerBound] ?? "")
                return iconURL
            }
        }
        return ""
    }

  enum CodingKeys: String, CodingKey {
    case id = "_id"
    case issuer, symbol, name, metadata
  }
}



struct TokenMetadata: Codable {
    let url: String?
    let icon: String?
    let desc: String?
}


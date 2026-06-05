//
//  LeaderboardEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 11/09/2024.
//

import Foundation
enum LeaderboardEndPoint {
    case leaderboardEndpoint
}

extension LeaderboardEndPoint: Endpoint {
    var path: String {
        return ""
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    var header: [String : String]? {
        return ["Content-Type" : "application/json", "Authorization": "Bearer \(UserDefaults.standard.authToken)"]
    }
    
    var body: [String : Any]? {
        return nil
    }
    
    var baseURLType: BaseURLTypes {
        return .leaderboardURL
    }
    
}

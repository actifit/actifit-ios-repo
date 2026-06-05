//
//  GetPostReward.swift
//  Actifit
//
//  Created by Ali Jaber on 02/10/2024.
//

import Foundation
enum GetPostRewardEndPoint {
    case getPostRewardEndPoint(user: String, reportURL: String)
}
extension GetPostRewardEndPoint: Endpoint {
    var path: String {
        switch self {
        case .getPostRewardEndPoint(let user, let reportURL):
            return "getPostReward?user=\(user)&url=\(reportURL)"
        }
//https://api.actifit.io/getPostReward?user=twishi&url=/hive-193552/@cryptojiang/actifit-cryptojiang-20240930t202833672z
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var header: [String : String]? {
         ["Content-Type" : "application/json"]
    }
    
    var body: [String : Any]? {
        nil
    }
    
    var baseURLType: BaseURLTypes {
        return .appURL
    }
    

}

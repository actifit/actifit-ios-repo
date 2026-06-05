//
//  AfitBalanceEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 12/06/2024.
//

import Foundation
enum AfitBalanceEndPoint: Endpoint {
  case afitBalance(username: String)
}

extension AfitBalanceEndPoint {
  var path: String {
    switch self {
    case .afitBalance(let username):
      "user/\(username)?fullbalance=1"
    }
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

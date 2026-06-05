//
//  AccountData.swift
//  Actifit
//
//  Created by Ali Jaber on 12/06/2024.
//

import Foundation
enum AccountDataEndPoint: Endpoint {
  case accountData(username: String)
}

extension AccountDataEndPoint {
  var path: String {
    switch self {
    case .accountData(let username):
      "getAccountData?user=\(username)"
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

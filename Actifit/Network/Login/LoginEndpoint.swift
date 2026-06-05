//
//  LoginEndpoint.swift
//  Actifit
//
//  Created by Ali Jaber on 10/06/2024.
//

import Foundation
enum LoginEndpoint {
  case login(username: String, ppKey: String)
}

extension LoginEndpoint: Endpoint {
  var path: String {
    return "loginAuth"
  }
  var method: HTTPMethod {
    return .post
  }
  var header: [String : String]? {
    return ["Content-Type" : "application/json"]
  }

  var body: [String : Any]? {
    switch self {
    case .login(let username, let ppKey):
      return ["username": username, "ppkey": ppKey, "bchain": "HIVE", "loginsource": "ios", "keeploggedin": "true"]
    }
  }
  var baseURLType: BaseURLTypes {
    return .appURL
  }
}

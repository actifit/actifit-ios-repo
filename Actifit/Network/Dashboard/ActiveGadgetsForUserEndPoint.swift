//
//  ActiveGadgetsForUser.swift
//  Actifit
//
//  Created by Ali Jaber on 12/06/2024.
//

import Foundation
enum ActiveGadgetsForUserEndPoint: Endpoint {
  case activeGadgets(username: String)
}

extension ActiveGadgetsForUserEndPoint {
  var path: String {
    switch self {
    case .activeGadgets(let username):
      "activeGadgetsByUserApp/\(username)"
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

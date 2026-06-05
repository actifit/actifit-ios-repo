//
//  RCPPercentageEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 11/06/2024.
//

import Foundation
enum RCPPercentageEndPoint: Endpoint {
case rcpPercentage
}

extension RCPPercentageEndPoint {
  var path: String {
    switch self {
    case .rcpPercentage:
      "votingStatus"
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

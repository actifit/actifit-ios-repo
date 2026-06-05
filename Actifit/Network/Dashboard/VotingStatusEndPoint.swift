//
//  VotingStatusEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 11/06/2024.
//

import Foundation
enum VotingStatusEndPoint: Endpoint {
  case votingStatus
}

extension VotingStatusEndPoint {
  var path: String {
      "votingStatus"
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

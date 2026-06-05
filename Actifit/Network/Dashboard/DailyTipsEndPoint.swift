//
//  DailyTipsEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 12/06/2024.
//

import Foundation
enum DailyTipsEndPoint: Endpoint {
  case dailyTips
}

extension DailyTipsEndPoint {
  var path: String {
    return "dailyTip"
  }

  var method: HTTPMethod {
    return .get
  }

  var header: [String : String]? {
    return ["Content-Type" : "application/json"]
  }

  var body: [String : Any]? {
    return nil
  }
  var baseURLType: BaseURLTypes {
    return .appURL
  }
}

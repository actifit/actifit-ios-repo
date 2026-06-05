//
//  NotificationCountEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 14/06/2024.
//

import Foundation
enum NotificationCountEndPoint: Endpoint {
  case notificationCount
}

extension NotificationCountEndPoint {
  var path: String {
    switch self {
    case .notificationCount:
      "stats"
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
    return .chatURL
  }
}

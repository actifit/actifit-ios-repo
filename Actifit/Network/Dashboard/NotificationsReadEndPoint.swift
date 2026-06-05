//
//  NotificationsReadEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 12/06/2024.
//

import Foundation
enum NotificationsReadEndPoint: Endpoint {
  case notificationsRead(username: String)
}

extension NotificationsReadEndPoint {
  var path: String {
    switch self {
    case .notificationsRead(let username):
      "readNotifications/\(username)"
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

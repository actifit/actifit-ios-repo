//
//  NotificationsEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 09/08/2024.
//

import Foundation

enum NotificationsEndPoint {
  case getNotifications(username: String)
}

extension NotificationsEndPoint: Endpoint {
  var path: String {
    switch self {
    case .getNotifications(let username):
      return "allNotifications/\(username)"
    }

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

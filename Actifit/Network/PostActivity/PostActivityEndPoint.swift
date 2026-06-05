//
//  PostReportEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 27/08/2024.
//

import Foundation
enum PostActivityEndPoint {
  case postReport(body: [String: Any])
}

extension PostActivityEndPoint: Endpoint {
  var path: String {
    return ""
  }
  
  var method: HTTPMethod {
    return .post
  }
  
  var header: [String : String]? {
    return ["Content-Type" : "application/json", "Authorization": "Bearer \(UserDefaults.standard.authToken)"]
  }
  
  var body: [String : Any]? {
    switch self {
    case .postReport(let body):
      return body
    }
  }
  
  var baseURLType: BaseURLTypes {
    return .postActivityURL
  }
  

}

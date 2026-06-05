//
//  BannersEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 11/06/2024.
//

import Foundation
enum BannersEndPoint: Endpoint {
  case banner
}

extension BannersEndPoint {
  var path: String {
    return "news"
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

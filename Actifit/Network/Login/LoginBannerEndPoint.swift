//
//  LoginBannerEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 11/06/2024.
//

import Foundation
enum LoginBannerEndPoint {
case loginBanner
}

extension LoginBannerEndPoint: Endpoint {
  var path: String {
    return "loginImg"
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

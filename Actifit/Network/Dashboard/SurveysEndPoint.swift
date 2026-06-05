//
//  SurveysEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 11/06/2024.
//

import Foundation
enum SurveysEndPoint: Endpoint {
  case surver
}

extension SurveysEndPoint {
  var header: [String : String]? {
     ["Content-Type" : "application/json"]
  }
  var method: HTTPMethod {
     .get
  }

  var body: [String : Any]? {
     nil
  }
  var path: String {
    "surveys"
  }
  var baseURLType: BaseURLTypes {
    return .appURL
  }

}

//
//  SurveyStatusEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 12/06/2024.
//

import Foundation
enum SurveyStatusEndPoint: Endpoint {
  case surveyStatus(username: String, surveyId: String)
}

extension SurveyStatusEndPoint {
  var path: String {
    switch self {
    case .surveyStatus(let username, let surveyId):
      "userVotedSurvey?user=\(username)&id=\(surveyId)"
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

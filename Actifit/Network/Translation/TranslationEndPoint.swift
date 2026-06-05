//
//  TranslationEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 02/08/2024.
//

import Foundation
enum TranslationEndPoint: Endpoint {
  case translate(content: String)
}

extension TranslationEndPoint {
  var path: String {
    return "v2/translate"
  }

  var method: HTTPMethod {
    return .post
  }

  var header: [String : String]? {
    return ["Content-Type" : "application/json", "Authorization" : "DeepL-Auth-Key \(Secrets.deepLAuthKey)"]
  }

  var body: [String : Any]? {
    switch self {
    case .translate(let content):
      return ["text": [content], "target_lang": "EN"]
    }
  }
  
  var baseURLType: BaseURLTypes {
    return .translateURL
  }
}

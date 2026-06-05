//
//  CreateWaveEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 14/08/2024.
//

import Foundation
enum CreateWaveEndPoint {
  case createWave(username: String, comment: String,params: [String: Any])
}

extension CreateWaveEndPoint: Endpoint {
  var path: String {
      switch self {
      case .createWave(let username, let comment, let params):
          let array: [Any] = [comment, params]
          let basePath = "performTrx/"
          var url = "\(basePath)?user=\(username)"
          do {
              let jsonData = try JSONSerialization.data(withJSONObject: array, options: [])
              if let jsonString = String(data: jsonData, encoding: .utf8)?
                  .replacingOccurrences(of: "\n", with: "") {
                  url += "&operation=[\(jsonString)]&bchain=HIVE"
                  if let encodedString = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                      return encodedString
                  }
              }
          } catch {
              print("Error serializing JSON: \(error.localizedDescription)")
          }
      }
      return ""
  }


  var method: HTTPMethod {
    return .get
  }

  var header: [String : String]? {
    return ["Content-Type" : "application/json", "Authorization": "Bearer \(UserDefaults.standard.authToken)"]
  }

  var body: [String : Any]? {
    return nil
  }

  var baseURLType: BaseURLTypes {
    return .appURL
  }


}

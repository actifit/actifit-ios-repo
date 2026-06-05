//
//  EndPoints.swift
//  Actifit
//
//  Created by Ali Jaber on 10/06/2024.
//

import Foundation
enum BaseURLTypes {
  case appURL
  case chatURL
  case translateURL
  case herpcURL
  case hiveBlog
  case postActivityURL
  case leaderboardURL//TODO: merge this with post activity url
}
protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var header: [String: String]? { get }
    var body: [String: Any]? { get }
    var baseURLType: BaseURLTypes { get }
}

extension Endpoint {
    var baseURL: String {
      switch baseURLType {
      case .appURL: return getRandomURL()
      case .chatURL: return "https://chat-api.peakd.com/api/"
      case .translateURL: return "https://api.deepl.com/"
      case .herpcURL : return "https://herpc.actifit.io/"
      case .hiveBlog: return "https://api.hive.blog"
      case .postActivityURL: return "https://actifit-pst-cr3at0r.herokuapp.com/p0stact1f1t_Js0n"
      case .leaderboardURL: return "https://actifit-pst-cr3at0r.herokuapp.com/api/topP0stsV2"

      }
    }

  func getRandomURL() -> String {
    let baseURLS = ["https://api.actifit.io/","https://api2.actifit.io/", "https://actifitbot.herokuapp.com/"]
    return baseURLS.randomElement()!
  }
}
//https://api.hive.blog/

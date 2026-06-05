//
//  GetWavesEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 15/08/2024.
//

import Foundation
enum GetWavesEndPoint {
  case getWaves
    case getPosts(username: String, startAuthor: String? = nil, startPermlink: String? = nil)
  case getSocialPosts(author: String? = nil, permlink: String? = nil)
}

extension GetWavesEndPoint: Endpoint {
  var path: String {
    return ""
  }

  var method: HTTPMethod {
    .post
  }

  var header: [String : String]? {
    return ["Content-Type" : "application/json"]
  }

  var body: [String : Any]? {
    switch self {
    case .getWaves:
      let body: [String: Any] = [
        "sort": "posts",
        "account":"ecency.waves",
        "start_author":"",
        "start_permlink": "",
        "limit": 10,
        "observer": "",
      ]
      let params: [String:Any] = ["id":1,"jsonrpc":"2.0","method": "bridge.get_account_posts", "params": body]
      return params
    case .getPosts(let username, let startAuthor, let startPermlink):
      let body: [String: Any] = ["id" :"1", "jsonrpc" : "2.0", "method": "bridge.get_account_posts", "params":
                                  [
                                    "sort": "posts",
                                    "account": username,
                                    "start_author": startAuthor ?? "",
                                    "start_permlink": startPermlink ?? "",
                                    "limit": 20,
                                    "observer": ""
                                  ]
      ]
      return body

    case .getSocialPosts(let author, let permlink):
        let body: [String: Any] = [
          "sort": "created",
          "start_author":author ?? "",
          "start_permlink": permlink ?? "",
          "tag": "hive-193552",
        ]
        let params: [String:Any] = ["id":1,"jsonrpc":"2.0","method": "bridge.get_ranked_posts", "params": body]
        return params
    }
  }

  var baseURLType: BaseURLTypes {
    return .hiveBlog
  }
}

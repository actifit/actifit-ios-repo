//
//  GetSnapEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 22/11/2024.
//

import Foundation
enum GetSnapsEndPoint {
  case getSnaps
  case getLeoThreads   // InLeo short-form threads (account: leothreads) — Android parity
}

extension GetSnapsEndPoint: Endpoint {
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
    case .getSnaps:
      let body: [String: Any] = [
        "sort": "posts",
        "account":"peak.snaps",
        "start_author":"",
        "start_permlink": "",
        "limit": 10,
        "observer": "",
      ]
      let params: [String:Any] = ["id":1,"jsonrpc":"2.0","method": "bridge.get_account_posts", "params": body]
      return params

    case .getLeoThreads:
      let body: [String: Any] = [
        "sort": "posts",
        "account":"leothreads",
        "start_author":"",
        "start_permlink": "",
        "limit": 10,
        "observer": "",
      ]
      let params: [String:Any] = ["id":1,"jsonrpc":"2.0","method": "bridge.get_account_posts", "params": body]
      return params
    }
  }

  var baseURLType: BaseURLTypes {
    return .hiveBlog
  }
}

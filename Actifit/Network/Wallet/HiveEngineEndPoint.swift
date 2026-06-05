//
//  HiveEngineEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 09/08/2024.
//

import Foundation
enum TableType: String {
  case tokens
  case balances
}
enum HiveEngineEndPoint {
  case hiveEngine(username: String, tableType: TableType)
}

extension HiveEngineEndPoint: Endpoint {
  var path: String {
    return "contracts"
  }
  
  var method: HTTPMethod {
    return .post
  }
  
  var header: [String : String]? {
    return ["Content-Type" : "application/json"]
  }
  
  var body: [String : Any]? {
    var innerParms: [String: Any] = [:]
    switch self {
    case .hiveEngine(let username, let tableType):
      switch tableType {
      case .tokens:
        innerParms = ["contract": "tokens", "table": tableType.rawValue, "query": [:]]
      case .balances:
        innerParms =  ["contract": "tokens", "table": tableType.rawValue,
                      "query": ["account": username], "limit": 1000,"offset": 0]
      }
    }
    return ["id":1,"jsonrpc":"2.0","method": "find", "params": innerParms]
  }
  
  var baseURLType: BaseURLTypes {
    return .herpcURL
  }
  

}

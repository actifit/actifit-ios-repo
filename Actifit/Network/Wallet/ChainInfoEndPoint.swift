//
//  ChainInfoEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 09/08/2024.
//

import Foundation

enum ChainInfoEndPoint {
  case getChainInfo
}

extension ChainInfoEndPoint: Endpoint {
  var path: String {
    "getChainInfo"
  }
  
  var method: HTTPMethod {
    .get
  }
  
  var header: [String : String]? {
    return ["Content-Type" : "application/json"]
  }
  
  var body: [String : Any]? {
    return nil
  }
  
  var baseURLType: BaseURLTypes {
    .appURL
  }
  

}

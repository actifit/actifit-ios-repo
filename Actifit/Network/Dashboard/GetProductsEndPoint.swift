//
//  GetProductsEndPoint.swift
//  Actifit
//
//  Created by Ali Jaber on 12/06/2024.
//

import Foundation
//products
enum GetProductsEndPoint: Endpoint {
  case products
}

extension GetProductsEndPoint {
  var path: String {
    return "products"
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

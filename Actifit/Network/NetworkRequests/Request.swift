//
//  Request.swift
//  Actifit
//
//  Created by Ali Jaber on 10/06/2024.
//

import Foundation
protocol Request {
    var method: HTTPMethod { get }
}

extension Request {
    var getMethod: HTTPMethod {
        .get
    }
  var postMethod: HTTPMethod {
      .get
  }
}

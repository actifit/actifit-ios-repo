//
//  FitbitAPIFitbitAPI.swift
//  Actifit
//
//  Created by Srini on 02/02/19.
//

import UIKit

class FitbitAPI {
    
    static let sharedInstance: FitbitAPI = FitbitAPI()
    
    static let baseAPIURL = URL(string:"https://api.fitbit.com/1")
    
    func authorize(with token: String) {
        let sessionConfiguration = URLSessionConfiguration.default
        var headers = sessionConfiguration.httpAdditionalHeaders ?? [:]
        headers["Authorization"] = "Bearer \(token)"
        sessionConfiguration.httpAdditionalHeaders = headers
        session = URLSession(configuration: sessionConfiguration)
    }
    
    var session: URLSession?
}

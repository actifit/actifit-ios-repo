//
//  RequestErrors.swift
//  Actifit
//
//  Created by Ali Jaber on 10/06/2024.
//

import Foundation
enum RequestError: Error {
case unknown
case invalidURL
case noResponse
case decode
case unathorized
case notFound
case defaultCase
    var customMessage: String {
        //Add any message you want, this will be displayed to the user as an error message
        switch self {
        case .noResponse: return "No response"
        case .invalidURL: return "Invalid URL"
        case .decode: return "Error decoding data"
        case .unathorized: return "Unauthorized"
        case .notFound: return "Not Found"
        case .defaultCase: return "Default Case"
        default: return "Unknown error"
        }
    }
}

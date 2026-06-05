//
//  BaseNetworkService.swift
//  Actifit
//
//  Created by Ali Jaber on 10/06/2024.
//

import Foundation
class HTTPClient {
  func sendRequest<T: Decodable>(endpoint: Endpoint, responseModel: T.Type) async -> Result<T, RequestError> {
      guard let url = URL(string: endpoint.baseURL + endpoint.path) else {
          return .failure(.invalidURL)
      }
      var request = URLRequest(url: url)
      request.httpMethod = endpoint.method.rawValue
      request.allHTTPHeaderFields = endpoint.header
      if let body = endpoint.body {
          request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        // self.httpBody = try JSONSerialization.data(withJSONObject: json, options:[])
      }
      do {
          // TODO: Simplify the code of checking the iOS version
        
              let (data, response) = try await URLSession.shared.data(for: request, delegate: nil)

              guard let response = response as? HTTPURLResponse else {
                  return .failure(.noResponse)
              }
              switch response.statusCode {
              case 200...204:
                  do {
                      if let jsonString = String(data: data, encoding: .utf8) {
                          print(endpoint.path)
                          print("Raw JSON response: \(jsonString)")
                      } else {
                          print("Unable to convert data to string")
                      }
                    let decoder = JSONDecoder()
                       decoder.keyDecodingStrategy = .convertFromSnakeCase
                       let decodedResponse = try decoder.decode(T.self, from: data)
                      return .success(decodedResponse)
                  } catch _ {
                      return .failure(.decode)
                  }
              case 401:
                  return .failure(.unathorized)
              case 404:
                  return .failure(.notFound)
              default:
                  return .failure(.unknown)
              }



      } catch {
          return .failure(.unknown)
      }
  }
}

extension URLSession {
    func data(from url: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: url) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}

//
//} catch let error as DecodingError {
//    switch error {
//        case .typeMismatch(let type, let context):
//            print("Type mismatch for key: \(context.codingPath.last?.stringValue ?? "Unknown")")
//            print("Expected type: \(type), but found: \(context.debugDescription)")
//        case .valueNotFound(let type, let context):
//            print("Value not found for key: \(context.codingPath.last?.stringValue ?? "Unknown")")
//            print("Expected value of type: \(type), but found nil")
//        case .keyNotFound(let key, let context):
//            print("Key not found: \(key.stringValue) in context: \(context.debugDescription)")
//        case .dataCorrupted(let context):
//            print("Data corrupted at key: \(context.codingPath.last?.stringValue ?? "Unknown")")
//            print("Debug description: \(context.debugDescription)")
//        @unknown default:
//            print("Unknown decoding error")
//        }
//        return .failure(.decode)
//}

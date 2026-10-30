//
//  AuthenticationManager.swift
//  Actifit
//
//  Created by Ali Jaber on 24/06/2024.
//

import Foundation


class TokenManager {
    static let shared = TokenManager()

    private init() {}

  private let lock = NSLock()
  private var lastAttempt = Date.distantPast
  private static let issuedAtKey = "authTokenIssuedAt"

  /// Refreshes when the session is older than `maxAge` (the backend's token lasts 24 hours,
  /// and a login on another device ends it sooner).
  func refreshIfStale(maxAge: TimeInterval = 6 * 60 * 60) {
    let issued = UserDefaults.standard.object(forKey: TokenManager.issuedAtKey) as? Date ?? .distantPast
    if Date().timeIntervalSince(issued) > maxAge { refreshToken() }
  }

  /// The backend answers HTTP 200 {success:false} (no error) when the session is missing or
  /// expired. Seeing that, log in again, at most once every five minutes so a route that answers
  /// success:false for its own reasons can't hammer the rate-limited login.
  func noteReply(_ data: Data) {
    guard data.count < 300,
          let doc = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
          User.current() != nil else { return }
    // checkHdrs' replies: {success:false, message:"Token is not valid" | "Auth token is not
    // provided"}, or {error:"Authentication failed. Key not found"} once the session was purged
    // (a login elsewhere, or a key-rotation purge).
    let message = (doc["message"] as? String ?? "").lowercased()
    let error = (doc["error"] as? String ?? "").lowercased()
    let expired = (doc["success"] as? Bool == false && (message.contains("token is not valid") || message.contains("auth token is not provided")))
      || error.contains("authentication failed. key not found")
    guard expired else { return }
    lock.lock()
    let due = Date().timeIntervalSince(lastAttempt) > 5 * 60
    if due { lastAttempt = Date() }
    lock.unlock()
    if due { refreshToken() }
  }

  func refreshToken() {
     let username = UserDefaults.standard.username
      let ppKey = UserDefaults.standard.privatePostingKey
      Task {
        var networkManager =  HTTPClient()
        let loginEndPoint = await networkManager.loginAPI(username: username, ppKey: ppKey)
        switch loginEndPoint {
        case .success(let user):
          User.saveWith(info: [
            UserKeys.steemit_username : username,
            UserKeys.private_posting_key :  ppKey,
            UserKeys.last_post_date : Date().yesterday
          ])
          UserDefaults.standard.username = user.userdata.name
          UserDefaults.standard.privatePostingKey = ppKey
          UserDefaults.standard.authToken = user.token
          UserDefaults.standard.set(Date(), forKey: TokenManager.issuedAtKey)
        case .failure(let failure):
          print("Failed to refresh token: \(failure)")
        }
      }
    }
  }



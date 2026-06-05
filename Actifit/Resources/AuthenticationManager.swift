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
        case .failure(let failure):
          print("Failed to refresh token: \(failure)")
        }
      }
    }
  }



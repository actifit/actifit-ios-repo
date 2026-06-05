//
//  LoginViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 03/07/2023.
//

import Foundation
import Combine
import UIKit

class LoginViewModel {
  var networkManager =  HTTPClient()
    var labelRedColor: UIColor {
        return .primaryRedColor()
    }
    @Published var username: String = ""
    @Published var privatePostingKey = ""
    
    @Published var loginEnabled: Bool = false
    private let loaderVisibilitySubject = PassthroughSubject<Bool, Never>()
    private let imageLoaderVisibilitySubject = PassthroughSubject<Bool, Never>()
    var imageLoaderVisibiltyPublisher: AnyPublisher<Bool, Never> {
        return imageLoaderVisibilitySubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    var loaderVisibilityPublisher: AnyPublisher<Bool, Never> {
        return loaderVisibilitySubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    private let isUserAutorizedSubject = PassthroughSubject<Bool, Never>()
    var isUserBiometricAuthorizedPublisher: AnyPublisher<Bool, Never> {
        return isUserAutorizedSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    
    private let imageSubject = PassthroughSubject<UIImage?, Never>()
    private let proccessSuccessSubject = PassthroughSubject<Bool,Never>()
    
    var successProcessPublisher: AnyPublisher<Bool, Never> {
        return proccessSuccessSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    
    private var cancellables = Set<AnyCancellable>()
    private var cancellable: AnyCancellable?
    init() {
        getBannerImage()
    }

     func loadImage(url: URL)  {
         cancellable = URLSession.shared.dataTaskPublisher(for: url)
            .map {data, _ -> UIImage? in
                UIImage(data: data)
            }.receive(on: DispatchQueue.main)
             .replaceError(with: nil)
             .sink{[weak self ] image in
                 self?.imageSubject.send(image)
                 self?.imageLoaderVisibilitySubject.send(false)
             }
    }
    
    func imagePublisher() -> AnyPublisher<UIImage?, Never> {
        return imageSubject.eraseToAnyPublisher()
    }
    
    func authorizeUser() {
        let biometricIDAuth = BiometricIDAuth()
        biometricIDAuth.canEvaluate { canEvaluate, _ , canEvaluateError in
            if canEvaluate {
                biometricIDAuth.evaluate {[weak self] success, error in
                    guard success else {
                        self?.isUserAutorizedSubject.send(false)
                        return
                    }
                    self?.isUserAutorizedSubject.send(true)
                    }
                }
            
        }
    }
    
  //ali.jaber
  //password: kbxqnym6xrsxctwoz27g0ol6q09aqkvn5ty3brqtlc
//ppkey: 5HyM8Coizc88mXBSsA13km8NiQj96BtK8HyR69X2YkRbDf4drhB
   
        //5JsDjHm59mojuhKEDk3ffDm9NBemmL98SQBzzELbpELs1EnCSy5
    //hive.guy
    
//user: vevita
//
//key: 5JeAQvwUdeuvZvSbvHW24r5jQrQ1kLXHcyn3Echqg6b2LkJHhhe

  private func getBannerImage() {
      imageLoaderVisibilitySubject.send(true)
    Task {
      let banner = await networkManager.getLoginBannerImage()
      imageLoaderVisibilitySubject.send(false)
      switch banner {
      case .success(let banner):
        self.loadImage(url: URL(string: banner.imgUrl ?? "")!)
      case .failure(let failure):
        print("Error decoding JSON: \(failure.localizedDescription)")
      }
    }
  }


    func proceedTapped(username: String, privatePostingKey: String) {
        loaderVisibilitySubject.send(true)
        do {
            try Keychain.setObject(UserModel(username: username, privatePostingKey: privatePostingKey), service: KeychainKeys.user.rawValue)
        } catch let error {
            print(error.localizedDescription)
        }
      Task {
        let loginEndPoint = await networkManager.loginAPI(username: username, ppKey: privatePostingKey)
          self.loaderVisibilitySubject.send(false)
        switch loginEndPoint {
        case .success(let user):
         User.saveWith(info: [UserKeys.steemit_username : username, UserKeys.private_posting_key : privatePostingKey, UserKeys.last_post_date : Date().yesterday])
          UserDefaults.standard.username = user.userdata.name
          UserDefaults.standard.privatePostingKey = privatePostingKey
          UserDefaults.standard.authToken = user.token
        self.proccessSuccessSubject.send(true)
        case .failure(_):
            self.proccessSuccessSubject.send(false)
        }
      }
    }
}


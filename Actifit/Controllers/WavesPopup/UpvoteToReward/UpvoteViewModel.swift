//
//  UpvoteViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 03/05/2024.
//

import Foundation
import Combine
class UpvoteViewModel {
  var cancellables = Set<AnyCancellable>()
  private let loaderSubject = PassthroughSubject<Bool, Never>()
  var loaderPublisher: AnyPublisher<Bool, Never> {
    return loaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  /// A failed broadcast's reason (signed on the device: wrong key, no RC, network...).
  private let errorSubject = PassthroughSubject<String, Never>()
  var errorPublisher: AnyPublisher<String, Never> {
    return errorSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  private let dismissSubject = PassthroughSubject<Bool, Never>()
  var dismissPublisher: AnyPublisher<Bool, Never> {
    return dismissSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  init() {

  }

  func upvoteAPI(comment: PostComments, vote: Int) {
    guard let username = User.current()?.steemit_username else { return }
    loaderSubject.send(true)
    let opName = "vote"
    var customParams: [String:Any] =
    [
      "author": comment.author,
      "permlink": comment.permlink,
      "voter": username,
      "weight": Int(vote * 100)
    ]
    var metadata: [String: Any] = [:]

    let tagsBody = ["hive-193552", "actifit"]

    metadata["tags"] = tagsBody
    metadata["app"] = "actifit"

    do {
      let metaDataJsonString  = try? JSONSerialization.data(withJSONObject: metadata, options: [])
      if let jsonString = String(data: metaDataJsonString!, encoding: .utf8) {
        customParams["json_metadata"] = jsonString
        API().createWave(body: customParams, username: User.current()?.steemit_username ?? "", comment: opName) { info, statusCode in
          print(info)
          print(statusCode)
          self.loaderSubject.send(false)
          self.dismissSubject.send(true)
        } failure: { error in
          self.loaderSubject.send(false)
          self.errorSubject.send(error.localizedDescription)
        }
      }
    }
    catch {
      print(error.localizedDescription)
    }
  }
}

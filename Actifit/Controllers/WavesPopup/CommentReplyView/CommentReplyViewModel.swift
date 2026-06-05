//
//  CommentReplyViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 21/04/2024.
//

import Foundation
import UIKit
import Combine
class CommentReplyViewModel {
  var cancellables = Set<AnyCancellable>()
  private let loaderSubject = PassthroughSubject<Bool, Never>()
  var loaderPublisher: AnyPublisher<Bool, Never> {
    return loaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  private let dismissSubject = PassthroughSubject<Bool, Never>()
  var dismissPublisher: AnyPublisher<Bool, Never> {
    return dismissSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  private var uploadedImageURLSubject = PassthroughSubject<String, Never>()
  var uploadedImageURLPublisher: AnyPublisher<String, Never> {
    return uploadedImageURLSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  
  init() {
    
  }

  func addCommentReply(reply: String, stepCount: String, appVersion: String,comment: PostComments) {
    loaderSubject.send(true)
    let opName = "comment"
    let commentPerm = "\((User.current()?.steemit_username.replacingOccurrences(of: ".", with: "-")) ?? "") -re-\(comment.author)-\(comment.permlink)\(Date().converToServerDate())".lowercased().replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "[^a-zA-Z0-9-]+", with: "", options: .regularExpression)
    var customParams: [String:Any] =
    [
      "author": User.current()?.steemit_username ?? "",
     "permlink": commentPerm,
     "title": "",
     "body" : reply,
      "parent_author": comment.author,
      "parent_permlink" : comment.permlink

    ]
    var metadata: [String: Any] = [:]

    let tagsBody = ["hive-193552", "actifit"]

    metadata["tags"] = tagsBody
    metadata["app"] = "actifit"
    metadata["step_count"] = stepCount
    metadata["appVersion"] = appVersion
    do {
      let metaDataJsonString  = try? JSONSerialization.data(withJSONObject: metadata, options: [])
      if let jsonString = String(data: metaDataJsonString!, encoding: .utf8) {
        customParams["json_metadata"] = jsonString
        API().createWave(body: customParams, username: User.current()?.steemit_username ?? "", comment: opName) { info, statusCode in
          self.loaderSubject.send(false)
          self.dismissSubject.send(true)
        } failure: { error in
          print(error.localizedDescription)
        }
      }
    }
    catch {
      print(error.localizedDescription)
    }
  }


    func uploadData(image: UIImage) async {
        DispatchQueue.main.async {
            self.loaderSubject.send(true)
        }

        do {
            let imageURL = try await ImageUploadManager().uploadImage(image)
            DispatchQueue.main.async {
                self.loaderSubject.send(false)
                self.uploadedImageURLSubject.send(imageURL)
            }
        } catch {
            print(error.localizedDescription)
            DispatchQueue.main.async {
                self.loaderSubject.send(false)
            }
        }
    }
}

//
//  ThreeSpeakViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 07/05/2024.
//

import Foundation
import UIKit
import Combine
class ThreeSpeakViewModel {
  var cancellables = Set<AnyCancellable>()
  private let loaderSubject = PassthroughSubject<Bool, Never>()
  private let videoProgressSubjectToUpdateUI = PassthroughSubject<Double, Never>()
  var videoProgressPublisher: AnyPublisher<Double, Never> {
    return videoProgressSubjectToUpdateUI.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  private let imageProgressSubjectToUpdateUI = PassthroughSubject<Double, Never>()
  var imageSubjectPublisher: AnyPublisher<Double, Never> {
    return imageProgressSubjectToUpdateUI.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  var loaderPublisher: AnyPublisher<Bool, Never> {
    return loaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  var videos: [Video] = []
  private let refreshSubject = PassthroughSubject<Bool, Never>()
  private let showDeleteAlertSubject = PassthroughSubject<Bool, Never>()
  var showDeleteAlertPublisher: AnyPublisher<Bool, Never> {
    return showDeleteAlertSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let deleteAlertSubject = PassthroughSubject<Bool, Never>()
  var refreshPublisher: AnyPublisher<Bool, Never> {
    return refreshSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let showSuccessSubmitSubject = PassthroughSubject<Bool, Never>()
  var showSuccessSubmitPublisher: AnyPublisher<Bool, Never> {
    return showSuccessSubmitSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  var refetchCounter = 0
  var uploadedVideoURL: URL? = nil
  var uploadedImageURL: URL? = nil
  var threeSpeakerVideoManager : ThreeSpeakVideoUploadManager!
  var loginToken: ThreeSpeakLoginModel?
  var finalParamsForVideoSubmit: [String:Any] = [:]
  var isImageReadyToUpload = false
  var isVideoReadyToUpload = false
  var originalVideoName: URL? = nil
  var initialURL: URL? = nil
  init() {
    setBindingBetweenViewModelAndManager()
  //  if UserDefaults.standard.setXcstkn == "" || UserDefaults.standard.setXcstkn == nil {
      loginThreeSpeakVideo()
//    } else {
//      fetchUserVideos()
//    }
  }

  deinit {
   // threeSpeakerVideoManager = nil
  }

  func stopAllUploadOperations() {
    //threeSpeakerVideoManager.tusClient?.stopAndCancelAll()
    threeSpeakerVideoManager.tusClient = nil
  }

  func setBindingBetweenViewModelAndManager() {
    threeSpeakerVideoManager = ThreeSpeakVideoUploadManager()
    threeSpeakerVideoManager.videoProgressSubject.sink { percentage in
      self.videoProgressSubjectToUpdateUI.send(percentage)
    }.store(in: &cancellables)
    threeSpeakerVideoManager.imageProgressSubject.sink { percentage in
      self.imageProgressSubjectToUpdateUI.send(percentage)
    }.store(in: &cancellables)

    threeSpeakerVideoManager.uploadedVideoURLSubject.sink { uploadedURL in

      self.uploadedVideoURL = uploadedURL
//      if let initialURL = self.initialURL {
//        self.uploadThumbnailAndGetURL(url: initialURL)
//      }
      //TODO: start uploading the image
      if let imgURL = self.uploadedVideoURL, let vidURl = uploadedURL, let initialURL = self.initialURL {
              self.generateAPIBody(initialVideoURL: initialURL, uploadeVideoURL: vidURl, uploadeImageURL: imgURL)
              self.isImageReadyToUpload = true
              self.isVideoReadyToUpload = true
            }
    }.store(in: &cancellables)
    threeSpeakerVideoManager.uploadedImageURLSubject.sink { uploadedImg in
      self.uploadedImageURL = uploadedImg
      if let initialURL = self.initialURL {
        self.isImageReadyToUpload = true
        self.uploadVideoAndGetURL(url: initialURL)
      }

    }.store(in: &cancellables)
  }

  func loginThreeSpeakVideo() {
    guard let username = User.current()?.steemit_username else { 
      return
    }
    API().loginThroughVideo3Speak(username: username) { info, statusCode in
      if let response = info as? String {
        let data = response.utf8Data()
        let decoder = JSONDecoder()
        do {
          self.loginToken = try decoder.decode(ThreeSpeakLoginModel.self, from: data)
          self.verify3SpeakMemo(username: username)
        } catch {
          print("Error decoding JSON: \(error.localizedDescription)")
        }
      }
    } failure: { error in
      print(error.localizedDescription)
    }

  }

  func verify3SpeakMemo(username: String) {
    guard let memo = loginToken?.memo else {
      let xcstkn = UserDefaults.standard.setXcstkn
      self.fetch3SpeakCookies(username: username, token: xcstkn ?? "")
      return
    }
    API().verifyActifit3SpeakVideoMemo(username: username, body: ["memo": memo]) { info, statusCode in
      if let response = info as? String {
        let data = response.utf8Data()
        let decoder = JSONDecoder()
        do {
          let xcstknObject = try decoder.decode(ActifitMemoVerificationModel.self, from: data)
          let xcstkn = xcstknObject.xcstkn?.replacingOccurrences(of: "#", with: "")
          UserDefaults.standard.setXcstkn = xcstkn
          self.fetch3SpeakCookies(username: username, token: xcstkn ?? "")
        } catch {
          print("Error decoding JSON: \(error.localizedDescription)")
        }
      }
    } failure: { error in
      print(error.localizedDescription)
    }
  }

  func fetch3SpeakCookies(username: String, token: String) {
    API().grab3SpeakCookie(username: username, token: token) { info, statusCode in//
      if let response = info as? String {
        self.fetchUserVideos()
//        do {
//
//        } catch {
//          print("Error decoding JSON: \(error.localizedDescription)")
//        }
      }
    } failure: { error in
      print(error.localizedDescription)
    }
  }

  func fetchUserVideos() {
    API().fetchUserVideosFrom3Speak { info, statusCode in
      if let response = info as? String {
        if statusCode == 400 || statusCode == 401 {
          UserDefaults.standard.setXcstkn = nil
          self.loginThreeSpeakVideo()
        }
        let data = response.utf8Data()
        let decoder = JSONDecoder()
        do {

          self.videos = try decoder.decode([Video].self, from: data)
          self.refreshSubject.send(true)
        } catch {

          print("Error decoding JSON: \(error.localizedDescription)")
          if self.refetchCounter <= 5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, execute: {
              self.fetchUserVideos()
              self.refetchCounter += 1
            })
          } else {
            self.loaderSubject.send(false)
            //TODO: show retry alert
          }

        }
      }
    } failure: { error in

      print("Error decoding JSON: \(error.localizedDescription)")
    }
  }

  func getVideoSize(url: URL) -> Double {
    return threeSpeakerVideoManager.getVidSize(for: url) ?? 0.0
  }

  func getVideoDuration(url: URL) -> Double {
    return threeSpeakerVideoManager.getVidDuration(for: url) ?? 0.0
  }

  func generateAPIBody(initialVideoURL: URL, uploadeVideoURL: URL, uploadeImageURL: URL) {
    guard let username = User.current()?.steemit_username else { return }
    do {
      let img = threeSpeakerVideoManager.generateThumbnail(from: initialURL!)
      let imageName = try threeSpeakerVideoManager.getBitmapFileUrl(from: img!)

      // threeSpeakerVideoManager.uploadedImageURLSubject.sink { uploadedImg in
      // guard let uploadedImgURL = uploadedImg else { return }
      let name = uploadeVideoURL.absoluteString.replacingOccurrences(of: "https://uploads.3speak.tv/files/", with: "")
      self.finalParamsForVideoSubmit =
      [
        "filename": name,
        "oFilename": self.originalVideoName?.absoluteString ?? "",
        "size": String(format: "%.2f", ((self.threeSpeakerVideoManager.getVidSize(for: initialVideoURL))!)),
        "duration": String(format: "%.2f",self.threeSpeakerVideoManager.getVidDuration(for: initialVideoURL) ?? 0),
        "thumbnail" : self.uploadedImageURL!.absoluteString.replacingOccurrences(of: "https://uploads.3speak.tv/files/", with: ""),
        "owner": username,
        "isReel": false,]
    } catch let error {
      print(error.localizedDescription)
    }

  }

   func uploadThumbnailAndGetURL(url: URL) {
     self.initialURL = url

    do {
      let img = threeSpeakerVideoManager.generateThumbnail(from: initialURL!)
      let imageName = try threeSpeakerVideoManager.getBitmapFileUrl(from: img!)
      threeSpeakerVideoManager.uploadVideoOrImage(videoURL: imageName, uploadType: .image)
    } catch {

    }

  }

  func uploadVideoAndGetURL(url: URL) {
    guard initialURL != nil else { return }
    if let range = url.absoluteString.range(of: "/", options: .backwards) {
      let fileNameWithExtension = String(url.absoluteString[range.upperBound...])
      if let dotRange = fileNameWithExtension.range(of: ".", options: .backwards) {
        let fileName = String(fileNameWithExtension[..<dotRange.lowerBound])
        let lastTenCharacters = String(fileName.suffix(10))
        let newFileNameWithExtension = "\(lastTenCharacters).MOV"
        self.originalVideoName = URL(string: newFileNameWithExtension)
      }
    }
    if uploadedVideoURL != nil {
      self.videoProgressSubjectToUpdateUI.send(100)
      self.isVideoReadyToUpload = true
    //  uploadThumbnailAndGetURL(url: url)
      self.isVideoReadyToUpload = true
    } else {
   //   self.isImageReadyToUpload = false
   //   self.isVideoReadyToUpload = false
      threeSpeakerVideoManager.uploadVideoOrImage(videoURL: url, uploadType: .video)

    }
  }

  var isReadyToSubmit: Bool {
    return isImageReadyToUpload && isVideoReadyToUpload
  }


  func submitVideoTo3Speak() {
    guard (User.current()?.steemit_username) != nil else { return }
    loaderSubject.send(true)
    API().submitVideo3Speak(params: finalParamsForVideoSubmit) { info, statusCode in
      self.loaderSubject.send(false)
      if statusCode == 200 {
        self.showSuccessSubmitSubject.send(true)
      } else {
        self.showSuccessSubmitSubject.send(false)
      }
      self.uploadedVideoURL = nil
    } failure: { error in
      self.loaderSubject.send(false)
      print(error.localizedDescription)
    }
  }

  func deleteVideo(video: Video) {
    loaderSubject.send(true)
    if let permlink = video.permlink {
      API().deleteVideo(videoPermlLink: permlink) { info, statusCode in
        self.loaderSubject.send(false)
        if statusCode == 200 {
          self.showDeleteAlertSubject.send(true)
        } else {
          self.showDeleteAlertSubject.send(false)
        }
      } failure: { error in
        print(error.localizedDescription)
      }
    }
  }

}

struct Utils {
  static let statusList: [[String]] = [
    ["uploaded", "0", "Uploaded..▲"],
    ["encoding_queued", "1", "Queued for Encoding..→"],
    ["encoding_ipfs", "2", "Processing Encoding..⏳"],
    ["encoding_failed", "3", "Encoding Failed..x"],
    ["deleted", "4", "Deleted..🗑️"],
    ["publish_manual", "5", "Ready to publish..✅"],
    ["published", "6", "Published✓"]
  ]

  static func findMatchingStatus(statusCode: String) -> NSAttributedString? {
    for status in statusList {
      if statusCode == status[0] {
        let description = status[2]
        let attributedString = NSMutableAttributedString(string: description)

        // Customize the appearance of the attributed string if needed
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 14), range: NSRange(location: 0, length: description.count))

        return attributedString
      }
    }
    return nil
  }
}
extension NSAttributedString {
  func contains(_ substring: String) -> Bool {
    // Extract the plain string from the NSAttributedString
    let plainString = self.string
    // Check if the plain string contains the substring
    return plainString.range(of: substring) != nil
  }
}

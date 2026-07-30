//
//  WavesPopupViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 06/04/2024.
//

import Foundation
import Combine
import UIKit
class WavesPopupViewModel {
    var hivePosts: HivePosts?
    var snapPost: HivePosts?
    var upvotesId: [Int] = []
    var cancellables = Set<AnyCancellable>()
    private let loaderSubject = PassthroughSubject<Bool, Never>()
    var loaderPublisher: AnyPublisher<Bool, Never> {
        return loaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    private let clearTextSubject = PassthroughSubject<Bool, Never>()
    var clearTextPublisher: AnyPublisher<Bool, Never> {
        return clearTextSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    private var commentsSubject = PassthroughSubject<(PostsResults, [PostComments]), Never>()
    var commentsPublisher: AnyPublisher<(PostsResults, [PostComments]), Never> {
        return commentsSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    private var refreshSubject = PassthroughSubject<Bool, Never>()
    var refreshPublisher: AnyPublisher<Bool, Never> {
        return refreshSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    private var uploadedImageURLSubject = PassthroughSubject<String, Never>()
    var uploadedImageURLPublisher: AnyPublisher<String, Never> {
        return uploadedImageURLSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    var previewContent = "Wave Review"
    let shareUpdate = "Share a quick update..."
//    var author = ""
//    var permlink = ""
    private var ecencyComments: [PostComments] = []
    private var snapComments: [PostComments] = []
    var postResult: PostsResults? = nil
    var commentsAndSnaps: [PostComments] = []
    init(){
        Task {
            await getWaveContent()
            await getSnaps()
        }
    }

    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()

    func appendCommentIdToVotes(commentId: Int) {
        upvotesId.append(commentId)
    }

    var commentCount: Int {
        return commentsAndSnaps.count
    }

    func createWave(body: String, stepCount: String, appVersion: String, isSnap: Bool) async {
        guard let userName = User.current()?.steemit_username  else { return }
        let author = isSnap ? (snapPost?.result.first?.author ?? "") : (hivePosts?.result.first?.author ?? "")
        let permlink = isSnap ? (snapPost?.result.first?.permlink ?? "") : (hivePosts?.result.first?.permlink ?? "")
        loaderSubject.send(true)
        let opName = "comment"
        let commentPerm = "\(getCommentType(isSnap: isSnap))actifit-\((User.current()?.steemit_username.replacingOccurrences(of: ".", with: "-")) ?? "")\(Date().converToServerDate())".replacingOccurrences(of: "[^a-zA-Z0-9-]+", with: "", options: .regularExpression).lowercased()
        var customParams: [String:Any] =
        [
            "author": User.current()?.steemit_username ?? "",
            "permlink": commentPerm,
            "title": "",
            "body" : body,
            "parent_author": author,
            "parent_permlink" : permlink
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
                let waveResponse = await HTTPClient().createWave(username: userName, body: customParams, comment: opName)
                self.loaderSubject.send(false)
                switch waveResponse {
                case .success(let success):
                    if success.success {
                        self.clearTextSubject.send(true)
                    }
                case .failure(let failure):
                    print(failure.localizedDescription)
                }
            }
        }
        catch let error  {
            self.loaderSubject.send(false)
            print(error.localizedDescription)
        }

    }

    private func getCommentType(isSnap: Bool) -> String {
        return isSnap ? "snap-" : "wave-"
    }

    private func getWaveContent() async {
        // Show the loader immediately (a *delayed* send(true) could fire AFTER a fast
        // load's send(false) and re-show the spinner forever over loaded content).
        self.loaderSubject.send(true)
        let waveContent = await HTTPClient().getWave()
        switch waveContent {
        case .success(let success):
            self.hivePosts = success
            guard let post = success.result.first else { self.loaderSubject.send(false); return }
            Task {
                await self.getWavePostComments(wavePost: post, isSnap: false)
            }
        case .failure(let failure):
            print(failure.localizedDescription)
            self.loaderSubject.send(false)
        }
    }

    private func getSnaps() async {
        self.loaderSubject.send(true)
        let waveContent = await HTTPClient().getSnaps()
        switch waveContent {
        case .success(let success):
            self.snapPost = success
            guard let post = success.result.first else { self.loaderSubject.send(false); return }
            Task {
                await self.getWavePostComments(wavePost: post, isSnap: true)
            }
        case .failure(let failure):
            print(failure.localizedDescription)
            self.loaderSubject.send(false)
        }
    }


    func getPastWaveCommentsOnPagination(isSnap: Bool) {
        // Guard the index: result[1] force-subscripts and would crash when the account
        // returned fewer than two posts.
        if isSnap {
            guard let posts = self.snapPost?.result, posts.count > 1 else { return }
            let post = posts[1]
            Task {
                await getWavePostComments(wavePost: post, isSnap: true)
            }
        } else {
            guard let posts = self.hivePosts?.result, posts.count > 1 else { return }
            let post = posts[1]
            Task {
                await getWavePostComments(wavePost: post, isSnap: false)
            }
        }
    }

    private func getWavePostComments(wavePost: PostsResults, isSnap: Bool) async {
        let comments = await HTTPClient().getComments(author: wavePost.author ?? "", permlink: wavePost.permlink ?? "")
        switch comments {
        case .success(let comments):
            comments.result.forEach { comment in
                comment.updateSnapStatus(isSnap: isSnap)
            }
            self.postResult = wavePost
            if isSnap {
                self.snapComments = comments.result
            } else {
                self.ecencyComments = comments.result
            }
            self.sortComments()
            self.loaderSubject.send(false)
        case .failure(let failure):
            print(failure.localizedDescription)
            self.loaderSubject.send(false)   // never leave the spinner running on a failed fetch
        }
    }

    func sortComments() {
        commentsAndSnaps = (ecencyComments + snapComments).sorted {
            guard let date1 = dateFormatter.date(from: $0.created),
                  let date2 = dateFormatter.date(from: $1.created) else { return false }
            return date1 > date2
        }
        print(commentsAndSnaps)
        refreshSubject.send(true)
    }

    func uploadData(image:UIImage) async {
        loaderSubject.send(true)
        do {
            let imageURL = try await ImageUploadManager().uploadImage(image)
            self.loaderSubject.send(false)
            self.uploadedImageURLSubject.send(imageURL)

        } catch {
            print(error.localizedDescription)
            self.loaderSubject.send(false)
        }
    }
}

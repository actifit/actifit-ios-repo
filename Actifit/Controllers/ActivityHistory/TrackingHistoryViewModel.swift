//
//  DailyLeaderboardViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 16/08/2024.
//

import Foundation
import Combine


class TrackingHistoryViewModel {
  var cancellables =  Set<AnyCancellable>()
  var history = [Activity]()
  var historyWithReportStatus: [HistoryWithReportModel] = []
  private let loaderSubject = PassthroughSubject<Bool, Never>()
  var loaderPublisher: AnyPublisher<Bool, Never> {
    return loaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let refreshSubject = PassthroughSubject<Bool, Never>()
  var refreshPublisher: AnyPublisher<Bool, Never> {
    return refreshSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }


  var posts: [Post] = []
  init() {
      history = Activity.allWithoutCountZero()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute:  {
      Task{
        await self.getUserPosts()
      }
    })
  }

    func getUserPosts(startAuthor: String? = nil, startPermlink: String? = nil) async {
        if startAuthor == nil && startPermlink == nil {
            self.posts.removeAll()
            self.historyWithReportStatus.removeAll()
        }
        guard let username = User.current()?.steemit_username else { return }
        loaderSubject.send(true)
        let posts = await HTTPClient().getUserPosts(username: username)
        loaderSubject.send(false)
        switch posts {
        case .success(let posts):
            self.updateTableWithPostIcon(posts: posts, isPagination: !self.posts.isEmpty)
        case .failure(let failure):
            print(failure.localizedDescription)
        }
    }

    private func updateTableWithPostIcon(posts: HiveUserPosts, isPagination: Bool) {
    let finalPosts = posts.result.compactMap { post -> Post? in
        guard
            let activityType = post.jsonMetadata.activityType,
            let stepCount = post.jsonMetadata.stepCount,
            let tags = post.jsonMetadata.tags,
            !activityType.isEmpty,
            !stepCount.isEmpty,
            tags.contains(where: { tag in tag == "hive-193552" || tag == "actifit" })
        else {
            return nil
        }
        return post
    }
      self.posts = self.posts + finalPosts
        filterHistoryObjects(isPagination: isPagination)
  }

    func filterHistoryObjects(isPagination: Bool) {
        DispatchQueue.main.async {
//            if !isPagination {
//                self.historyWithReportStatus.removeAll()
//            }

            self.history.forEach { element in
                // Find the first matching post
                if let matchingPost = self.posts.first(where: { post in
                    self.areMonthAndDayEqual(postDate: post.created, activityDate: element.date)
                }) {
                    // If a matching post exists, append it with containsReport = true
                    self.historyWithReportStatus.append(HistoryWithReportModel(activity: element, containsReport: true, post: matchingPost))
                } else {
                    self.historyWithReportStatus.append(HistoryWithReportModel(activity: element, containsReport: false, post: nil))
                }
            }

            self.refreshSubject.send(true)
        }
    }
    
    func areMonthAndDayEqual(postDate: String, activityDate: Date) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(abbreviation: "UTC")  // Ensure consistency

        // Convert the string to a Date object
        guard let createdDate = formatter.date(from: postDate) else {
            print("❌ Error: Invalid date string format")
            return false
        }

        // Extract month and day from both dates
        let calendar = Calendar.current
        let createdMonth = calendar.component(.month, from: createdDate)
        let createdDay = calendar.component(.day, from: createdDate)

        let existingMonth = calendar.component(.month, from: activityDate)
        let existingDay = calendar.component(.day, from: activityDate)

        print("🔹 Created Month/Day: \(createdMonth)/\(createdDay)")
        print("🔹 Existing Month/Day: \(existingMonth)/\(existingDay)")

        return createdMonth == existingMonth && createdDay == existingDay
    }
}

struct HistoryWithReportModel {
    let activity: Activity
    let containsReport: Bool
    let post: Post?
    init(activity: Activity, containsReport: Bool, post: Post?) {
        self.activity = activity
        self.containsReport = containsReport
        self.post = post
    }
}


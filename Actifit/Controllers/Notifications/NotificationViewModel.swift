//
//  NotificationViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 25/07/2023.
//

import Foundation
import Combine
import UIKit
class NotificationViewModel {
  var httpClient  = HTTPClient()
  var cancellables = Set<AnyCancellable>()
  var notificationsList: [NotificationModel] = []
  private let notificationDataReceivedSubject =  PassthroughSubject<Bool, Never>()
  private let loaderStatus = PassthroughSubject<Bool, Never>()
  var loaderStatusPublisher: AnyPublisher<Bool, Never> {
    return loaderStatus.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  var notificationsPublisher: AnyPublisher<Bool, Never> {
    return notificationDataReceivedSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  init () {
    Task {
      await getNotifications()
    }
  }

 func getNotifications() async {
    loaderStatus.send(true)
    guard let username  = User.current()?.steemit_username else { return }
    let notifications = await httpClient.getNotifications(username: username)
    self.loaderStatus.send(false)
    switch notifications {
    case .success(let notifications):
        self.notificationsList = Array(notifications.reversed())
        self.notificationDataReceivedSubject.send(true)
    case .failure(let failure):
        print("Error, please try again")
    }
  }
}

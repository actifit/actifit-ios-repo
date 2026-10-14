//
//  NotificationsModel.swift
//  Actifit
//
//  Created by Ali Jaber on 27/07/2023.
//

import Foundation
struct NotificationModel: Codable {
    let user: String?
    let details: String?
    let date: String?
    let url: String?
    /// e.g. "friendship_request"; optional so older payloads still decode.
    let type: String?
}

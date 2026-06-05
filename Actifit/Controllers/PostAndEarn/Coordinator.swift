//
//  Coordinator.swift
//  Actifit
//
//  Created by Ali Jaber on 17/07/2024.
//

import SwiftUI

class Coordinator: ObservableObject {
  enum Actions {
    case dismiss
    case viewPost(url: String)
    case sharePost(url: String)
  }
  @Published var action: Actions?
//    @Published var isActive: Bool = true
//    @Published var viewPost: Bool = true
//    @Published var sharePost: Bool = true
}


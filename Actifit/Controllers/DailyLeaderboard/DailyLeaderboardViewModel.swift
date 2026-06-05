//
//  DailyLeaderboardViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 11/09/2024.
//

import Foundation
import Combine
class DailyLeaderboardViewModel {
    var leaderboardArray: [LeaderboardModel] = []
    private let refreshSubject = PassthroughSubject<Bool, Never>()
    var refreshPublisher: AnyPublisher<Bool, Never> {
        return refreshSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    private let loaderSubject = PassthroughSubject<Bool, Never>()
    var loaderPublisher: AnyPublisher<Bool, Never> {
      return loaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    var cancellable = Set<AnyCancellable>()


    init() {
        DispatchQueue.main.asyncAfter(deadline: .now(), execute: {
            Task {
                await self.fetchDailyLeaderboard()
            }
        })

    }

    func fetchDailyLeaderboard() async {
        loaderSubject.send(true)
        let leaderboard = await HTTPClient().dailyLeaderboard()
        loaderSubject.send(false)
        switch leaderboard {
        case .success(let leaderboardData):
            self.leaderboardArray = leaderboardData
            self.refreshSubject.send(true)
        case .failure(let failure):
            print(failure.localizedDescription)
        }
    }
}

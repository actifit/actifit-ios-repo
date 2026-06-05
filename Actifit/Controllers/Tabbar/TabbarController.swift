//
//  TabbarController.swift
//  Actifit
//
//  Created by Ali Jaber on 03/09/2024.
//

import UIKit
import SwiftUI

class TabbarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
//
        //self.delegate = self
        let dashboard = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ActivityTrackingVC") as! ActivityTrackingVC
        let settingsVC = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "SettingsVC") as! SettingsVC
        let trackingHistoryVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrackingHistoryVC") as! TrackingHistoryVC
        let dailyLeaderBoardVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DailyLeaderBoardBVC") as! DailyLeaderBoardBVC
        let socialView = SocialView()
        let socialController = UIHostingController(rootView: socialView)

        // Set tab bar item properties

        dashboard.tabBarItem = UITabBarItem(title: "Dashboard", image: UIImage(systemName: "house"), tag: 0)
        trackingHistoryVC.tabBarItem = UITabBarItem(title: "History", image: UIImage(systemName: "clock"), tag: 1)
        socialController.tabBarItem = UITabBarItem(title: "Social", image: UIImage(named: "social2-icon"), tag: 2)
        dailyLeaderBoardVC.tabBarItem = UITabBarItem(title: "Leaderboard", image: UIImage(systemName: "star"), tag: 3)
        settingsVC.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 4)

        //self.viewControllers = [trackingHistoryVC, settingsVC]
        self.viewControllers = [dashboard, trackingHistoryVC, socialController, dailyLeaderBoardVC, settingsVC] // viewControllers
        self.tabBar.backgroundColor = .white
        print("Tab Bar View Controllers: \(String(describing: self.viewControllers))")

        // Do any additional setup after loading the view.
    }

}

extension TabbarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        print(viewController)
        print("Selected Tab: \(viewController.title ?? "Unknown")")
    }
}

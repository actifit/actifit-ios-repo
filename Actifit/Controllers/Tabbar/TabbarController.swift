//
//  TabbarController.swift
//  Actifit
//
//  Created by Ali Jaber on 03/09/2024.
//

import UIKit
import SwiftUI
import SafariServices

class TabbarController: UITabBarController {

    // Held for routing from the "More" sheet (no longer top-level tabs).
    private var trackingHistoryVC: UIViewController!
    private var settingsVC: UIViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self

        let dashboard = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ActivityTrackingVC") as! ActivityTrackingVC
        settingsVC = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "SettingsVC") as! SettingsVC
        trackingHistoryVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrackingHistoryVC") as! TrackingHistoryVC
        let dailyLeaderBoardVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DailyLeaderBoardBVC") as! DailyLeaderBoardBVC
        let socialController = UIHostingController(rootView: SocialView())

        let market = MarketViewController.create()
        market.hidesCloseButton = true
        let marketNav = UINavigationController(rootViewController: market)

        let moreVC = UIViewController() // placeholder — its selection is intercepted

        dashboard.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
        socialController.tabBarItem = UITabBarItem(title: "Social", image: UIImage(named: "social2-icon") ?? UIImage(systemName: "person.2.fill"), tag: 1)
        marketNav.tabBarItem = UITabBarItem(title: "Market", image: UIImage(systemName: "cart.fill"), tag: 2)
        dailyLeaderBoardVC.tabBarItem = UITabBarItem(title: "Leaders", image: UIImage(systemName: "trophy.fill"), tag: 3)
        moreVC.tabBarItem = UITabBarItem(title: "More", image: UIImage(systemName: "ellipsis"), tag: 4)

        self.viewControllers = [dashboard, socialController, marketNav, dailyLeaderBoardVC, moreVC]
        self.tabBar.backgroundColor = .white
        if let red = UIColor(named: "primaryRed") { self.tabBar.tintColor = red }
    }

    fileprivate func presentMoreSheet() {
        let items: [MoreMenuViewController.Item] = [
            .init(title: "History", systemIcon: "clock.fill") { [weak self] in self?.presentInNav(self?.trackingHistoryVC) },
            .init(title: "Settings", systemIcon: "gearshape.fill") { [weak self] in self?.presentInNav(self?.settingsVC) },
            .init(title: "Help", systemIcon: "questionmark.circle.fill") { [weak self] in
                if let url = URL(string: "https://actifit.io/faq") { self?.present(SFSafariViewController(url: url), animated: true) }
            }
        ]
        let sheet = MoreMenuViewController(items: items)
        if let sp = sheet.sheetPresentationController {
            sp.detents = [.medium()]
            sp.prefersGrabberVisible = true
        }
        present(sheet, animated: true)
    }

    private func presentInNav(_ vc: UIViewController?) {
        guard let vc = vc else { return }
        let nav = UINavigationController(rootViewController: vc)
        vc.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPresented))
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func dismissPresented() { dismiss(animated: true) }
}

extension TabbarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem?.tag == 4 { // More
            presentMoreSheet()
            return false
        }
        return true
    }
}

// MARK: - "More" bottom sheet

final class MoreMenuViewController: UIViewController {

    struct Item {
        let title: String
        let systemIcon: String
        let action: () -> Void
    }

    private let items: [Item]

    init(items: [Item]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let header = UILabel()
        header.text = "More"
        header.font = .systemFont(ofSize: 20, weight: .bold)

        let stack = UIStackView(arrangedSubviews: [header])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 24, left: 20, bottom: 20, right: 20)

        for (i, item) in items.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle("   " + item.title, for: .normal)
            b.setImage(UIImage(systemName: item.systemIcon), for: .normal)
            b.tintColor = UIColor(named: "primaryRed")
            b.setTitleColor(.label, for: .normal)
            b.contentHorizontalAlignment = .left
            b.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
            b.heightAnchor.constraint(equalToConstant: 52).isActive = true
            b.tag = i
            b.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(b)
        }

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    @objc private func itemTapped(_ sender: UIButton) {
        let action = items[sender.tag].action
        dismiss(animated: true) { action() }
    }
}

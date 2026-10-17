//
//  TabbarController.swift
//  Actifit
//
//  Created by Ali Jaber on 03/09/2024.
//

import UIKit
import SwiftUI
import SafariServices

/// Hosts SocialView and tells it each time the tab comes on screen, so the feed can reload
/// (the SwiftUI view is created once at launch and would otherwise never refresh).
final class SocialTabContainer: UIViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: .socialTabDidAppear, object: nil)
    }
}

class TabbarController: UITabBarController {

    // Held for routing from the "More" sheet (no longer top-level tabs).
    private var trackingHistoryVC: UIViewController!
    private var settingsVC: UIViewController!
    private var dailyLeaderBoardVC: UIViewController!
    private let friendsVC = FriendsViewController()
    /// Hosts the screens opened from the More sheet (History, Settings) inside the More tab,
    /// so the tab bar stays visible on them.
    private let moreNav = UINavigationController()
    /// Hosts the dashboard and the screens it opens (Wallet, Notifications, Profile,
    /// Post & Earn) inside the Home tab, so the tab bar stays visible on them too.
    private let homeNav = UINavigationController()
    private static let moreTabIndex = 4
    /// The live tab bar, for routing notification links into it.
    static weak var current: TabbarController?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        TabbarController.current = self

        let dashboard = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ActivityTrackingVC") as! ActivityTrackingVC
        settingsVC = UIStoryboard(name: "Settings", bundle: nil).instantiateViewController(withIdentifier: "SettingsVC") as! SettingsVC
        trackingHistoryVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TrackingHistoryVC") as! TrackingHistoryVC
        dailyLeaderBoardVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DailyLeaderBoardBVC") as! DailyLeaderBoardBVC
        // A bare UIHostingController lets SocialView's red header bleed under the status
        // bar. Wrap it in a white container and pin the SwiftUI content to the container's
        // SAFE-AREA top, so the header starts below the status bar with white showing above
        // (matches Market/Leaders/History).
        let socialHost = UIHostingController(rootView: SocialView())
        let socialController = SocialTabContainer()
        socialController.view.backgroundColor = .white
        socialController.addChildViewController(socialHost)
        socialController.view.addSubview(socialHost.view)
        socialHost.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            socialHost.view.topAnchor.constraint(equalTo: socialController.view.safeAreaLayoutGuide.topAnchor),
            socialHost.view.leadingAnchor.constraint(equalTo: socialController.view.leadingAnchor),
            socialHost.view.trailingAnchor.constraint(equalTo: socialController.view.trailingAnchor),
            socialHost.view.bottomAnchor.constraint(equalTo: socialController.view.bottomAnchor)
        ])
        socialHost.didMove(toParentViewController: socialController)

        let market = MarketViewController.create()
        market.hidesCloseButton = true
        let marketNav = UINavigationController(rootViewController: market)

        // The Arena took the Leaders tab (as on Android); the Daily Leaderboard moved to More.
        // Challenge screens are pushed inside this tab so the tab bar stays visible.
        let arenaNav = UINavigationController(rootViewController: ArenaViewController())
        arenaNav.setNavigationBarHidden(true, animated: false)

        let moreVC = moreNav // tapping the tab opens the More sheet; see shouldSelect
        // These screens (and the history charts pushed from them) draw their own headers and
        // back buttons, so the system navigation bar stays hidden.
        moreNav.setNavigationBarHidden(true, animated: false)
        moreNav.view.backgroundColor = .white

        // The dashboard and every screen it pushes draw their own headers and back buttons.
        homeNav.setViewControllers([dashboard], animated: false)
        homeNav.setNavigationBarHidden(true, animated: false)
        homeNav.delegate = self
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house.fill"), tag: 0)
        socialController.tabBarItem = UITabBarItem(title: "Social", image: UIImage(named: "social2-icon") ?? UIImage(systemName: "person.2.fill"), tag: 1)
        marketNav.tabBarItem = UITabBarItem(title: "Market", image: UIImage(systemName: "cart.fill"), tag: 2)
        arenaNav.tabBarItem = UITabBarItem(title: ArenaText.title, image: UIImage(systemName: "trophy.fill"), tag: 3)
        moreVC.tabBarItem = UITabBarItem(title: "More", image: UIImage(systemName: "ellipsis"), tag: 4)

        self.viewControllers = [homeNav, socialController, marketNav, arenaNav, moreVC]
        self.tabBar.backgroundColor = .white
        if let red = UIColor(named: "primaryRed") { self.tabBar.tintColor = red }
    }

    fileprivate func presentMoreSheet() {
        // Mirrors the Android "More" menu (bottom_sheet_more_menu.xml), in the same order. Upload
        // Video, Follow Us, Video Tutorial and Community Chat lost their only entry points when the
        // revamped dashboard covered the legacy bottom menu. The Daily Leaderboard moved here when
        // the Arena took its tab. Settings is here because, unlike on Android, it is not
        // otherwise reachable from every tab.
        let items: [MoreMenuViewController.Item] = [
            .init(title: "Activity History", systemIcon: "clock.fill") { [weak self] in self?.showInMoreTab(self?.trackingHistoryVC) },
            .init(title: FriendsText.title, systemIcon: "person.crop.circle.badge.plus") { [weak self] in self?.showFriends() },
            .init(title: "Daily Leaderboard", systemIcon: "list.number") { [weak self] in self?.showInMoreTab(self?.dailyLeaderBoardVC) },
            .init(title: "Upload Video", systemIcon: "video.fill") { [weak self] in
                self?.present(ThreeSpeakVideoViewController.create(), animated: true)
            },
            .init(title: "Follow Us", systemIcon: "person.2.fill") { [weak self] in
                self?.present(SocialMediaPopupViewController.create(), animated: true)
            },
            .init(title: "Help & FAQ", systemIcon: "questionmark.circle.fill") { [weak self] in
                if let url = URL(string: "https://actifit.io/faq") { self?.present(SFSafariViewController(url: url), animated: true) }
            },
            .init(title: "Video Tutorial", systemIcon: "play.rectangle.fill") { [weak self] in
                self?.present(TutorialVideoViewController.create(), animated: true)
            },
            .init(title: "Community Chat", systemIcon: "bubble.left.and.bubble.right.fill") { [weak self] in
                let chat = ChatViewController()
                chat.modalPresentationStyle = .overFullScreen
                self?.present(chat, animated: true)
            },
            .init(title: "Settings", systemIcon: "gearshape.fill") { [weak self] in self?.showSettings() }
        ]
        // The screen currently open in the More tab gets its row highlighted, as on Android.
        let screens: [(UIViewController?, String)] = [(trackingHistoryVC, "Activity History"), (friendsVC, FriendsText.title),
                                                      (dailyLeaderBoardVC, "Daily Leaderboard"), (settingsVC, "Settings")]
        let current = selectedIndex == TabbarController.moreTabIndex ? moreNav.viewControllers.first : nil
        let currentTitle = screens.first { $0.0 != nil && $0.0 === current }?.1
        let sheet = MoreMenuViewController(items: items, highlighted: items.firstIndex { $0.title == currentTitle })
        if let sp = sheet.sheetPresentationController {
            sp.detents = [.medium(), .large()]
            sp.prefersGrabberVisible = true
        }
        present(sheet, animated: true)

        // Pending received friend requests, as a badge on the Friends row.
        let user = arenaCurrentUser()
        if !user.isEmpty, let friendsRow = items.firstIndex(where: { $0.title == FriendsText.title }) {
            FriendsAPI.requests(of: user) { [weak sheet] requests in
                guard let count = requests?.received.count, count > 0 else { return }
                sheet?.setBadge("\(count)", at: friendsRow, accessibility: FriendsText.pendingBadge(count))
            }
        }
    }

    /// Shows a screen inside the More tab rather than full screen, keeping the tab bar on
    /// screen with More marked as the current tab.
    private func showInMoreTab(_ vc: UIViewController?) {
        guard let vc = vc else { return }
        moreNav.setViewControllers([vc], animated: false)
        selectedIndex = TabbarController.moreTabIndex
        updateTabTint()
    }

    /// Also used by the dashboard's settings button, so Settings looks the same from both.
    func showSettings() {
        showInMoreTab(settingsVC)
    }

    /// Opens Friends inside the More tab, optionally on a tab (notification deep links).
    func showFriends(tab: FriendsViewController.Tab? = nil) {
        if let tab = tab { friendsVC.show(tab: tab) }
        showInMoreTab(friendsVC)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ArenaDeepLink.deliver()   // a notification tapped before the tab bar existed
    }

    /// Opens the Arena tab on its challenge list (used by the dashboard's Arena card), or on one
    /// challenge (notification links).
    func showArena(challengeId: String? = nil) {
        // A sheet or modal (More, Post & Earn) would otherwise hide the challenge.
        presentedViewController?.dismiss(animated: false)
        selectedIndex = 3
        updateTabTint()
        guard let nav = selectedViewController as? UINavigationController else { return }
        nav.popToRootViewController(animated: false)
        if let id = challengeId {
            nav.pushViewController(ArenaChallengeViewController(challengeId: id), animated: true)
        }
    }

    /// The More tab is tinted green while one of its screens is showing; other tabs stay red.
    private func updateTabTint() {
        let onMore = selectedIndex == TabbarController.moreTabIndex
        if onMore {
            tabBar.tintColor = .primaryGreenColor()
        } else if let red = UIColor(named: "primaryRed") {
            tabBar.tintColor = red
        }
        // The app's root navigation bar is empty but sits over the top of every tab and swallows
        // taps there, including the back arrow on the history charts. Let taps through while a
        // More screen is showing (hiding the bar instead would shift every header up).
        navigationController?.navigationBar.isUserInteractionEnabled = !onMore
        updateRootBar(showing: homeNav.topViewController)
    }

    /// Screens pushed from the dashboard have full-height headers of their own, so the root
    /// navigation bar is hidden while one of them is on screen and restored otherwise.
    private func updateRootBar(showing top: UIViewController?) {
        let pushedInHome = selectedIndex == 0 && top != nil && top !== homeNav.viewControllers.first
        navigationController?.setNavigationBarHidden(pushedInHome, animated: false)
    }
}

extension TabbarController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard navigationController === homeNav else { return }
        navigationController.setNavigationBarHidden(true, animated: false)
        updateRootBar(showing: viewController)
    }
}


extension TabbarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
        if viewController.tabBarItem?.tag == 4 { // More
            presentMoreSheet()
            return false
        }
        return true
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        updateTabTint()
        ArenaDeepLink.deliver()   // one that waited for a modal to close
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
    private let highlighted: Int?
    private var buttons: [UIButton] = []

    init(items: [Item], highlighted: Int? = nil) {
        self.items = items
        self.highlighted = highlighted
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
            buttons.append(b)
        }

        // Scrollable: the list is taller than the medium detent.
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        // Light pink band across the full sheet width behind the current screen's row.
        if let i = highlighted, i < buttons.count {
            let band = UIView()
            band.backgroundColor = UIColor.primaryRedColor().withAlphaComponent(0.1)
            band.translatesAutoresizingMaskIntoConstraints = false
            band.isUserInteractionEnabled = false
            scroll.insertSubview(band, belowSubview: stack)
            NSLayoutConstraint.activate([
                band.topAnchor.constraint(equalTo: buttons[i].topAnchor),
                band.bottomAnchor.constraint(equalTo: buttons[i].bottomAnchor),
                band.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor),
                band.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor)
            ])
            buttons[i].accessibilityTraits |= UIAccessibilityTraitSelected
        }
    }

    /// A red count pill at the trailing edge of one row.
    func setBadge(_ text: String, at index: Int, accessibility: String) {
        guard index < buttons.count else { return }
        let b = buttons[index]
        let badge = UILabel()
        badge.text = "  \(text)  "
        badge.font = .systemFont(ofSize: 13, weight: .bold)
        badge.textColor = .white
        badge.backgroundColor = UIColor(named: "primaryRed") ?? .red
        badge.layer.cornerRadius = 11
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false
        b.addSubview(badge)
        NSLayoutConstraint.activate([
            badge.trailingAnchor.constraint(equalTo: b.trailingAnchor),
            badge.centerYAnchor.constraint(equalTo: b.centerYAnchor),
            badge.heightAnchor.constraint(equalToConstant: 22)
        ])
        b.accessibilityValue = accessibility
    }

    @objc private func itemTapped(_ sender: UIButton) {
        let action = items[sender.tag].action
        dismiss(animated: true) { action() }
    }
}

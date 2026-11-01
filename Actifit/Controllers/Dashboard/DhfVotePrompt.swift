//
//  DhfVotePrompt.swift
//  Actifit
//
//  Asks users who have not voted for Actifit's DHF proposal to vote for it (Android
//  DhfVotePromptManager). Three triggers: app open (random, with cooldowns), right after a
//  post, and a dashboard card. The vote happens on the web (Hivesigner or PeakD) because it
//  needs the active key. Vote status is read on chain and cached, so voters are never asked.
//

import UIKit

enum DhfVotePrompt {

    /// The proposal users are asked to support. Change this (and only this) for a new proposal.
    static let proposalId = 391

    private static let checkTTL: TimeInterval = 24 * 3600          // re-check vote status daily
    private static let promptCooldown: TimeInterval = 3 * 24 * 3600 // gap between app-open prompts
    private static let maxDismissals = 3
    private static let appOpenChance = 0.20
    private static let afterPostCooldown: TimeInterval = 24 * 3600
    private static let cardSnooze: TimeInterval = 10 * 24 * 3600

    /// Set by the post screen after a successful post; read once by the dashboard.
    static let justPostedKey = "dhfJustPosted"

    // Vote and dismissal records are per proposal, so a new proposal asks everyone again.
    private static var kVoted: String { return "dhfVoted_\(proposalId)" }
    private static var kCheckedAt: String { return "dhfVotedCheckedAt_\(proposalId)" }
    private static var kLastShown: String { return "dhfPromptLastShownAt_\(proposalId)" }
    private static var kDismissals: String { return "dhfPromptDismissCount_\(proposalId)" }
    private static var kAfterPostShown: String { return "dhfAfterPostLastShownAt_\(proposalId)" }
    private static var kCardSnoozedAt: String { return "dhfCardSnoozedAt_\(proposalId)" }
    private static let kCardCollapsed = "dhfCardCollapsed"
    private static let kWebPending = "dhfWebVotePending"
    private static let kHasPosted = "dhfHasPosted"

    private static var defaults: UserDefaults { return .standard }
    private static var now: TimeInterval { return Date().timeIntervalSince1970 }

    static var username: String {
        return User.current()?.steemit_username.byTrimming(string: "@").lowercased() ?? ""
    }

    static var hasVoted: Bool { return defaults.bool(forKey: kVoted) }

    // MARK: Triggers

    /// Dashboard appeared: after a post, the after-post prompt; otherwise the app-open roll.
    /// `refresh` redraws the card once the vote status is known.
    static func onDashboardAppear(from vc: UIViewController, refresh: @escaping () -> Void) {
        refresh()
        guard !username.isEmpty else { return }
        if defaults.bool(forKey: justPostedKey) {
            defaults.set(false, forKey: justPostedKey)
            defaults.set(true, forKey: kHasPosted)
            refreshIfStale {
                refresh()
                guard !hasVoted, dismissals < maxDismissals,
                      now - defaults.double(forKey: kAfterPostShown) > afterPostCooldown else { return }
                defaults.set(now, forKey: kAfterPostShown)
                show(from: vc)
            }
            return
        }
        guard !hasVoted else { return }
        refreshIfStale {
            refresh()
            ensureHasPosted {
                refresh()
                guard !hasVoted, dismissals < maxDismissals,
                      now - defaults.double(forKey: kLastShown) > promptCooldown,
                      Double.random(in: 0..<1) < appOpenChance else { return }
                show(from: vc)
            }
        }
    }

    /// Back from the browser after tapping a vote button: re-check so a voter stops being asked.
    static func onReturnFromWeb(from vc: UIViewController, refresh: @escaping () -> Void) {
        guard defaults.bool(forKey: kWebPending) else { return }
        defaults.set(false, forKey: kWebPending)
        refreshVoteStatus {
            if hasVoted { vc.showToast(message: DhfText.thanks) }
            refresh()
        }
    }

    // MARK: Prompt

    static func show(from vc: UIViewController) {
        guard vc.view.window != nil, vc.presentedViewController == nil else { return }
        defaults.set(now, forKey: kLastShown)
        let alert = UIAlertController(title: DhfText.title, message: DhfText.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: DhfText.hivesigner, style: .default) { _ in openVote(hivesignerURL) })
        alert.addAction(UIAlertAction(title: DhfText.peakd, style: .default) { _ in openVote(peakdURL) })
        alert.addAction(UIAlertAction(title: DhfText.later, style: .cancel) { _ in
            defaults.set(dismissals + 1, forKey: kDismissals)
        })
        vc.present(alert, animated: true)
    }

    static var hivesignerURL: URL {
        return URL(string: "https://hivesigner.com/sign/update-proposal-votes?proposal_ids=%5B\(proposalId)%5D&approve=true")!
    }

    static var peakdURL: URL { return URL(string: "https://peakd.com/proposals/\(proposalId)")! }

    private static func openVote(_ url: URL) {
        defaults.set(true, forKey: kWebPending)
        UIApplication.shared.open(url)
    }

    private static var dismissals: Int { return defaults.integer(forKey: kDismissals) }

    // MARK: Card state

    static var isCardEligible: Bool {
        return !username.isEmpty && !hasVoted && defaults.bool(forKey: kHasPosted)
            && now - defaults.double(forKey: kCardSnoozedAt) >= cardSnooze
    }

    static var isCardCollapsed: Bool {
        get { return defaults.bool(forKey: kCardCollapsed) }
        set { defaults.set(newValue, forKey: kCardCollapsed) }
    }

    /// The card's x: hidden for 10 days, then back unless the user voted.
    static func snoozeCard() { defaults.set(now, forKey: kCardSnoozedAt) }

    // MARK: Chain reads

    private static func refreshIfStale(_ done: @escaping () -> Void) {
        if now - defaults.double(forKey: kCheckedAt) > checkTTL { refreshVoteStatus(done) } else { done() }
    }

    /// Reads the user's vote on the proposal; on failure the cached status stays as it was.
    static func refreshVoteStatus(_ done: @escaping () -> Void) {
        let user = username
        let params: [Any] = [[user, proposalId], 1, "by_voter_proposal", "ascending", "all"]
        FriendsAPI.rpc("condenser_api.list_proposal_votes", params: params, timeout: 8) { result in
            if let votes = result as? [[String: Any]] {
                defaults.set(votedFor(votes, user: user, proposal: proposalId), forKey: kVoted)
                defaults.set(now, forKey: kCheckedAt)
            }
            done()
        }
    }

    /// The lookup starts at [user, proposal], so the first vote matches only if it is that one.
    static func votedFor(_ votes: [[String: Any]], user: String, proposal: Int) -> Bool {
        guard let vote = votes.first,
              let voter = vote["voter"] as? String,
              let id = (vote["proposal"] as? [String: Any])?["proposal_id"] as? Int else { return false }
        return voter.lowercased() == user.lowercased() && id == proposal
    }

    /// Only users with at least one post are asked; once true it is remembered.
    private static func ensureHasPosted(_ done: @escaping () -> Void) {
        if defaults.bool(forKey: kHasPosted) { return done() }
        FriendsAPI.rpc("bridge.get_account_posts", params: ["sort": "posts", "account": username, "limit": 1], timeout: 8) { result in
            guard let posts = result as? [Any], !posts.isEmpty else { return }
            defaults.set(true, forKey: kHasPosted)
            done()
        }
    }
}

/// Copy under Android's keys, so translations come from ci_scripts/import_android_strings.py.
enum DhfText {
    static var title: String { return Copy.text("dhf_vote_title", "Support our work 💪") }
    static var message: String {
        return Copy.text("dhf_vote_message", "A 1-tap vote on our proposal helps support our ongoing work on Hive — and it costs you nothing.")
    }
    static var hivesigner: String { return Copy.text("dhf_vote_btn_hivesigner", "Vote in 1 tap (Hivesigner)") }
    static var peakd: String { return Copy.text("dhf_vote_btn_peakd", "Read & vote (PeakD)") }
    static var later: String { return Copy.text("dhf_vote_btn_later", "Maybe later") }
    static var voteNow: String { return Copy.text("dhf_vote_btn_vote_now", "Vote now") }
    static var thanks: String { return Copy.text("dhf_vote_thanks", "Thanks for supporting Actifit! 🙏") }
}

/// The dashboard card (Android dhf_vote_card): collapsible, with an x that snoozes it.
final class DhfVoteCard: UIView {

    private let body = UIStackView()
    private let chevron = UIImageView()
    private weak var host: UIViewController?

    init(host: UIViewController) {
        self.host = host
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.borderWidth = 1
        layer.borderColor = UIColor(red: 1, green: 0.05, blue: 0.2, alpha: 1).cgColor
        accessibilityIdentifier = "dhfVoteCard"

        let logo = UIImageView(image: UIImage(named: "circular_logo"))
        logo.contentMode = .scaleAspectFit
        logo.widthAnchor.constraint(equalToConstant: 28).isActive = true
        logo.heightAnchor.constraint(equalToConstant: 28).isActive = true
        let title = UILabel()
        title.text = DhfText.title
        title.font = .systemFont(ofSize: 16, weight: .bold)
        title.textColor = UIColor(white: 0.13, alpha: 1)
        chevron.tintColor = UIColor(white: 0.45, alpha: 1)
        chevron.contentMode = .scaleAspectFit
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark"), for: .normal)
        close.tintColor = UIColor(red: 1, green: 0.05, blue: 0.2, alpha: 1)
        close.widthAnchor.constraint(equalToConstant: 28).isActive = true
        close.accessibilityLabel = DhfText.later
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [logo, title, chevron, close])
        header.axis = .horizontal; header.spacing = 8; header.alignment = .center
        header.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(headerTapped)))

        let message = UILabel()
        message.text = DhfText.message
        message.font = .systemFont(ofSize: 14)
        message.textColor = UIColor(white: 0.35, alpha: 1)
        message.numberOfLines = 0
        let vote = UIButton(type: .system)
        vote.setTitle(DhfText.voteNow, for: .normal)
        vote.setTitleColor(.white, for: .normal)
        vote.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        vote.backgroundColor = UIColor(red: 1, green: 0.05, blue: 0.2, alpha: 1)
        vote.layer.cornerRadius = 22
        vote.heightAnchor.constraint(equalToConstant: 44).isActive = true
        vote.accessibilityIdentifier = "dhfVoteNow"
        vote.addTarget(self, action: #selector(voteTapped), for: .touchUpInside)
        body.axis = .vertical; body.spacing = 12
        body.addArrangedSubview(message)
        body.addArrangedSubview(vote)

        let stack = UIStackView(arrangedSubviews: [header, body])
        stack.axis = .vertical; stack.spacing = 12
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 12)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        refresh()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func refresh() {
        isHidden = !DhfVotePrompt.isCardEligible
        setCollapsed(DhfVotePrompt.isCardCollapsed)
    }

    private func setCollapsed(_ collapsed: Bool) {
        body.isHidden = collapsed
        chevron.image = UIImage(systemName: collapsed ? "chevron.down" : "chevron.up")
    }

    @objc private func headerTapped() {
        let collapse = !body.isHidden
        DhfVotePrompt.isCardCollapsed = collapse
        UIView.animate(withDuration: 0.25) { self.setCollapsed(collapse) }
    }

    @objc private func closeTapped() {
        DhfVotePrompt.snoozeCard()
        UIView.animate(withDuration: 0.25) { self.isHidden = true }
    }

    @objc private func voteTapped() {
        guard let host = host else { return }
        DhfVotePrompt.show(from: host)
    }
}

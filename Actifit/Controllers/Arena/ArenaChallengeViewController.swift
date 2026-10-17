//
//  ArenaChallengeViewController.swift
//  Actifit
//
//  One Arena challenge (Android ArenaChallengeActivity): hero, facts, how it works, prizes,
//  standings and a sticky Join / Leave.
//
//  Join/leave is broadcast on-chain and indexed by the backend a few seconds later, so the new
//  state is shown optimistically from ArenaPendingStore until the server agrees.
//

import UIKit

final class ArenaChallengeViewController: UIViewController {

    /// The board is capped on screen; the viewer's own row is appended if it falls below.
    private static let maxStandingRows = 50

    private let challengeId: String
    private var me = ""
    private var challenge: ArenaChallenge?
    private var standings: [ArenaStandingRow]?
    private var standingsAt: Date?
    private var standingsFailed = false
    private var clock: Timer?
    private var acting = false
    private var statusOverride: String?
    /// Bumped per load(); an older response arriving late must not overwrite a newer one.
    private var loadGeneration = 0

    private let brandRed = UIColor.primaryRedColor()
    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .medium)
    private let messageButton = UIButton(type: .system)

    private let hero = UIImageView()
    private let chipsLabel = UILabel()
    private let titleLabel = UILabel()
    private let taglineLabel = UILabel()
    private let participantsLabel = UILabel()
    private let resultLabel = ArenaChallengeViewController.calloutLabel()
    private let myStandingLabel = ArenaChallengeViewController.calloutLabel()
    private let reportNote = ArenaChallengeViewController.calloutLabel()
    private let factsStack = UIStackView()
    private let howLabel = ArenaChallengeViewController.bodyLabel()
    private let prizeLabel = ArenaChallengeViewController.bodyLabel()
    private let badgesLabel = ArenaChallengeViewController.bodyLabel()
    private let updatedLabel = UILabel()
    private let standingsEmpty = ArenaChallengeViewController.bodyLabel()
    private let standingsStack = UIStackView()

    private let actionBar = UIView()
    private let actionStatus = UILabel()
    private let actionButton = UIButton(type: .system)

    init(challengeId: String) {
        self.challengeId = challengeId
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var preferredStatusBarStyle: UIStatusBarStyle { return .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        buildUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        // Re-read the user each time: they may have just come back from logging in.
        me = arenaCurrentUser()
        load()
        clock?.invalidate()
        clock = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.renderChips() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clock?.invalidate()
        clock = nil
    }

    private func renderChips() {
        guard let c = challenge else { return }
        chipsLabel.text = [c.recurrenceText, c.tierText ?? "", c.liveTimeText].filter { !$0.isEmpty }.joined(separator: "  ·  ")
        chipsLabel.textColor = c.endsWithinADay ? brandRed : .gray
    }

    // MARK: - Loading

    private func load() {
        if challenge == nil {
            spinner.startAnimating()
            messageButton.isHidden = true
        }
        loadGeneration += 1
        let gen = loadGeneration
        ArenaAPI.challenge(id: challengeId, viewer: me) { [weak self] detail, notFound in
            guard let self = self, gen == self.loadGeneration else { return }
            self.spinner.stopAnimating()
            guard let detail = detail else {
                // Keep showing what we have if only a refresh failed.
                if self.challenge == nil { self.showMessage(notFound ? ArenaText.notFound : ArenaText.detailLoadError, retry: !notFound) }
                return
            }
            self.challenge = detail
            // The "couldn't confirm" note belongs to one load; a failed-action note stays
            // until the next tap.
            if self.statusOverride == ArenaText.pendingExpired { self.statusOverride = nil }
            if ArenaPendingStore.settle(user: self.me, challenge: detail) {
                self.statusOverride = ArenaText.pendingExpired
            }
            self.render()
        }
        ArenaAPI.standings(id: challengeId) { [weak self] rows, computedAt in
            guard let self = self, gen == self.loadGeneration else { return }
            // Failed refresh: keep the board we have rather than claim there is none.
            if rows == nil && self.standings != nil { return }
            // A failed first load is an error, not "no standings yet".
            self.standingsFailed = rows == nil
            self.standings = rows
            self.standingsAt = computedAt
            if self.challenge != nil { self.renderStandings() }
        }
    }

    private func showMessage(_ text: String, retry: Bool) {
        scroll.isHidden = true
        actionBar.isHidden = true
        messageButton.setTitle(text, for: .normal)
        messageButton.isEnabled = retry
        messageButton.isHidden = false
    }

    @objc private func retryTapped() { load() }

    // MARK: - Rendering

    private func render() {
        guard let c = challenge else { return }
        messageButton.isHidden = true
        scroll.isHidden = false

        ArenaImageLoader.load(c.artURL, into: hero)
        renderChips()
        titleLabel.text = c.title
        taglineLabel.text = c.taglineText
        participantsLabel.text = ArenaText.participants(c.participantCount ?? 0)

        factsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for (label, value) in [(ArenaText.length, c.durationText), (ArenaText.scoredBy, c.scoredByText),
                               (ArenaText.starts, ArenaFormat.date(c.start)), (ArenaText.ends, ArenaFormat.date(c.end))]
            where !value.isEmpty {
            factsStack.addArrangedSubview(factRow(label, value))
        }

        howLabel.text = c.howItWorksText
        prizeLabel.text = c.prizeText
        badgesLabel.isHidden = c.offeredBadges.isEmpty
        badgesLabel.text = ArenaText.badgeAward + " " + c.offeredBadges.joined(separator: ", ")

        // The reminder only helps while there is still something to score.
        reportNote.isHidden = !ArenaLogic.isJoinable(c.state)
        reportNote.text = ArenaPendingStore.membership(user: me, challenge: c).isIn ? todayText(c) : ArenaText.reportNote

        if let mine = c.participant(me), let rank = mine.resultRank, rank > 0 {
            resultLabel.text = mine.rewardAfit > 0
                ? ArenaText.yourResult(rank: rank, afit: ArenaFormat.number(mine.rewardAfit))
                : ArenaText.yourResult(rank: rank)
            resultLabel.isHidden = false
        } else {
            resultLabel.isHidden = true
        }

        renderAction()
        renderStandings()
    }

    private func renderAction() {
        guard let c = challenge else { return }
        let m = ArenaPendingStore.membership(user: me, challenge: c)
        let joinable = c.acceptsMembershipChanges

        var status = statusOverride
        if status == nil {
            switch m {
            case .pendingJoin: status = ArenaText.joinPending
            case .pendingLeave: status = ArenaText.leavePending
            case .joined: status = ArenaText.joined
            case .notJoined: status = joinable ? nil : ArenaText.closed
            }
        }
        actionStatus.text = status
        actionStatus.isHidden = status == nil

        // Closed: nothing to do, but a participant still sees that they were in.
        actionButton.isHidden = !joinable
        actionButton.isEnabled = !acting
        let title: String
        if acting { title = ArenaText.working }
        else if me.isEmpty { title = ArenaText.loginToJoin }
        else { title = m.isIn ? ArenaText.leave : ArenaText.join }
        actionButton.setTitle(title, for: .normal)
        let leaving = m.isIn && !me.isEmpty
        actionButton.backgroundColor = acting ? .lightGray : (leaving ? .white : brandRed)
        actionButton.setTitleColor(leaving ? brandRed : .white, for: .normal)
        actionButton.layer.borderWidth = leaving ? 1.5 : 0
        actionBar.isHidden = actionButton.isHidden && actionStatus.isHidden
    }

    @objc private func actionTapped() {
        guard let c = challenge, !acting else { return }
        guard !me.isEmpty else {
            // Guests replaced the login screen with the tab bar ("Skip"), so go back to it the
            // way logging out does, and reopen this challenge once they are in.
            ArenaDeepLink.openAfterLogin(c.id)
            let login = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController")
            (UIApplication.shared.delegate as? AFAppDelegate)?.window?.rootViewController = login
            return
        }
        let leaving = ArenaPendingStore.membership(user: me, challenge: c).isIn
        let op: ArenaLogic.Op = leaving ? .leave : .join
        let user = me
        let id = c.id
        acting = true
        statusOverride = nil
        // Stored BEFORE sending: if the user leaves mid-request the op may still land, and the
        // next visit must not offer the same action again.
        let previous = ArenaPendingStore.get(user: user, challengeId: id)
        ArenaPendingStore.put(user: user, challengeId: id, op: op)
        ArenaHomeCardView.invalidate()   // membership is changing; the dashboard card must refetch
        renderAction()
        ArenaAPI.send(op, user: user, challengeId: id) { [weak self] ok in
            if !ok {
                // Back to what was pending before this tap (e.g. a join still being indexed),
                // so a failed leave can't make the screen offer that join a second time.
                if let p = previous { ArenaPendingStore.put(user: user, challengeId: id, op: p.op, at: p.at) }
                else { ArenaPendingStore.clear(user: user, challengeId: id) }
            }
            guard let self = self else { return }
            self.acting = false
            if !ok { self.statusOverride = ArenaText.actionFailed }
            self.render()
            // The backend indexes the op within a few blocks; look again so the screen settles
            // on its own. Also after a failure: a timed-out request may have landed.
            for delay in [10.0, 30.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self = self, self.viewIfLoaded?.window != nil, !self.acting else { return }
                    self.load()
                }
            }
        }
    }

    private func renderStandings() {
        guard let c = challenge else { return }
        standingsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard let rows = standings else {   // still loading, or the first load failed
            standingsEmpty.text = ArenaText.standingsError
            standingsEmpty.isHidden = !standingsFailed
            updatedLabel.isHidden = true
            return
        }
        standingsEmpty.text = ArenaText.noStandings
        renderMyStanding(c, rows)

        standingsEmpty.isHidden = !rows.isEmpty
        if let at = standingsAt, !rows.isEmpty {
            updatedLabel.text = ArenaText.standingsUpdated(ArenaFormat.relative(at))
            updatedLabel.isHidden = false
        } else {
            updatedLabel.isHidden = true
        }
        for (i, r) in rows.enumerated() where i < ArenaChallengeViewController.maxStandingRows || r.entity == me {
            standingsStack.addArrangedSubview(standingRow(r, isMe: r.entity == me, participant: c.participant(r.entity)))
        }
    }

    /// "You are #3 · 12,400 / 2,100 behind #2" for a participant while the challenge runs.
    private func renderMyStanding(_ c: ArenaChallenge, _ rows: [ArenaStandingRow]) {
        guard ArenaLogic.isJoinable(c.state), ArenaPendingStore.membership(user: me, challenge: c).isIn else {
            myStandingLabel.isHidden = true
            return
        }
        if let s = ArenaLogic.standing(of: me, in: rows) {
            let gap = s.ahead.map { ArenaText.myGap(ArenaFormat.number(max(0, $0.score - s.mine.score)), behind: $0.rank) }
            myStandingLabel.text = ArenaText.myRank(s.mine.rank, score: ArenaFormat.number(s.mine.score))
                + "\n" + (gap ?? ArenaText.myLeading)
        } else {
            myStandingLabel.text = ArenaText.myUnranked
        }
        myStandingLabel.isHidden = false
    }

    /// Today's steps on this phone, so a participant sees what is waiting on a report.
    private func todayText(_ c: ArenaChallenge) -> String {
        // Steps say nothing about a distance-scored challenge.
        if c.metric == "distance" { return ArenaText.reportNote }
        let steps = ArenaChallengeViewController.todayDeviceSteps()
        return c.metric == "goal_hit" && c.threshold > 0
            ? ArenaText.todayGoal(ArenaFormat.number(Double(steps)), of: ArenaFormat.number(c.threshold))
            : ArenaText.todaySteps(ArenaFormat.number(Double(steps)))
    }

    /// Today's count from the local activity store (0 when nothing is recorded yet), read the
    /// same way as the profile's "Today" tile.
    static func todayDeviceSteps() -> Int {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd"
        let today = f.string(from: Date())
        return Activity.all().filter { f.string(from: $0.date) == today }.map { $0.steps }.max() ?? 0
    }

    // MARK: - Layout

    private func buildUI() {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = brandRed
        view.addSubview(header)
        let back = UIButton(type: .system)
        back.translatesAutoresizingMaskIntoConstraints = false
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.tintColor = .white
        back.accessibilityLabel = "Back"
        back.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        header.addSubview(back)
        let headerTitle = UILabel()
        headerTitle.translatesAutoresizingMaskIntoConstraints = false
        headerTitle.text = ArenaText.challenge
        headerTitle.font = .systemFont(ofSize: 18, weight: .bold)
        headerTitle.textColor = .white
        header.addSubview(headerTitle)

        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        scroll.isHidden = true

        content.axis = .vertical
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 24, right: 16)
        scroll.addSubview(content)

        hero.contentMode = .scaleAspectFill
        hero.clipsToBounds = true
        hero.layer.cornerRadius = 14
        hero.backgroundColor = UIColor(white: 0.93, alpha: 1)
        hero.heightAnchor.constraint(equalToConstant: 170).isActive = true

        chipsLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        chipsLabel.numberOfLines = 0
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        titleLabel.numberOfLines = 0
        taglineLabel.font = .systemFont(ofSize: 15)
        taglineLabel.textColor = .darkGray
        taglineLabel.numberOfLines = 0
        participantsLabel.font = .systemFont(ofSize: 13)
        participantsLabel.textColor = .gray

        resultLabel.backgroundColor = UIColor(red: 0.9, green: 0.96, blue: 0.9, alpha: 1)
        myStandingLabel.backgroundColor = UIColor(red: 0.99, green: 0.94, blue: 0.95, alpha: 1)
        reportNote.backgroundColor = UIColor(red: 1, green: 0.96, blue: 0.88, alpha: 1)
        reportNote.font = .systemFont(ofSize: 14)

        factsStack.axis = .vertical
        factsStack.spacing = 6

        let fairPlay = ArenaChallengeViewController.bodyLabel()
        fairPlay.text = ArenaText.fairPlay
        fairPlay.font = .systemFont(ofSize: 12)
        fairPlay.textColor = .gray

        updatedLabel.font = .systemFont(ofSize: 12)
        updatedLabel.textColor = .gray
        standingsEmpty.text = ArenaText.noStandings
        standingsEmpty.textColor = .gray
        standingsEmpty.isHidden = true
        standingsStack.axis = .vertical
        standingsStack.spacing = 0

        [spacer(4), hero, chipsLabel, titleLabel, taglineLabel, participantsLabel, resultLabel, myStandingLabel, reportNote,
         factsStack, sectionHeader(ArenaText.howItWorks), howLabel, sectionHeader(ArenaText.prizes), prizeLabel, badgesLabel,
         fairPlay, sectionHeader(ArenaText.standings), updatedLabel, standingsEmpty, standingsStack]
            .forEach { content.addArrangedSubview($0) }
        content.setCustomSpacing(14, after: hero)
        resultLabel.isHidden = true
        myStandingLabel.isHidden = true
        reportNote.isHidden = true

        actionBar.translatesAutoresizingMaskIntoConstraints = false
        actionBar.backgroundColor = .white
        actionBar.layer.shadowColor = UIColor.black.cgColor
        actionBar.layer.shadowOpacity = 0.08
        actionBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        actionBar.isHidden = true
        actionStatus.font = .systemFont(ofSize: 13, weight: .medium)
        actionStatus.textColor = .darkGray
        actionStatus.textAlignment = .center
        actionStatus.numberOfLines = 0
        actionButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        actionButton.layer.cornerRadius = 12
        actionButton.layer.borderColor = brandRed.cgColor
        actionButton.heightAnchor.constraint(equalToConstant: 48).isActive = true
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        let actionStack = UIStackView(arrangedSubviews: [actionStatus, actionButton])
        actionStack.axis = .vertical
        actionStack.spacing = 8
        actionStack.translatesAutoresizingMaskIntoConstraints = false
        actionBar.addSubview(actionStack)

        // The action bar sits under the scroll view and collapses when hidden; the stack ends at
        // the safe area, which already excludes the tab bar.
        let body = UIStackView(arrangedSubviews: [scroll, actionBar])
        body.axis = .vertical
        body.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(body)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)
        messageButton.translatesAutoresizingMaskIntoConstraints = false
        messageButton.titleLabel?.numberOfLines = 0
        messageButton.titleLabel?.textAlignment = .center
        messageButton.setTitleColor(.darkGray, for: .normal)
        messageButton.setTitleColor(.darkGray, for: .disabled)
        messageButton.isHidden = true
        messageButton.addTarget(self, action: #selector(retryTapped), for: .touchUpInside)
        view.addSubview(messageButton)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 6),
            back.topAnchor.constraint(equalTo: header.topAnchor),
            back.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            back.widthAnchor.constraint(equalToConstant: 40),
            back.heightAnchor.constraint(equalToConstant: 40),
            headerTitle.leadingAnchor.constraint(equalTo: back.trailingAnchor, constant: 2),
            headerTitle.centerYAnchor.constraint(equalTo: back.centerYAnchor),

            body.topAnchor.constraint(equalTo: header.bottomAnchor),
            body.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            body.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            body.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor),

            actionStack.topAnchor.constraint(equalTo: actionBar.topAnchor, constant: 10),
            actionStack.leadingAnchor.constraint(equalTo: actionBar.leadingAnchor, constant: 16),
            actionStack.trailingAnchor.constraint(equalTo: actionBar.trailingAnchor, constant: -16),
            actionStack.bottomAnchor.constraint(equalTo: actionBar.bottomAnchor, constant: -10),

            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            messageButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            messageButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
        ])
    }

    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }

    private func factRow(_ label: String, _ value: String) -> UIView {
        let l = UILabel()
        l.text = label
        l.font = .systemFont(ofSize: 14)
        l.textColor = .gray
        l.setContentHuggingPriority(.required, for: .horizontal)
        let v = UILabel()
        v.text = value
        v.font = .systemFont(ofSize: 14, weight: .semibold)
        v.textAlignment = .right
        v.numberOfLines = 0
        let row = UIStackView(arrangedSubviews: [l, v])
        row.spacing = 12
        return row
    }

    private func sectionHeader(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 17, weight: .bold)
        return l
    }

    private func spacer(_ h: CGFloat) -> UIView {
        let v = UIView()
        v.heightAnchor.constraint(equalToConstant: h).isActive = true
        return v
    }

    private static func bodyLabel() -> UILabel {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15)
        l.textColor = UIColor(white: 0.2, alpha: 1)
        l.numberOfLines = 0
        return l
    }

    private static func calloutLabel() -> UILabel {
        let l = ArenaPaddedLabel()
        l.font = .systemFont(ofSize: 15, weight: .semibold)
        l.textColor = UIColor(white: 0.15, alpha: 1)
        l.numberOfLines = 0
        l.layer.cornerRadius = 10
        l.clipsToBounds = true
        return l
    }

    private func standingRow(_ r: ArenaStandingRow, isMe: Bool, participant: ArenaParticipant?) -> UIView {
        let rank = UILabel()
        rank.text = ArenaText.rank(r.rank)
        rank.font = .systemFont(ofSize: 15, weight: .bold)
        rank.textColor = r.rank <= 3 ? brandRed : .darkGray
        rank.widthAnchor.constraint(equalToConstant: 40).isActive = true

        let avatar = UIImageView()
        avatar.backgroundColor = UIColor(white: 0.9, alpha: 1)
        avatar.layer.cornerRadius = 16
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.widthAnchor.constraint(equalToConstant: 32).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 32).isActive = true
        ArenaImageLoader.load(URL(string: "https://images.hive.blog/u/\(r.entity)/avatar/small"), into: avatar)

        let name = UILabel()
        name.text = "@" + r.entity
        name.font = .systemFont(ofSize: 15, weight: isMe ? .bold : .regular)
        let nameStack = UIStackView(arrangedSubviews: [name])
        nameStack.axis = .vertical
        // What this finisher earned, once the challenge is settled.
        if let p = participant, p.rewardAfit > 0 || !p.earnedBadges.isEmpty {
            var parts: [String] = []
            if p.rewardAfit > 0 { parts.append(ArenaText.rewardAfit(ArenaFormat.number(p.rewardAfit))) }
            if !p.earnedBadges.isEmpty { parts.append(p.earnedBadges.joined(separator: ", ")) }
            let reward = UILabel()
            reward.text = parts.joined(separator: "  ·  ")
            reward.font = .systemFont(ofSize: 12, weight: .semibold)
            reward.textColor = .primaryGreenColor()
            reward.numberOfLines = 0
            nameStack.addArrangedSubview(reward)
        }

        let score = UILabel()
        score.text = ArenaFormat.number(r.score)
        score.font = .systemFont(ofSize: 15, weight: .semibold)
        score.setContentHuggingPriority(.required, for: .horizontal)
        score.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [rank, avatar, nameStack, score])
        row.spacing = 10
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        if isMe {
            let bg = UIView()
            bg.backgroundColor = UIColor(red: 0.99, green: 0.94, blue: 0.95, alpha: 1)
            bg.layer.cornerRadius = 8
            row.insertSubview(bg, at: 0)
            bg.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bg.topAnchor.constraint(equalTo: row.topAnchor), bg.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                bg.leadingAnchor.constraint(equalTo: row.leadingAnchor), bg.trailingAnchor.constraint(equalTo: row.trailingAnchor)
            ])
        }
        row.accessibilityIdentifier = r.entity
        row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(rowTapped(_:))))
        return row
    }

    @objc private func rowTapped(_ g: UITapGestureRecognizer) {
        guard let user = g.view?.accessibilityIdentifier else { return }
        navigationController?.pushViewController(ProfileViewController(username: user, isSelf: user == me), animated: true)
    }
}

/// A label with inner padding, for the callout boxes on the challenge screen.
final class ArenaPaddedLabel: UILabel {
    private let insets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)

    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }

    override var intrinsicContentSize: CGSize {
        let s = super.intrinsicContentSize
        return CGSize(width: s.width + insets.left + insets.right, height: s.height + insets.top + insets.bottom)
    }

    override var bounds: CGRect {
        // Wrap at the padded width, or multi-line text is measured too wide and clipped.
        didSet { preferredMaxLayoutWidth = bounds.width - insets.left - insets.right }
    }
}

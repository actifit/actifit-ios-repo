//
//  ArenaViewController.swift
//  Actifit
//
//  The Arena home (Android ArenaActivity): a segmented Open | Mine | Results toggle over one
//  list of challenge cards. Open challenges are enriched from their detail call (participant
//  count and the viewer's membership); Mine and Results load the first time they are opened.
//

import UIKit

/// The logged-in Hive account, or "" for a guest.
func arenaCurrentUser() -> String {
    return User.current()?.steemit_username.byTrimming(string: "@").lowercased() ?? ""
}

/// Small in-memory cache for the challenge art and avatars (no image pod in this app).
enum ArenaImageLoader {
    private static let cache = NSCache<NSURL, UIImage>()

    static func load(_ url: URL?, into imageView: UIImageView) {
        guard let url = url else { return }
        // Remember what this view should show, so a recycled cell ignores a late image.
        imageView.accessibilityIdentifier = url.absoluteString
        if let img = cache.object(forKey: url as NSURL) {
            imageView.image = img
            return
        }
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            cache.setObject(img, forKey: url as NSURL)
            DispatchQueue.main.async {
                if imageView.accessibilityIdentifier == url.absoluteString { imageView.image = img }
            }
        }.resume()
    }
}

final class ArenaViewController: UIViewController {

    private enum Tab: Int { case open, mine, results }

    /// The settled list has no server-side paging yet, so cap what we render.
    private static let maxResults = 30

    private let headerBar = UIView()
    private let segmented = UISegmentedControl(items: [ArenaText.tabOpen, ArenaText.tabMine, ArenaText.tabResults])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .medium)
    private let refresh = UIRefreshControl()

    private var running: [ArenaChallenge] = []
    private var minePast: [ArenaChallenge] = []
    private var results: [ArenaChallenge] = []
    private var current: [ArenaChallenge] = []

    private var selectedTab: Tab = .open
    private var me = ""

    /// Bumped on every reload; a response from a superseded load is ignored.
    private var generation = 0
    private var runningLoading = false, runningLoaded = false, runningFailed = false
    private var mineLoading = false, mineLoaded = false, mineFailed = false
    private var resultsLoading = false, resultsLoaded = false, resultsFailed = false

    override var preferredStatusBarStyle: UIStatusBarStyle { return .darkContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupHeader()
        setupList()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        // The account may have changed (login, logout or switch) since the last visit.
        let user = arenaCurrentUser()
        if user != me {
            me = user
            minePast = []
            mineLoaded = false
            running = running.map { var c = $0; c.serverJoined = false; c.participantCount = nil; return c }
        }
        // Also the first load. Coming back from a challenge, membership may have changed.
        loadRunning()
    }

    // MARK: - Layout

    private func setupHeader() {
        headerBar.translatesAutoresizingMaskIntoConstraints = false
        headerBar.backgroundColor = .primaryRedColor()
        view.addSubview(headerBar)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = ArenaText.screenTitle
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.textColor = .white
        headerBar.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            headerBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: headerBar.leadingAnchor, constant: 15),
            titleLabel.topAnchor.constraint(equalTo: headerBar.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: -5)
        ])
    }

    private func setupList() {
        let subtitle = UILabel()
        subtitle.text = ArenaText.subtitle
        subtitle.font = .systemFont(ofSize: 13)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0

        segmented.selectedSegmentIndex = 0
        segmented.selectedSegmentTintColor = .primaryRedColor()
        segmented.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .selected)
        segmented.addTarget(self, action: #selector(tabChanged), for: .valueChanged)

        let top = UIStackView(arrangedSubviews: [subtitle, segmented])
        top.axis = .vertical
        top.spacing = 10
        top.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(top)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 250
        tableView.register(ArenaCardCell.self, forCellReuseIdentifier: ArenaCardCell.reuseId)
        tableView.refreshControl = refresh
        refresh.addTarget(self, action: #selector(pulled), for: .valueChanged)
        view.addSubview(tableView)

        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.font = .systemFont(ofSize: 15)
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = true
        view.addSubview(emptyLabel)

        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            top.topAnchor.constraint(equalTo: headerBar.bottomAnchor, constant: 12),
            top.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            top.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            tableView.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            emptyLabel.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 60),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 60)
        ])
    }

    // MARK: - Loading

    @objc private func tabChanged() {
        selectedTab = Tab(rawValue: segmented.selectedSegmentIndex) ?? .open
        if selectedTab == .mine && !mineLoaded && !mineLoading { loadMinePast() }
        if selectedTab == .results && !resultsLoaded && !resultsLoading { loadResults() }
        render()
    }

    @objc private func pulled() {
        switch selectedTab {
        case .open: loadRunning()
        case .mine: loadRunning(); loadMinePast()
        case .results: loadResults()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in self?.refresh.endRefreshing() }
    }

    /// Open + active challenges (the API filters one state per call), then their details.
    private func loadRunning() {
        generation += 1
        let gen = generation
        runningLoading = true
        runningFailed = false
        render()

        var merged: [ArenaChallenge] = []
        var pending = 2
        // Both halves must succeed: swapping in only the open or only the active list would
        // make the other half's challenges silently vanish.
        var allOk = true
        let onPart: ([ArenaChallenge]?) -> Void = { [weak self] list in
            guard let self = self, gen == self.generation else { return }
            if let list = list { merged += list } else { allOk = false }
            pending -= 1
            guard pending == 0 else { return }
            self.runningLoading = false
            // A failed refresh keeps the list already on screen; it is only an error state
            // when there is nothing to show.
            self.runningFailed = !allOk && !self.runningLoaded
            if allOk {
                self.runningLoaded = true
                // Soonest to close first: that is the one worth acting on now.
                merged.sort { ($0.end ?? .distantFuture) < ($1.end ?? .distantFuture) }
                // Keep what the last detail calls said until the fresh ones land, so "Joined"
                // and the counts don't blink off on every return to this screen.
                self.running = merged.map { fresh in
                    guard let old = self.running.first(where: { $0.id == fresh.id }) else { return fresh }
                    var c = fresh
                    c.participantCount = old.participantCount
                    c.serverJoined = old.serverJoined
                    return c
                }
                merged.forEach { self.enrich(gen: gen, id: $0.id) }
            }
            self.render()
        }
        ArenaAPI.listChallenges(state: "open", entity: nil, completion: onPart)
        ArenaAPI.listChallenges(state: "active", entity: nil, completion: onPart)
    }

    /// Fills in the participant count and the viewer's membership for one running card.
    private func enrich(gen: Int, id: String) {
        ArenaAPI.challenge(id: id, viewer: me) { [weak self] detail, _ in
            guard let self = self, gen == self.generation, let detail = detail,
                  let i = self.running.firstIndex(where: { $0.id == id }) else { return }
            self.running[i] = detail
            self.render()
        }
    }

    /// Settled challenges the user took part in.
    private func loadMinePast() {
        guard !me.isEmpty else {
            mineLoaded = true
            return render()
        }
        let user = me
        mineLoading = true
        mineFailed = false
        render()
        ArenaAPI.listChallenges(state: "settled", entity: user) { [weak self] list in
            guard let self = self else { return }
            self.mineLoading = false
            guard user == self.me else { return self.render() }   // account changed meanwhile
            if let list = list {
                self.mineLoaded = true
                self.minePast = Array(list.sorted { ($0.end ?? .distantPast) > ($1.end ?? .distantPast) }
                    .prefix(ArenaViewController.maxResults))
            } else {
                // Keep whatever was already loaded; a network error is not "nothing joined".
                self.mineFailed = true
            }
            self.render()
        }
    }

    private func loadResults() {
        resultsLoading = true
        resultsFailed = false
        render()
        ArenaAPI.listChallenges(state: "settled", entity: nil) { [weak self] list in
            guard let self = self else { return }
            self.resultsLoading = false
            if let list = list {
                self.resultsLoaded = true
                self.results = Array(list.sorted { ($0.end ?? .distantPast) > ($1.end ?? .distantPast) }
                    .prefix(ArenaViewController.maxResults))
            } else {
                self.resultsFailed = !self.resultsLoaded
            }
            self.render()
        }
    }

    // MARK: - Rendering

    private func render() {
        let loading: Bool
        let failed: Bool
        let emptyText: String
        switch selectedTab {
        case .open:
            current = running
            loading = runningLoading && !runningLoaded
            failed = runningFailed
            emptyText = ArenaText.emptyOpen
        case .mine:
            current = running.filter { ArenaPendingStore.membership(user: me, challenge: $0).isIn } + minePast
            // Membership comes from the per-card detail calls, so until those land an empty
            // Mine list means "not known yet", not "nothing joined".
            let membershipPending = !me.isEmpty && running.contains { $0.participantCount == nil }
            loading = (runningLoading && !runningLoaded) || mineLoading || membershipPending
            failed = runningFailed || mineFailed
            emptyText = me.isEmpty ? ArenaText.emptyMineLogin : ArenaText.emptyMine
        case .results:
            current = results
            loading = resultsLoading
            failed = resultsFailed
            emptyText = ArenaText.emptyResults
        }
        tableView.reloadData()

        let showSpinner = loading && current.isEmpty
        if showSpinner { spinner.startAnimating() } else { spinner.stopAnimating() }
        emptyLabel.isHidden = !(current.isEmpty && !showSpinner)
        emptyLabel.text = failed ? ArenaText.loadError : emptyText
    }
}

extension ArenaViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return current.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArenaCardCell.reuseId, for: indexPath) as! ArenaCardCell
        let c = current[indexPath.row]
        cell.configure(c, joined: ArenaPendingStore.membership(user: me, challenge: c).isIn)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard indexPath.row < current.count else { return }
        navigationController?.pushViewController(ArenaChallengeViewController(challengeId: current[indexPath.row].id), animated: true)
    }
}

// MARK: - Card cell

final class ArenaCardCell: UITableViewCell {

    static let reuseId = "ArenaCardCell"

    private let card = UIView()
    private let art = UIImageView()
    private let titleLabel = UILabel()
    private let taglineLabel = UILabel()
    private let metaLabel = UILabel()
    private let joinedPill = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = .white
        card.layer.cornerRadius = 14
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor(white: 0.9, alpha: 1).cgColor
        card.clipsToBounds = true
        contentView.addSubview(card)

        art.translatesAutoresizingMaskIntoConstraints = false
        art.contentMode = .scaleAspectFill
        art.clipsToBounds = true
        art.backgroundColor = UIColor(white: 0.93, alpha: 1)
        card.addSubview(art)

        joinedPill.translatesAutoresizingMaskIntoConstraints = false
        joinedPill.text = "  ✓ \(ArenaText.joinedShort)  "
        joinedPill.font = .systemFont(ofSize: 12, weight: .bold)
        joinedPill.textColor = .white
        joinedPill.backgroundColor = .primaryGreenColor()
        joinedPill.layer.cornerRadius = 10
        joinedPill.clipsToBounds = true
        card.addSubview(joinedPill)

        titleLabel.font = .systemFont(ofSize: 17, weight: .bold)
        titleLabel.numberOfLines = 2
        taglineLabel.font = .systemFont(ofSize: 14)
        taglineLabel.textColor = .darkGray
        taglineLabel.numberOfLines = 2
        metaLabel.font = .systemFont(ofSize: 12, weight: .medium)
        metaLabel.numberOfLines = 0

        let text = UIStackView(arrangedSubviews: [titleLabel, taglineLabel, metaLabel])
        text.axis = .vertical
        text.spacing = 4
        text.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(text)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            art.topAnchor.constraint(equalTo: card.topAnchor),
            art.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            art.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            art.heightAnchor.constraint(equalToConstant: 130),
            joinedPill.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            joinedPill.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -10),
            joinedPill.heightAnchor.constraint(equalToConstant: 22),
            text.topAnchor.constraint(equalTo: art.bottomAnchor, constant: 10),
            text.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            text.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            text.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ c: ArenaChallenge, joined: Bool) {
        titleLabel.text = c.title
        taglineLabel.text = c.taglineText
        var meta = [c.recurrenceText, c.timeText].filter { !$0.isEmpty }
        if let n = c.participantCount { meta.append(ArenaText.participants(n)) }
        metaLabel.text = meta.joined(separator: "  ·  ")
        metaLabel.textColor = c.endsWithinADay ? .primaryRedColor() : .gray
        joinedPill.isHidden = !joined
        art.image = nil
        ArenaImageLoader.load(c.artURL, into: art)
    }
}

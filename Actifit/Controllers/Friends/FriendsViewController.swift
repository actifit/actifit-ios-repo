//
//  FriendsViewController.swift
//  Actifit
//
//  The Friends screen (Android FriendsActivity): username search with autocomplete, then a
//  segmented Friends | Requests | Suggested toggle over one list. Shown inside the More tab.
//
//  Suggestions are ranked by activity (the owner's call: active users engage more). Two sources
//  race, recent verified reporters and Hive's recent #actifit authors, and the first to return
//  a usable candidate wins. Each suggestion is then filled in with reports, AFIT and mutual
//  friends, and further Hive pages load as the user scrolls.
//

import UIKit

final class FriendsViewController: UIViewController {

    enum Tab: Int { case friends, requests, suggested }

    private enum Item {
        case header(String)
        case row(FriendRow)
    }

    private static let suggestCap = 15
    private static let suggestHardCap = 100

    private var me = ""
    private var selectedTab: Tab = .friends

    private var friends: [FriendRow] = []
    private var received: [FriendRow] = []
    private var sent: [FriendRow] = []
    private var suggested: [FriendRow] = []
    private var items: [Item] = []
    /// Users with a write in flight; their button shows a spinner and can't be tapped twice.
    private var busy = Set<String>()

    /// Bumped per load; a response from a superseded load is ignored.
    private var loadGeneration = 0
    private var suggestGeneration = 0
    private var dataLoaded = false, dataLoading = false, dataFailed = false
    private var suggestLoaded = false, suggestLoading = false
    private var suggestSeen = Set<String>()
    private var hiveCursor: (author: String, permlink: String)?
    private var loadingMore = false, noMore = false

    // Autocomplete: my friends (cached once) plus Hive accounts by prefix.
    private var cachedFriendNames: [String]?
    private var searchGeneration = 0
    private var matches: [String] = []

    private let searchField = UITextField()
    private let matchesTable = UITableView(frame: .zero, style: .plain)
    private let segmented = UISegmentedControl(items: [FriendsText.tabFriends, FriendsText.tabRequests, FriendsText.tabSuggested])
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .medium)
    private let refresh = UIRefreshControl()
    private let loadMoreFooter = UILabel()

    override var preferredStatusBarStyle: UIStatusBarStyle { return .darkContent }

    /// Opens on a given tab (notification deep links use Requests and Friends).
    func show(tab: Tab) {
        selectedTab = tab
        if isViewLoaded {
            segmented.selectedSegmentIndex = tab.rawValue
            tabChanged()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        buildUI()
        segmented.selectedSegmentIndex = selectedTab.rawValue
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        let user = arenaCurrentUser()
        if user != me {
            // Another account: nothing from the previous one may stay on screen.
            me = user
            friends = []; received = []; sent = []; suggested = []; busy = []
            dataLoaded = false; suggestLoaded = false; suggestLoading = false; cachedFriendNames = nil
            // Drop anything still in flight for the previous account.
            suggestGeneration += 1
            searchGeneration += 1
        }
        // Also refreshes after coming back from a profile where a request may have changed.
        loadData()
    }

    // MARK: - Loading

    private func loadData() {
        guard !me.isEmpty else {
            dataLoaded = true
            return render()
        }
        loadGeneration += 1
        let gen = loadGeneration
        let user = me
        dataLoading = true
        dataFailed = false
        render()
        var friendNames: [String]?
        var requests: (received: [String], sent: [String])?
        var pending = 2
        let finish = { [weak self] in
            pending -= 1
            guard pending == 0, let self = self, gen == self.loadGeneration else { return }
            self.dataLoading = false
            guard let friendNames = friendNames, let requests = requests else {
                // Keep what is on screen; it is only an error state when there is nothing to show.
                self.dataFailed = !self.dataLoaded
                return self.render()
            }
            self.dataLoaded = true
            self.friends = friendNames.map { FriendRow(username: $0, kind: .friend) }
            self.received = requests.received.map { FriendRow(username: $0, kind: .received) }
            self.sent = requests.sent.map { FriendRow(username: $0, kind: .sent) }
            self.cachedFriendNames = friendNames.map { $0.lowercased() }
            self.pruneSuggestions()
            if self.selectedTab == .suggested && !self.suggestLoaded { self.loadSuggestions() }
            self.render()
        }
        FriendsAPI.friends(of: user) { friendNames = $0; finish() }
        FriendsAPI.requests(of: user) { requests = $0; finish() }
    }

    /// Self, friends and anyone with a pending request either way.
    private var excluded: Set<String> {
        return Set([me] + (friends + received + sent).map { $0.username })
    }

    /// Drops suggestions that became friends or pending, except rows the user just added
    /// here, which stay as "Request sent" so the list doesn't jump under their finger.
    private func pruneSuggestions() {
        let ex = excluded
        suggested.removeAll { !$0.requestSent && ex.contains($0.username) }
    }

    private func loadSuggestions() {
        suggestGeneration += 1
        let gen = suggestGeneration
        suggestLoading = true
        suggestLoaded = false
        hiveCursor = nil
        noMore = false
        loadingMore = false
        render()

        let exclude = excluded
        var resolved = false
        var pending = 2
        // First source with at least one usable candidate wins; a source whose results are all
        // excluded must not win with an empty list while the other may still deliver.
        let race: ([String]?) -> Void = { [weak self] authors in
            guard let self = self, gen == self.suggestGeneration, !resolved else { return }
            pending -= 1
            let usable = FriendsLogic.usableCandidates(authors ?? [], excluding: exclude)
            if !usable.isEmpty || pending == 0 {
                resolved = true
                self.commitSuggestions(usable, gen: gen)
            }
        }
        FriendsAPI.recentVerifiedAuthors(excluding: me) { race($0) }
        FriendsAPI.recentActifitAuthors(after: nil) { [weak self] authors, next, _ in
            if let self = self, gen == self.suggestGeneration { self.hiveCursor = next }
            race(authors)
        }
    }

    private func commitSuggestions(_ usable: [String], gen: Int) {
        let picked = Array(usable.prefix(FriendsViewController.suggestCap))
        suggestSeen = Set(picked)
        suggested = picked.map { FriendRow(username: $0, kind: .suggested) }
        suggestLoaded = true
        suggestLoading = false
        render()
        picked.forEach { enrich($0, gen: gen) }
    }

    private func loadMoreSuggestions() {
        guard selectedTab == .suggested, suggestLoaded, !loadingMore, !noMore, let cursor = hiveCursor else { return }
        loadingMore = true
        updateFooter()
        let gen = suggestGeneration
        let exclude = excluded
        FriendsAPI.recentActifitAuthors(after: cursor) { [weak self] authors, next, pageSize in
            guard let self = self, gen == self.suggestGeneration else { return }
            self.loadingMore = false
            guard let authors = authors else { return self.updateFooter() }   // give up quietly
            var fresh: [String] = []
            for a in FriendsLogic.usableCandidates(authors, excluding: exclude) where !self.suggestSeen.contains(a) {
                if self.suggested.count + fresh.count >= FriendsViewController.suggestHardCap { break }
                self.suggestSeen.insert(a)
                fresh.append(a)
            }
            self.hiveCursor = next
            // A page with nothing new, or the last page, ends the paging.
            if fresh.isEmpty || pageSize < 2 { self.noMore = true }
            self.suggested += fresh.map { FriendRow(username: $0, kind: .suggested) }
            self.render()
            fresh.forEach { self.enrich($0, gen: gen) }
        }
    }

    /// Reports, AFIT and mutual friends for one suggestion; a failed part stays nil and is omitted.
    private func enrich(_ user: String, gen: Int) {
        let myFriends = friends.map { $0.username }
        var reports: Int?, afit: Double?, mutual: Int?
        var pending = 3
        let finish = { [weak self] in
            pending -= 1
            guard pending == 0, let self = self, gen == self.suggestGeneration,
                  let i = self.suggested.firstIndex(where: { $0.username == user }) else { return }
            self.suggested[i].reports = reports
            self.suggested[i].afit = afit
            self.suggested[i].mutual = mutual
            self.suggested[i].enriched = true
            if self.selectedTab == .suggested { self.render() }
        }
        FriendsAPI.rewardedReports(of: user) { reports = $0; finish() }
        FriendsAPI.afitBalance(of: user) { afit = $0; finish() }
        FriendsAPI.friends(of: user) { theirs in
            mutual = theirs.map { FriendsLogic.mutualFriends(mine: myFriends, theirs: $0).count }
            finish()
        }
    }

    // MARK: - Actions

    private func act(on row: FriendRow) {
        guard !me.isEmpty else { return showToast(message: FriendsText.loginNeeded, width: 280) }
        switch row.kind {
        case .friend:
            let alert = UIAlertController(title: nil, message: FriendsText.confirmUnfriend(row.username), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: FriendsText.unfriend, style: .destructive) { [weak self] _ in
                self?.perform(.unfriend, on: row)
            })
            alert.addAction(UIAlertAction(title: FriendsText.close, style: .cancel))
            present(alert, animated: true)
        case .received: perform(.accept, on: row)
        case .sent: perform(.cancelRequest, on: row)
        case .suggested: if !row.requestSent { perform(.add, on: row) }
        }
    }

    private func perform(_ action: FriendsAPI.Action, on row: FriendRow) {
        let user = row.username
        busy.insert(user)
        render()
        FriendsAPI.perform(action, me: me, target: user) { [weak self] ok in
            guard let self = self else { return }
            self.busy.remove(user)
            if !ok {
                self.showToast(message: FriendsText.failed, width: 300)
                return self.render()
            }
            if action == .add, let i = self.suggested.firstIndex(where: { $0.username == user }) {
                // Flip the row in place; reloading the suggestions would lose the scroll position.
                self.suggested[i].requestSent = true
                self.showToast(message: FriendsText.requestSent, width: 240)
            } else {
                self.showToast(message: FriendsText.done, width: 160)
            }
            self.loadData()
        }
    }

    private func submitSearch(_ text: String) {
        let handle = FriendsLogic.normalize(text)
        guard FriendsLogic.isValidUsername(handle) else { return showToast(message: FriendsText.searchInvalid, width: 300) }
        guard handle != me else { return showToast(message: FriendsText.searchSelf, width: 160) }
        searchField.text = ""
        searchField.resignFirstResponder()
        showMatches([])
        openProfile(handle)
    }

    private func openProfile(_ user: String) {
        navigationController?.pushViewController(ProfileViewController(username: user, isSelf: user == me), animated: true)
    }

    @objc private func searchChanged() {
        let prefix = FriendsLogic.searchPrefix(searchField.text ?? "")
        searchGeneration += 1
        let gen = searchGeneration
        guard !prefix.isEmpty else { return showMatches([]) }
        let own = (cachedFriendNames ?? []).filter { $0.hasPrefix(prefix) }
        showMatches(Array(own.prefix(10)))
        // Debounce typing a little before asking Hive.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            guard let self = self, gen == self.searchGeneration else { return }
            FriendsAPI.lookupAccounts(prefix: prefix, limit: 10) { [weak self] accounts in
                guard let self = self, gen == self.searchGeneration else { return }
                var merged = own
                for a in accounts where a.hasPrefix(prefix) && !merged.contains(a) { merged.append(a) }
                self.showMatches(Array(merged.prefix(10)))
            }
        }
    }

    private func showMatches(_ list: [String]) {
        matches = list
        matchesTable.reloadData()
        matchesTable.isHidden = list.isEmpty || !searchField.isFirstResponder
    }

    // MARK: - Rendering

    @objc private func tabChanged() {
        selectedTab = Tab(rawValue: segmented.selectedSegmentIndex) ?? .friends
        if selectedTab == .suggested && !suggestLoaded && !suggestLoading && dataLoaded { loadSuggestions() }
        render()
    }

    @objc private func pulled() {
        loadData()
        if selectedTab == .suggested && dataLoaded { loadSuggestions() }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in self?.refresh.endRefreshing() }
    }

    private func render() {
        segmented.setTitle(FriendsText.requestsTab(received.count), forSegmentAt: Tab.requests.rawValue)
        let loading: Bool
        let ready: Bool
        let empty: String
        switch selectedTab {
        case .friends:
            items = friends.map { .row($0) }
            loading = dataLoading; ready = dataLoaded; empty = FriendsText.emptyFriends
        case .requests:
            items = []
            if !received.isEmpty { items += [.header(FriendsText.received)] + received.map { .row($0) } }
            if !sent.isEmpty { items += [.header(FriendsText.sent)] + sent.map { .row($0) } }
            loading = dataLoading; ready = dataLoaded; empty = FriendsText.emptyRequests
        case .suggested:
            items = suggested.map { .row($0) }
            loading = suggestLoading || (!dataLoaded && dataLoading); ready = suggestLoaded; empty = FriendsText.emptySuggested
        }
        tableView.reloadData()
        let showSpinner = loading && items.isEmpty
        if showSpinner { spinner.startAnimating() } else { spinner.stopAnimating() }
        // Suggestions wait for the friend lists, so their failure is Suggested's failure too.
        let failed = dataFailed && (selectedTab != .suggested || !suggestLoaded)
        emptyLabel.text = me.isEmpty ? FriendsText.loginNeeded : (failed ? FriendsText.loadError : empty)
        emptyLabel.isHidden = !items.isEmpty || showSpinner || !(ready || failed || me.isEmpty)
        updateFooter()
    }

    private func updateFooter() {
        let show = selectedTab == .suggested && loadingMore
        loadMoreFooter.frame.size.height = show ? 44 : 0
        loadMoreFooter.isHidden = !show
        tableView.tableFooterView = loadMoreFooter
    }

    // MARK: - Layout

    private func buildUI() {
        let header = UIView()
        header.translatesAutoresizingMaskIntoConstraints = false
        header.backgroundColor = .primaryRedColor()
        view.addSubview(header)
        let title = UILabel()
        title.translatesAutoresizingMaskIntoConstraints = false
        title.text = FriendsText.title
        title.font = .systemFont(ofSize: 18, weight: .bold)
        title.textColor = .white
        header.addSubview(title)

        searchField.placeholder = FriendsText.searchHint
        searchField.borderStyle = .roundedRect
        searchField.autocapitalizationType = .none
        searchField.autocorrectionType = .no
        searchField.returnKeyType = .search
        searchField.clearButtonMode = .whileEditing
        searchField.delegate = self
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
        searchField.accessibilityIdentifier = "friendsSearch"
        let go = UIButton(type: .system)
        go.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        go.tintColor = .white
        go.backgroundColor = .primaryRedColor()
        go.layer.cornerRadius = 8
        go.widthAnchor.constraint(equalToConstant: 44).isActive = true
        go.accessibilityLabel = "Search"
        go.addTarget(self, action: #selector(goTapped), for: .touchUpInside)
        let searchRow = UIStackView(arrangedSubviews: [searchField, go])
        searchRow.spacing = 8

        segmented.selectedSegmentTintColor = .primaryRedColor()
        segmented.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: UIColor.white], for: .selected)
        segmented.addTarget(self, action: #selector(tabChanged), for: .valueChanged)

        let top = UIStackView(arrangedSubviews: [searchRow, segmented])
        top.axis = .vertical
        top.spacing = 10
        top.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(top)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 72
        tableView.keyboardDismissMode = .onDrag
        tableView.register(FriendCell.self, forCellReuseIdentifier: FriendCell.reuseId)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "header")
        tableView.refreshControl = refresh
        refresh.addTarget(self, action: #selector(pulled), for: .valueChanged)
        view.addSubview(tableView)

        loadMoreFooter.text = FriendsText.loadingMore
        loadMoreFooter.textAlignment = .center
        loadMoreFooter.font = .systemFont(ofSize: 13)
        loadMoreFooter.textColor = .gray
        loadMoreFooter.frame = CGRect(x: 0, y: 0, width: 0, height: 0)

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

        // Autocomplete dropdown floats over the list, under the search field.
        matchesTable.translatesAutoresizingMaskIntoConstraints = false
        matchesTable.dataSource = self
        matchesTable.delegate = self
        matchesTable.isHidden = true
        matchesTable.layer.borderWidth = 1
        matchesTable.layer.borderColor = UIColor(white: 0.85, alpha: 1).cgColor
        matchesTable.layer.cornerRadius = 8
        matchesTable.register(UITableViewCell.self, forCellReuseIdentifier: "match")
        matchesTable.accessibilityIdentifier = "friendsMatches"
        view.addSubview(matchesTable)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            title.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 15),
            title.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            title.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -5),

            top.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            top.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            top.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 40),

            tableView.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            emptyLabel.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 60),
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: top.bottomAnchor, constant: 60),

            matchesTable.topAnchor.constraint(equalTo: searchRow.bottomAnchor, constant: 2),
            matchesTable.leadingAnchor.constraint(equalTo: searchField.leadingAnchor),
            matchesTable.trailingAnchor.constraint(equalTo: searchField.trailingAnchor),
            matchesTable.heightAnchor.constraint(equalToConstant: 220)
        ])
    }

    @objc private func goTapped() { submitSearch(searchField.text ?? "") }
}

extension FriendsViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        submitSearch(textField.text ?? "")
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        matchesTable.isHidden = true
    }
}

extension FriendsViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableView === matchesTable ? matches.count : items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView === matchesTable {
            let cell = tableView.dequeueReusableCell(withIdentifier: "match", for: indexPath)
            cell.textLabel?.text = "@" + matches[indexPath.row]
            cell.textLabel?.font = .systemFont(ofSize: 15)
            return cell
        }
        switch items[indexPath.row] {
        case .header(let title):
            let cell = tableView.dequeueReusableCell(withIdentifier: "header", for: indexPath)
            cell.textLabel?.text = title
            cell.textLabel?.font = .systemFont(ofSize: 12, weight: .bold)
            cell.textLabel?.textColor = .gray
            cell.selectionStyle = .none
            return cell
        case .row(let row):
            let cell = tableView.dequeueReusableCell(withIdentifier: FriendCell.reuseId, for: indexPath) as! FriendCell
            cell.configure(row, busy: busy.contains(row.username)) { [weak self] in self?.act(on: row) }
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if tableView === matchesTable {
            return submitSearch(matches[indexPath.row])
        }
        if case .row(let row) = items[indexPath.row] { openProfile(row.username) }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === tableView else { return }
        let nearBottom = scrollView.contentOffset.y + scrollView.bounds.height > scrollView.contentSize.height - 140
        if nearBottom && scrollView.contentSize.height > 0 { loadMoreSuggestions() }
    }
}

// MARK: - Row

final class FriendCell: UITableViewCell {

    static let reuseId = "FriendCell"

    private let avatar = UIImageView()
    private let handle = UILabel()
    private let stats = UILabel()
    private let mutualLabel = UILabel()
    private let action = UIButton(type: .system)
    private let actionSpinner = UIActivityIndicatorView(activityIndicatorStyle: .medium)
    private var onAction: (() -> Void)?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        avatar.backgroundColor = UIColor(white: 0.9, alpha: 1)
        avatar.layer.cornerRadius = 22
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.widthAnchor.constraint(equalToConstant: 44).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 44).isActive = true
        handle.font = .systemFont(ofSize: 16, weight: .semibold)
        stats.font = .systemFont(ofSize: 13)
        stats.textColor = .gray
        stats.numberOfLines = 0
        mutualLabel.font = .systemFont(ofSize: 13)
        mutualLabel.textColor = .gray
        let text = UIStackView(arrangedSubviews: [handle, stats, mutualLabel])
        text.axis = .vertical
        text.spacing = 2

        action.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        action.setTitleColor(.white, for: .normal)
        action.layer.cornerRadius = 8
        action.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        action.setContentHuggingPriority(.required, for: .horizontal)
        action.setContentCompressionResistancePriority(.required, for: .horizontal)
        action.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        actionSpinner.hidesWhenStopped = true

        let rowStack = UIStackView(arrangedSubviews: [avatar, text, actionSpinner, action])
        rowStack.spacing = 12
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            rowStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            rowStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            rowStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(_ row: FriendRow, busy: Bool, onAction: @escaping () -> Void) {
        self.onAction = onAction

        handle.text = "@" + row.username
        avatar.image = nil
        ArenaImageLoader.load(URL(string: "https://images.hive.blog/u/\(row.username)/avatar/small"), into: avatar)

        // Suggestions carry two stat lines that fill in once enrichment lands.
        if row.kind == .suggested {
            stats.text = row.enriched ? (FriendsLogic.primaryStats(row) ?? "") : FriendsText.statsLoading
            stats.isHidden = stats.text?.isEmpty ?? true
            if let m = row.mutual, m > 0, row.enriched {
                mutualLabel.text = FriendsText.mutual(m)
                mutualLabel.isHidden = false
            } else {
                mutualLabel.isHidden = true
            }
        } else {
            stats.isHidden = true
            mutualLabel.isHidden = true
        }

        let title: String
        let color: UIColor
        switch row.kind {
        case .received: title = FriendsText.accept; color = .primaryGreenColor()
        case .sent: title = FriendsText.cancel; color = .gray
        case .friend: title = FriendsText.unfriend; color = .gray
        case .suggested:
            title = row.requestSent ? FriendsText.requestSentShort : FriendsText.add
            color = row.requestSent ? UIColor(white: 0.7, alpha: 1) : .primaryRedColor()
        }
        action.setTitle(title, for: .normal)
        action.backgroundColor = color
        action.isEnabled = !(row.kind == .suggested && row.requestSent)
        action.accessibilityLabel = title + " @" + row.username
        action.isHidden = busy
        if busy { actionSpinner.startAnimating() } else { actionSpinner.stopAnimating() }
    }

    @objc private func actionTapped() { onAction?() }
}

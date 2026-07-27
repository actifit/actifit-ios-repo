//
//  ProfileViewController.swift
//  Actifit
//
//  Native "Living Fitness Identity" profile — iOS port of Android ProfileActivity.
//  Reuses the ported AuraView + CompanionUtil. Replaces the old web-profile
//  Safari open. Self profile pulls today/streak/lifetime from the local Realm
//  activity store; rank + recent reports come from the Actifit API.
//

import UIKit

final class ProfileViewController: UIViewController {

    private let username: String
    private let isSelf: Bool

    // MARK: Data
    private var rankValue: String = "—"
    private var companionIndex = 0
    private var todaySteps = 0
    private var streak = 0
    private var lifetimeSteps = 0
    private var latestSteps = 0
    private var reportsCount = 0
    private struct RecentReport { let title: String; let steps: Int; let author: String; let permlink: String }
    private var recent: [RecentReport] = []

    // MARK: Tokens
    private let brandRed = UIColor.primaryRedColor()
    private let pageBg = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
    private let textSecondary = UIColor(red: 117/255, green: 117/255, blue: 117/255, alpha: 1)
    private let onSurface = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
    private let separator = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1)

    // MARK: UI
    private let auraView = AuraView()
    private let avatarView = UIImageView()
    private let metricsLegend = UILabel()
    private let tierLabel = UILabel()
    private let usernameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let companionHint = UILabel()
    private let tile1 = ProfileViewController.statTile()
    private let tile2 = ProfileViewController.statTile()
    private let tile3 = ProfileViewController.statTile()
    private let recentStack = UIStackView()
    private let recentEmpty = UILabel()

    init(username: String, isSelf: Bool) {
        self.username = username.byTrimming(string: "@").lowercased()
        self.isSelf = isSelf
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = pageBg
        buildUI()
        if isSelf { computeSelfStats() }
        applyHero()
        loadRank()
        loadRecentActivity()
        loadAvatar()
    }

    // MARK: - Layout

    private func buildUI() {
        // Header bar
        let header = UIView()
        header.backgroundColor = .white
        header.translatesAutoresizingMaskIntoConstraints = false
        let back = UIButton(type: .system)
        back.setTitle("‹", for: .normal)
        back.titleLabel?.font = .systemFont(ofSize: 30, weight: .bold)
        back.setTitleColor(brandRed, for: .normal)
        back.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false
        let title = UILabel()
        title.text = "Profile"; title.font = .systemFont(ofSize: 20, weight: .bold); title.textColor = brandRed
        title.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(back); header.addSubview(title)
        let sep = UIView(); sep.backgroundColor = separator; sep.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(sep)
        view.addSubview(header)

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)

        let content = UIStackView()
        content.axis = .vertical; content.spacing = 12; content.alignment = .fill
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 40, right: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            back.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -10),
            back.widthAnchor.constraint(equalToConstant: 40),
            title.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            title.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            sep.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1),
            scroll.topAnchor.constraint(equalTo: header.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        // Hero: aura rings + companion, avatar badge overlaid lower-right
        let heroContainer = UIView()
        heroContainer.translatesAutoresizingMaskIntoConstraints = false
        auraView.translatesAutoresizingMaskIntoConstraints = false
        heroContainer.addSubview(auraView)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true
        avatarView.layer.cornerRadius = 23
        avatarView.layer.borderWidth = 2
        avatarView.layer.borderColor = UIColor.white.cgColor
        avatarView.backgroundColor = separator
        heroContainer.addSubview(avatarView)
        NSLayoutConstraint.activate([
            auraView.topAnchor.constraint(equalTo: heroContainer.topAnchor),
            auraView.bottomAnchor.constraint(equalTo: heroContainer.bottomAnchor),
            auraView.centerXAnchor.constraint(equalTo: heroContainer.centerXAnchor),
            auraView.widthAnchor.constraint(equalToConstant: 240),
            auraView.heightAnchor.constraint(equalToConstant: 240),
            avatarView.widthAnchor.constraint(equalToConstant: 46),
            avatarView.heightAnchor.constraint(equalToConstant: 46),
            avatarView.trailingAnchor.constraint(equalTo: auraView.trailingAnchor, constant: -18),
            avatarView.bottomAnchor.constraint(equalTo: auraView.bottomAnchor, constant: -18)
        ])
        if isSelf {
            auraView.isUserInteractionEnabled = true
            auraView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(pickCompanion)))
        }

        metricsLegend.font = .systemFont(ofSize: 15); metricsLegend.textColor = textSecondary
        metricsLegend.textAlignment = .center; metricsLegend.numberOfLines = 0

        tierLabel.font = .systemFont(ofSize: 15, weight: .bold); tierLabel.textAlignment = .center
        tierLabel.numberOfLines = 0

        usernameLabel.font = .systemFont(ofSize: 24, weight: .bold); usernameLabel.textColor = onSurface
        usernameLabel.textAlignment = .center; usernameLabel.text = "@\(username)"

        subtitleLabel.font = .systemFont(ofSize: 16); subtitleLabel.textColor = textSecondary
        subtitleLabel.textAlignment = .center; subtitleLabel.text = "Rank —"

        companionHint.font = .systemFont(ofSize: 11); companionHint.textColor = textSecondary
        companionHint.textAlignment = .center; companionHint.text = "✎ Tap to change animal"
        companionHint.isHidden = !isSelf

        let tilesRow = UIStackView(arrangedSubviews: [tile1.container, tile2.container, tile3.container])
        tilesRow.axis = .horizontal; tilesRow.distribution = .fillEqually; tilesRow.spacing = 8

        // Share (self only)
        let share = UIButton(type: .system)
        share.setTitle("Share my card", for: .normal)
        share.setTitleColor(.white, for: .normal)
        share.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        share.backgroundColor = brandRed
        share.layer.cornerRadius = 12
        share.heightAnchor.constraint(equalToConstant: 48).isActive = true
        share.addTarget(self, action: #selector(shareCard), for: .touchUpInside)
        share.isHidden = !isSelf

        let recentHeader = UILabel()
        recentHeader.text = "Recent activity"; recentHeader.font = .systemFont(ofSize: 16, weight: .bold)
        recentHeader.textColor = onSurface

        recentStack.axis = .vertical; recentStack.spacing = 0
        recentEmpty.text = "No recent activity reports yet."
        recentEmpty.font = .systemFont(ofSize: 14); recentEmpty.textColor = textSecondary
        recentEmpty.textAlignment = .center; recentEmpty.isHidden = true

        [heroContainer, metricsLegend, tierLabel, usernameLabel, subtitleLabel, companionHint,
         spacer(8), tilesRow, share, spacer(8), recentHeader, recentCard()].forEach { content.addArrangedSubview($0) }
        content.setCustomSpacing(4, after: tierLabel)
        content.setCustomSpacing(2, after: usernameLabel)
    }

    private func recentCard() -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        let v = UIStackView(arrangedSubviews: [recentStack, recentEmpty])
        v.axis = .vertical
        v.isLayoutMarginsRelativeArrangement = true
        v.layoutMargins = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        v.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: card.topAnchor),
            v.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func spacer(_ h: CGFloat) -> UIView {
        let v = UIView(); v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: h).isActive = true
        return v
    }

    private struct Tile { let container: UIView; let value: UILabel; let label: UILabel }
    private static func statTile() -> Tile {
        let value = UILabel(); value.font = .systemFont(ofSize: 20, weight: .bold)
        value.textColor = UIColor(red: 0.13, green: 0.13, blue: 0.13, alpha: 1)
        value.adjustsFontSizeToFitWidth = true; value.minimumScaleFactor = 0.6
        value.textAlignment = .center; value.text = "—"
        let label = UILabel(); label.font = .systemFont(ofSize: 13)
        label.textColor = UIColor(red: 117/255, green: 117/255, blue: 117/255, alpha: 1)
        label.textAlignment = .center; label.numberOfLines = 2
        let stack = UIStackView(arrangedSubviews: [value, label]); stack.axis = .vertical; stack.spacing = 4
        stack.alignment = .center
        let container = UIView()
        container.backgroundColor = .white
        container.layer.cornerRadius = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 96),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8)
        ])
        return Tile(container: container, value: value, label: label)
    }

    // MARK: - Hero / stats

    private func applyHero() {
        companionIndex = CompanionUtil.resolveCompanion(username: username, isSelf: isSelf)
        let steps = isSelf ? todaySteps : latestSteps
        let level = isSelf ? CompanionUtil.levelFromStreak(streak) : CompanionUtil.levelFromRank(rankValue)
        let hour = Calendar.current.component(.hour, from: Date())
        let wilting = CompanionUtil.isWilting(streak: streak, todaySteps: steps, hourOfDay: hour)
        let distKm = Double(steps) * 0.762 / 1000.0
        let cal = Double(steps) * 0.04
        auraView.setCompanion(companionIndex)
        auraView.setActivityRings(steps: CGFloat(steps) / 10000.0,
                                  distance: CGFloat(distKm) / 8.0,
                                  calories: CGFloat(cal) / 500.0,
                                  level: level, wilting: wilting)
        metricsLegend.text = "🚶 \(compact(steps)) steps · 📏 \(String(format: "%.2f", distKm)) km · 🔥 \(Int(cal)) kcal"
        let name = CompanionUtil.name(companionIndex)
        tierLabel.attributedText = NSAttributedString(
            string: "\(CompanionUtil.emoji(companionIndex)) \(name.uppercased()) · \(CompanionUtil.tierName(level).uppercased())",
            attributes: [.kern: 1.5, .foregroundColor: CompanionUtil.color(companionIndex),
                         .font: UIFont.systemFont(ofSize: 15, weight: .bold)])
        applyTiles()
    }

    private func applyTiles() {
        if isSelf {
            tile1.value.text = compact(todaySteps); tile1.label.text = "Today"
            tile2.value.text = "\(streak)"; tile2.label.text = "Day streak"
            tile3.value.text = compact(lifetimeSteps); tile3.label.text = "Lifetime steps"
        } else {
            tile1.value.text = compact(latestSteps); tile1.label.text = "Latest"
            tile2.value.text = rankValue; tile2.label.text = "Rank"
            tile3.value.text = "\(reportsCount)"; tile3.label.text = "Reports"
        }
    }

    private func computeSelfStats() {
        let activities = Activity.all()
        lifetimeSteps = activities.reduce(0) { $0 + $1.steps }
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyyMMdd"
        var byDay: [String: Int] = [:]
        for a in activities { let k = f.string(from: a.date); byDay[k] = max(byDay[k] ?? 0, a.steps) }
        let cal = Calendar.current
        todaySteps = byDay[f.string(from: Date())] ?? 0
        // consecutive days (ending today, or yesterday if today not yet reached) with >= 5000
        var count = 0
        var day = Date()
        for i in 0..<366 {
            let s = byDay[f.string(from: day)] ?? 0
            if s >= CompanionUtil.ACTIVE_THRESHOLD {
                count += 1
            } else if i == 0 {
                // today may be incomplete — don't break the streak on day 0
            } else {
                break
            }
            day = cal.date(byAdding: .day, value: -1, to: day) ?? day
        }
        streak = count
    }

    // MARK: - Networking

    private func loadRank() {
        API().getRank(username: username, completion: { [weak self] response, _ in
            guard let self = self, let str = response as? String,
                  let data = str.data(using: .utf8),
                  let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let rank = json["user_rank"] else { return }
            DispatchQueue.main.async {
                self.rankValue = "\(rank)"
                self.subtitleLabel.text = "Rank \(self.rankValue)"
                if !self.isSelf { self.applyHero() } else { self.applyTiles() }
            }
        }, failure: { _ in })
    }

    private func loadRecentActivity() {
        API().getTrackedActivity(username: username, completion: { [weak self] response, _ in
            guard let self = self, let str = response as? String,
                  let data = str.data(using: .utf8),
                  let arr = (try? JSONSerialization.jsonObject(with: data)) as? [[String: Any]] else { return }
            var rows: [RecentReport] = []
            for post in arr.prefix(12) {
                let author = post["author"] as? String ?? self.username
                let permlink = post["permlink"] as? String ?? ""
                let meta = post["json_metadata"] as? [String: Any] ?? [:]
                let steps = self.firstInt(meta["step_count"])
                let type = self.firstString(meta["activity_type"]) ?? "Activity"
                let dateStr = self.firstString(meta["activityDate"]) ?? ""
                rows.append(RecentReport(title: "\(type) · \(self.prettyDate(dateStr))", steps: steps, author: author, permlink: permlink))
            }
            DispatchQueue.main.async {
                self.reportsCount = arr.count
                self.latestSteps = rows.first?.steps ?? 0
                self.recent = rows
                self.renderRecent()
                if !self.isSelf { self.applyHero() }
            }
        }, failure: { _ in })
    }

    private func loadAvatar() {
        guard let url = URL(string: "https://images.hive.blog/u/\(username)/avatar") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.avatarView.image = img }
        }.resume()
    }

    private func renderRecent() {
        recentStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        recentEmpty.isHidden = !recent.isEmpty
        for (i, r) in recent.enumerated() {
            recentStack.addArrangedSubview(recentRow(r))
            if i < recent.count - 1 {
                let line = UIView(); line.backgroundColor = separator
                line.heightAnchor.constraint(equalToConstant: 1).isActive = true
                recentStack.addArrangedSubview(line)
            }
        }
    }

    private func recentRow(_ r: RecentReport) -> UIView {
        let left = UILabel(); left.text = r.title; left.font = .systemFont(ofSize: 14); left.textColor = onSurface
        left.numberOfLines = 2
        let right = UILabel(); right.text = r.steps > 0 ? NumberFormatter.localizedString(from: NSNumber(value: r.steps), number: .decimal) : "—"
        right.font = .systemFont(ofSize: 14, weight: .bold); right.textColor = brandRed
        right.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [left, right])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        if !r.permlink.isEmpty {
            row.isUserInteractionEnabled = true
            row.tag = recent.firstIndex(where: { $0.permlink == r.permlink }) ?? 0
            row.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openReport(_:))))
        }
        return row
    }

    // MARK: - Helpers

    private func compact(_ n: Int) -> String {
        if n >= 1_000_000 { return String(format: "%.1fM", Double(n) / 1_000_000) }
        if n >= 1_000 { return String(format: "%.1fk", Double(n) / 1_000) }
        return "\(n)"
    }
    private func firstInt(_ v: Any?) -> Int {
        if let i = v as? Int { return i }
        if let s = v as? String { return Int(s) ?? 0 }
        if let a = v as? [Any] { return firstInt(a.first) }
        if let d = v as? Double { return Int(d) }
        return 0
    }
    private func firstString(_ v: Any?) -> String? {
        if let s = v as? String { return s }
        if let a = v as? [Any] { return firstString(a.first) }
        if let i = v as? Int { return "\(i)" }
        return nil
    }
    private func prettyDate(_ yyyymmdd: String) -> String {
        let inF = DateFormatter(); inF.locale = Locale(identifier: "en_US_POSIX"); inF.dateFormat = "yyyyMMdd"
        guard let d = inF.date(from: yyyymmdd.replacingOccurrences(of: "-", with: "")) else { return yyyymmdd }
        let outF = DateFormatter(); outF.dateFormat = "MMM d, yyyy"
        return outF.string(from: d)
    }

    // MARK: - Actions

    @objc private func closeTapped() {
        if let nav = navigationController, nav.viewControllers.first != self { nav.popViewController(animated: true) }
        else { dismiss(animated: true) }
    }

    @objc private func openReport(_ g: UITapGestureRecognizer) {
        let idx = g.view?.tag ?? 0
        guard idx < recent.count else { return }
        let r = recent[idx]
        if let url = URL(string: "https://actifit.io/@\(r.author)/\(r.permlink)") { UIApplication.shared.open(url) }
    }

    @objc private func shareCard() {
        let text = "I've done \(todaySteps) steps today on Actifit! 🏃 Rank \(rankValue)."
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    @objc private func pickCompanion() {
        let sheet = UIAlertController(title: "Choose your spirit animal", message: nil, preferredStyle: .actionSheet)
        for i in 0..<CompanionUtil.companionCount {
            sheet.addAction(UIAlertAction(title: "\(CompanionUtil.emoji(i)) \(CompanionUtil.name(i))", style: .default) { [weak self] _ in
                UserDefaults.standard.set(i, forKey: CompanionUtil.PREF_COMPANION)
                self?.applyHero()
            })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        sheet.popoverPresentationController?.sourceView = auraView
        present(sheet, animated: true)
    }
}

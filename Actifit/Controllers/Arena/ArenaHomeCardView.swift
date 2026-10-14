//
//  ArenaHomeCardView.swift
//  Actifit
//
//  The Arena card on the dashboard (Android ArenaHomeCard). For a user who is in a challenge
//  it shows the one closing soonest with their rank and score; otherwise it invites them to
//  the open ones.
//
//  A successful load is cached for a couple of minutes so returning to the dashboard doesn't
//  refetch every time. A load in which any call failed is shown but never cached, so a
//  network error can't pin "not in a challenge" on a participant.
//

import UIKit

final class ArenaHomeCardView: UIView {

    private static let cacheTTL: TimeInterval = 2 * 60
    // After a join/leave the backend needs a few blocks to index it; refetch often until then.
    private static let settlingTTL: TimeInterval = 10
    private static let settlingWindow: TimeInterval = 60
    // `entity=` also returns challenges the user has since left, so candidates are confirmed
    // against the detail call. Bounded, to cap the requests per load.
    private static let maxCandidates = 8

    private struct State {
        var user = ""
        var loadedAt = Date()
        var complete = true        // false once any call in the load failed
        var joined: ArenaChallenge?
        var rank = 0               // 0 = not on the board (or the board couldn't be read)
        var score: Double = 0
        var openCount = 0
    }

    private static var cache: State?
    private static var settlingUntil = Date.distantPast
    // Bumped per load and on invalidate; a chain started earlier must not publish its result.
    private static var generation = 0

    /// Call when the user's membership changed (a join or leave was sent).
    static func invalidate() {
        cache = nil
        generation += 1
        settlingUntil = Date().addingTimeInterval(settlingWindow)
    }

    /// True when the last successful load found `user` in a running challenge.
    static func inChallenge(_ user: String) -> Bool {
        guard let c = cache else { return false }
        return c.joined != nil && c.user == user
    }

    var onOpenChallenge: ((String) -> Void)?
    var onOpenArena: (() -> Void)?

    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let timeLabel = UILabel()
    private var shown: State?

    override init(frame: CGRect) {
        super.init(frame: frame)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = .white
        layer.cornerRadius = 16
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.08
        layer.shadowRadius = 5
        layer.shadowOffset = CGSize(width: 0, height: 2)
        isHidden = true

        let icon = UIImageView(image: UIImage(systemName: "trophy.fill"))
        icon.tintColor = .primaryRedColor()
        icon.contentMode = .scaleAspectFit
        icon.widthAnchor.constraint(equalToConstant: 28).isActive = true
        icon.heightAnchor.constraint(equalToConstant: 28).isActive = true

        let eyebrow = UILabel()
        eyebrow.text = ArenaText.title.uppercased()
        eyebrow.font = .systemFont(ofSize: 11, weight: .bold)
        eyebrow.textColor = .primaryRedColor()
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        titleLabel.textColor = UIColor(white: 0.13, alpha: 1)
        titleLabel.numberOfLines = 2
        statusLabel.font = .systemFont(ofSize: 14)
        statusLabel.textColor = .darkGray
        statusLabel.numberOfLines = 0
        timeLabel.font = .systemFont(ofSize: 12, weight: .semibold)

        let text = UIStackView(arrangedSubviews: [eyebrow, titleLabel, statusLabel, timeLabel])
        text.axis = .vertical
        text.spacing = 3
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .lightGray
        chevron.setContentHuggingPriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [icon, text, chevron])
        row.spacing = 12
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 14)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        accessibilityIdentifier = "arenaHomeCard"
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped)))
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    @objc private func tapped() {
        if let id = shown?.joined?.id { onOpenChallenge?(id) } else { onOpenArena?() }
    }

    func refresh(user: String) {
        let now = Date()
        let ttl = now < ArenaHomeCardView.settlingUntil ? ArenaHomeCardView.settlingTTL : ArenaHomeCardView.cacheTTL
        if let c = ArenaHomeCardView.cache, c.user == user, now.timeIntervalSince(c.loadedAt) < ttl {
            return bind(c)
        }
        // Never leave another account's challenge on screen while this one loads.
        if let shown = shown, shown.user != user {
            self.shown = nil
            isHidden = true
        }
        if let c = ArenaHomeCardView.cache, c.user != user { ArenaHomeCardView.cache = nil }

        ArenaHomeCardView.generation += 1
        let gen = ArenaHomeCardView.generation
        var s = State()
        s.user = user
        guard !user.isEmpty else { return loadOpenCount(s, gen) }

        // The API filters one state per call; a started challenge may be "active".
        var mine: [ArenaChallenge] = []
        var pending = 2
        let onPart: ([ArenaChallenge]?) -> Void = { [weak self] list in
            if let list = list { mine += list } else { s.complete = false }
            pending -= 1
            guard pending == 0, let self = self else { return }
            // Soonest to close first; an unknown end sorts last.
            mine.sort { ($0.end ?? .distantFuture) < ($1.end ?? .distantFuture) }
            self.confirmJoined(s, gen, Array(mine.prefix(ArenaHomeCardView.maxCandidates)))
        }
        ArenaAPI.listChallenges(state: "open", entity: user, completion: onPart)
        ArenaAPI.listChallenges(state: "active", entity: user, completion: onPart)
    }

    /// Walks the candidates until one is confirmed as still joined.
    private func confirmJoined(_ state: State, _ gen: Int, _ candidates: [ArenaChallenge]) {
        guard let next = candidates.first else { return loadOpenCount(state, gen) }
        var s = state
        ArenaAPI.challenge(id: next.id, viewer: s.user) { [weak self] detail, _ in
            guard let self = self else { return }
            if detail == nil { s.complete = false }
            // The pending store also honours a join/leave that was sent but not indexed yet.
            guard let detail = detail, ArenaPendingStore.membership(user: s.user, challenge: detail).isIn else {
                return self.confirmJoined(s, gen, Array(candidates.dropFirst()))
            }
            s.joined = detail
            ArenaAPI.standings(id: detail.id) { [weak self] rows, _ in
                if let rows = rows {
                    if let mine = rows.first(where: { $0.entity == s.user }) {
                        s.rank = mine.rank
                        s.score = mine.score
                    }
                } else {
                    s.complete = false
                }
                self?.done(s, gen)
            }
        }
    }

    private func loadOpenCount(_ state: State, _ gen: Int) {
        var s = state
        ArenaAPI.listChallenges(state: "open", entity: nil) { [weak self] open in
            // Couldn't reach the Arena: leave the card as it was rather than guess.
            guard let open = open else { return }
            s.openCount = open.count
            self?.done(s, gen)
        }
    }

    private func done(_ state: State, _ gen: Int) {
        guard gen == ArenaHomeCardView.generation else { return }
        var s = state
        if s.complete {
            s.loadedAt = Date()
            ArenaHomeCardView.cache = s
        } else if s.joined == nil {
            // A call failed and we found nothing: we don't know the user is in nothing, so
            // don't replace whatever the card shows with an invitation.
            return
        }
        bind(s)
    }

    private func bind(_ s: State) {
        shown = s
        if let c = s.joined {
            titleLabel.text = c.title
            if s.rank > 0 {
                statusLabel.text = ArenaText.homeRank(s.rank, score: ArenaFormat.number(s.score))
            } else {
                // Not on the board, or the board couldn't be read: then don't claim no score.
                statusLabel.text = s.complete ? ArenaText.homeNoScore : c.taglineText
            }
            timeLabel.text = c.timeText
            timeLabel.textColor = c.endsWithinADay ? .primaryRedColor() : .gray
            timeLabel.isHidden = false
        } else if s.openCount > 0 {
            titleLabel.text = ArenaText.homeJoinTitle
            statusLabel.text = ArenaText.openCount(s.openCount)
            timeLabel.isHidden = true
        } else {
            isHidden = true
            return
        }
        isHidden = false
    }
}

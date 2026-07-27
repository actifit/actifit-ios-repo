//
//  WalletAccordionViewController.swift
//  Actifit
//
//  Facelifted wallet screen — Android-style accordion (Core Balance,
//  Hive-Engine Balance, Claimable Token Rewards, AFIT Transactions,
//  Hive Transactions) with inline per-row action icons. Built on the
//  reusable AccordionCardView. Reuses WalletViewModel for data.
//

import UIKit
import Combine

final class WalletAccordionViewController: UIViewController {

    private let viewModel = WalletViewModel()
    private var cancellables = Set<AnyCancellable>()

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    private let coreCard = AccordionCardView(title: "Core Balance", systemIcon: "creditcard.fill")
    private let heCard = AccordionCardView(title: "Hive-Engine Balance", systemIcon: "wallet.pass.fill")
    private let claimCard = AccordionCardView(title: "Claimable Token Rewards", systemIcon: "gift.fill")
    private let afitTxCard = AccordionCardView(title: "AFIT Transactions", systemIcon: "doc.text.fill")
    private let hiveTxCard = AccordionCardView(title: "Hive Transactions", systemIcon: "arrow.left.arrow.right")

    private var afitTokens: Double = 0
    private var hiveSection: BalanceSections?
    private var blurtSection: BalanceSections?
    private var heLoaded = false
    private var pendingSummary = ""
    private var coreRefreshButton: UIButton?
    private var heRefreshButton: UIButton?

    private var username: String { User.current()?.steemit_username.byTrimming(string: "@").lowercased() ?? "" }
    private var brandRed: UIColor { AccordionCardView.brandRed }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(white: 0.96, alpha: 1)
        title = "Your Wallet"
        navigationController?.navigationBar.prefersLargeTitles = false
        setupScroll()
        bind()
        rebuildCore()
        rebuildClaim()
        loadAll()
    }

    private func makeHeaderBar() -> UIView {
        let header = UIView()
        header.backgroundColor = .white
        header.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(header)

        let back = UIButton(type: .system)
        back.setTitle("‹", for: .normal)
        back.titleLabel?.font = .systemFont(ofSize: 30, weight: .bold)
        back.setTitleColor(brandRed, for: .normal)
        back.addTarget(self, action: #selector(walletBackTapped), for: .touchUpInside)
        back.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = "Your Wallet"
        titleLabel.font = .systemFont(ofSize: 20, weight: .bold)
        titleLabel.textColor = brandRed
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        let sep = UIView()
        sep.backgroundColor = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1)
        sep.translatesAutoresizingMaskIntoConstraints = false

        header.addSubview(back); header.addSubview(titleLabel); header.addSubview(sep)
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            back.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            back.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 12),
            back.widthAnchor.constraint(equalToConstant: 40),
            back.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -10),
            titleLabel.centerXAnchor.constraint(equalTo: header.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: back.centerYAnchor),
            sep.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            sep.heightAnchor.constraint(equalToConstant: 1)
        ])
        return header
    }

    @objc private func walletBackTapped() {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func setupScroll() {
        let header = makeHeaderBar()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: header.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)
        scrollView.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            stack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor)
        ])
        accordionCards.forEach { stack.addArrangedSubview($0) }

        coreRefreshButton = coreCard.addHeaderAction(systemIcon: "arrow.clockwise") { [weak self] in
            guard let self = self else { return }
            if !self.coreCard.isExpanded { self.coreCard.setExpanded(true, animated: true) }
            self.startSpin(self.coreRefreshButton)
            self.viewModel.refresh()
            self.loadAfitBalance()
        }
        heRefreshButton = heCard.addHeaderAction(systemIcon: "arrow.clockwise") { [weak self] in
            guard let self = self else { return }
            if !self.heCard.isExpanded { self.heCard.setExpanded(true, animated: true) }
            self.startSpin(self.heRefreshButton)
            Task { await self.viewModel.getHiveEngineBalance() }
        }

        for card in accordionCards {
            card.onToggle = { [weak self, weak card] expanded in
                guard let self = self, let card = card else { return }
                if expanded {
                    self.collapseOthers(except: card)
                    if card === self.afitTxCard { self.loadAfitTransactions() }
                    if card === self.hiveTxCard { self.loadHiveTransactions() }
                }
            }
        }

        coreCard.setExpanded(true, animated: false)
    }

    private var accordionCards: [AccordionCardView] { [coreCard, heCard, claimCard, afitTxCard, hiveTxCard] }

    private func collapseOthers(except card: AccordionCardView) {
        for c in accordionCards where c !== card && c.isExpanded {
            c.setExpanded(false, animated: true)
        }
    }

    private func bind() {
        viewModel.hivePublisher.receive(on: DispatchQueue.main).sink { [weak self] section in
            self?.hiveSection = section; self?.rebuildCore(); self?.stopSpin(self?.coreRefreshButton)
        }.store(in: &viewModel.cancellables)

        viewModel.blurtPublisher.receive(on: DispatchQueue.main).sink { [weak self] section in
            self?.blurtSection = section; self?.rebuildCore()
        }.store(in: &viewModel.cancellables)

        viewModel.hiveEngineBalancePublisher.receive(on: DispatchQueue.main).sink { [weak self] _ in
            self?.heLoaded = true; self?.rebuildHiveEngine(); self?.stopSpin(self?.heRefreshButton)
        }.store(in: &viewModel.cancellables)

        viewModel.pendingRewardsPublisher.receive(on: DispatchQueue.main).sink { [weak self] summary in
            self?.pendingSummary = summary; self?.rebuildClaim()
        }.store(in: &viewModel.cancellables)

        viewModel.claimResultPublisher.receive(on: DispatchQueue.main).sink { [weak self] (success, message) in
            self?.showAlertWith(title: success ? "Success" : "Error", message: message)
            if success { self?.pendingSummary = ""; self?.rebuildClaim(); self?.viewModel.refresh(); self?.viewModel.fetchPendingRewards() }
        }.store(in: &viewModel.cancellables)
    }

    private func loadAll() {
        loadAfitBalance()
        viewModel.fetchPendingRewards()
    }

    private func loadAfitBalance() {
        API().getWalletBalanceWith(username: username, completion: { [weak self] info, _ in
            if let s = info as? String,
               let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any],
               let tokens = json["tokens"] as? String {
                self?.afitTokens = Double(tokens) ?? 0
                DispatchQueue.main.async { self?.rebuildCore() }
            }
        }, failure: { _ in })
    }

    private func showLoader(_ show: Bool) {
        if show { ActifitLoader.show(title: "Loading...", animated: true) } else { ActifitLoader.hide() }
    }

    private func startSpin(_ button: UIButton?) {
        guard let button = button else { return }
        if button.layer.animation(forKey: "spin") != nil { return }
        let rot = CABasicAnimation(keyPath: "transform.rotation")
        rot.fromValue = 0
        rot.toValue = CGFloat.pi * 2
        rot.duration = 0.8
        rot.repeatCount = .infinity
        button.layer.add(rot, forKey: "spin")
        // Safety: auto-stop after 10s if the refresh callback never arrives.
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self, weak button] in self?.stopSpin(button) }
    }

    private func stopSpin(_ button: UIButton?) {
        button?.layer.removeAnimation(forKey: "spin")
    }

    // MARK: - Row builders

    private func actionButton(systemIcon: String, handler: @escaping () -> Void) -> UIButton {
        let b = ClosureButton(type: .system)
        b.setImage(UIImage(systemName: systemIcon), for: .normal)
        b.tintColor = brandRed
        b.onTap = handler
        b.addTarget(b, action: #selector(ClosureButton.fire), for: .touchUpInside)
        b.widthAnchor.constraint(equalToConstant: 26).isActive = true
        b.heightAnchor.constraint(equalToConstant: 26).isActive = true
        return b
    }

    private func balanceRow(icon: UIImage?, iconURL: String?, balance: String, staked: String?, actions: [UIButton]) -> UIView {
        let iconView = UIImageView(image: icon)
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 30).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 30).isActive = true
        if let urlStr = iconURL, !urlStr.isEmpty, let url = URL(string: urlStr) {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    DispatchQueue.main.async { iconView.image = img }
                }
            }.resume()
        }

        let balanceLabel = UILabel()
        balanceLabel.text = balance
        balanceLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        balanceLabel.textColor = UIColor(white: 0.13, alpha: 1)
        balanceLabel.numberOfLines = 0
        balanceLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        let stakedLabel = UILabel()
        stakedLabel.text = staked
        stakedLabel.font = .systemFont(ofSize: 12)
        stakedLabel.textColor = .gray
        stakedLabel.numberOfLines = 0

        let middleViews: [UIView] = (staked?.isEmpty == false) ? [balanceLabel, stakedLabel] : [balanceLabel]
        let middle = UIStackView(arrangedSubviews: middleViews)
        middle.axis = .vertical
        middle.spacing = 2
        middle.alignment = .leading
        middle.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let actionsStack = UIStackView(arrangedSubviews: actions)
        actionsStack.axis = .horizontal
        actionsStack.spacing = 12
        actionsStack.alignment = .center
        actionsStack.setContentHuggingPriority(.required, for: .horizontal)
        actionsStack.setContentCompressionResistancePriority(.required, for: .horizontal)

        let row = UIStackView(arrangedSubviews: [iconView, middle, actionsStack])
        row.axis = .horizontal
        row.spacing = 12
        row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
        return row
    }

    private func verticalContent(_ rows: [UIView]) -> UIView {
        let v = UIStackView(arrangedSubviews: rows)
        v.axis = .vertical
        v.spacing = 0
        return v
    }

    /// Strips a trailing unit (e.g. "37.315 HIVE" -> 37.315) and re-formats with a label.
    private func formatToken(_ raw: String?, unit: String) -> String {
        let numStr = (raw ?? "0").split(separator: " ").first.map(String.init) ?? "0"
        let val = Double(numStr) ?? 0
        return "\(val.formatToThreeDecimalPlacesWithSeparators()) \(unit)"
    }

    // MARK: - Core Balance

    private func rebuildCore() {
        var rows: [UIView] = []
        // AFIT
        rows.append(balanceRow(icon: UIImage(named: "logo"), iconURL: nil,
                               balance: "\(afitTokens.formatToThousandSeparated()) AFIT",
                               staked: nil,
                               actions: [actionButton(systemIcon: "paperplane.fill") { [weak self] in self?.presentSendAfit() }]))
        // HIVE / HBD
        if let hive = hiveSection {
            let hiveBalText = "\(formatToken(viewModel.hiveObject?.hive.balance, unit: "HIVE"))\n\(formatToken(viewModel.hiveObject?.hive.hbd_balance, unit: "HBD"))"
            rows.append(balanceRow(icon: UIImage(named: "hive-icon"), iconURL: nil,
                                   balance: hiveBalText,
                                   staked: hive.staked,
                                   actions: [
                                    actionButton(systemIcon: "paperplane.fill") { [weak self] in self?.presentSendHive() },
                                    actionButton(systemIcon: "arrow.up.circle.fill") { [weak self] in self?.presentPowerUp() },
                                    actionButton(systemIcon: "arrow.down.circle.fill") { [weak self] in self?.presentPowerDown() }
                                   ]))
        }
        // BLURT
        if let blurt = blurtSection {
            rows.append(balanceRow(icon: UIImage(named: "blurt-icon"), iconURL: nil,
                                   balance: blurt.balance ?? "", staked: blurt.staked, actions: []))
        }
        coreCard.setContent(verticalContent(rows))
    }

    // MARK: - Hive-Engine

    private func rebuildHiveEngine() {
        guard let tokens = viewModel.hiveEngineBalanceToken?.result, !tokens.isEmpty else {
            let empty = UILabel()
            empty.text = "No Hive-Engine tokens"
            empty.textColor = .gray
            empty.font = .systemFont(ofSize: 14)
            empty.textAlignment = .center
            let wrap = UIView(); wrap.translatesAutoresizingMaskIntoConstraints = false
            wrap.addSubview(empty); empty.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                empty.topAnchor.constraint(equalTo: wrap.topAnchor, constant: 16),
                empty.bottomAnchor.constraint(equalTo: wrap.bottomAnchor, constant: -16),
                empty.centerXAnchor.constraint(equalTo: wrap.centerXAnchor)
            ])
            heCard.setContent(wrap)
            return
        }
        var rows: [UIView] = []
        for (idx, t) in tokens.enumerated() {
            let symbol = t.symbol ?? ""
            let bal = (Double(t.balance ?? "0") ?? 0)
            let stk = (Double(t.stake ?? "0") ?? 0)
            let iconURL = viewModel.getTokenURL(symbol: symbol)
            let fallbackIcon = iconURL.isEmpty ? viewModel.generateTokenImg(symbol: symbol) : nil
            rows.append(balanceRow(icon: fallbackIcon, iconURL: iconURL,
                                   balance: "\(bal.formatToThreeDecimalPlacesWithSeparators()) \(symbol)",
                                   staked: stk > 0 ? "\(stk.formatToThreeDecimalPlacesWithSeparators()) staked" : nil,
                                   actions: [
                                    actionButton(systemIcon: "paperplane.fill") { [weak self] in self?.presentHETokenAction(row: idx, action: .transfer) },
                                    actionButton(systemIcon: "lock.fill") { [weak self] in self?.presentHETokenAction(row: idx, action: .stake) },
                                    actionButton(systemIcon: "lock.open.fill") { [weak self] in self?.presentHETokenAction(row: idx, action: .unstake) }
                                   ]))
        }
        heCard.setContent(verticalContent(rows))
    }

    // MARK: - Claimable rewards

    private func rebuildClaim() {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 10
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)

        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14)
        if pendingSummary.isEmpty {
            label.text = "No claimable rewards right now."
            label.textColor = .gray
            container.addArrangedSubview(label)
        } else {
            label.text = "Pending: \(pendingSummary)"
            label.textColor = UIColor(white: 0.15, alpha: 1)
            container.addArrangedSubview(label)
            let btn = ClosureButton(type: .system)
            btn.setTitle("Claim Rewards", for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = brandRed
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            btn.layer.cornerRadius = 8
            btn.heightAnchor.constraint(equalToConstant: 42).isActive = true
            btn.onTap = { [weak self] in self?.confirmClaim() }
            btn.addTarget(btn, action: #selector(ClosureButton.fire), for: .touchUpInside)
            container.addArrangedSubview(btn)
        }
        claimCard.setContent(container)
    }

    private func confirmClaim() {
        let alert = UIAlertController(title: "Claim Rewards", message: "Claim your pending rewards?\n\n\(pendingSummary)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Claim", style: .default) { [weak self] _ in self?.viewModel.claimAllRewards() })
        present(alert, animated: true)
    }

    // MARK: - Transaction lists

    private func loadAfitTransactions() {
        APIMaster.getTransactions(username: username, completion: { [weak self] jsonString, _ in
            var items: [Transaction] = []
            if let s = jsonString as? String,
               let arr = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [[String: Any]] {
                items = arr.map { Transaction(info: $0) }
            }
            DispatchQueue.main.async { self?.renderAfitTransactions(items) }
        }, failure: { _ in })
    }

    private func renderAfitTransactions(_ items: [Transaction]) {
        var rows: [UIView] = []
        if items.isEmpty {
            rows.append(simpleTextRow("No AFIT transactions", subtitle: nil, amount: nil, positive: false))
        } else {
            for t in items.prefix(50) {
                let title = !t.note.isEmpty ? t.note : (!t.reward_activity.isEmpty ? t.reward_activity : "AFIT")
                let sign = t.token_count > 0 ? "+" : ""
                rows.append(simpleTextRow(title, subtitle: t.date, amount: "\(sign)\(t.token_count) AFIT", positive: t.token_count >= 0))
            }
        }
        afitTxCard.setContent(verticalContent(rows))
    }

    private func loadHiveTransactions() {
        showLoader(true)
        API().getHiveAccountHistory(username: username, start: -1, completion: { [weak self] info, _ in
            let parsed = HiveHistoryViewController.parse(response: (info as? String)?.utf8Data() ?? Data(), username: self?.username ?? "")
            DispatchQueue.main.async { self?.showLoader(false); self?.renderHiveTransactions(parsed) }
        }, failure: { [weak self] _ in DispatchQueue.main.async { self?.showLoader(false) } })
    }

    private func renderHiveTransactions(_ items: [HiveHistoryItem]) {
        var rows: [UIView] = []
        if items.isEmpty {
            rows.append(simpleTextRow("No Hive transactions", subtitle: nil, amount: nil, positive: false))
        } else {
            for it in items.prefix(60) {
                let positive = !it.amount.hasPrefix("-")
                let sub = [it.date, it.memo].filter { !$0.isEmpty }.joined(separator: "  •  ")
                rows.append(simpleTextRow(it.title, subtitle: sub, amount: it.amount, positive: positive))
            }
        }
        hiveTxCard.setContent(verticalContent(rows))
    }

    private func simpleTextRow(_ title: String, subtitle: String?, amount: String?, positive: Bool) -> UIView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.numberOfLines = 0

        let amountLabel = UILabel()
        amountLabel.text = amount
        amountLabel.font = .systemFont(ofSize: 14, weight: .bold)
        amountLabel.textColor = positive ? .systemGreen : brandRed
        amountLabel.setContentHuggingPriority(.required, for: .horizontal)
        amountLabel.textAlignment = .right

        let topRow = UIStackView(arrangedSubviews: [titleLabel, amountLabel])
        topRow.axis = .horizontal
        topRow.spacing = 8

        let col = UIStackView(arrangedSubviews: [topRow])
        col.axis = .vertical
        col.spacing = 2
        if let subtitle = subtitle, !subtitle.isEmpty {
            let subLabel = UILabel()
            subLabel.text = subtitle
            subLabel.font = .systemFont(ofSize: 12)
            subLabel.textColor = .gray
            subLabel.numberOfLines = 0
            col.addArrangedSubview(subLabel)
        }
        col.isLayoutMarginsRelativeArrangement = true
        col.layoutMargins = UIEdgeInsets(top: 10, left: 16, bottom: 10, right: 16)

        let wrap = UIView()
        wrap.translatesAutoresizingMaskIntoConstraints = false
        col.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(col)
        NSLayoutConstraint.activate([
            col.topAnchor.constraint(equalTo: wrap.topAnchor),
            col.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            col.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            col.bottomAnchor.constraint(equalTo: wrap.bottomAnchor)
        ])
        let sep = UIView()
        sep.backgroundColor = UIColor(white: 0.93, alpha: 1)
        sep.translatesAutoresizingMaskIntoConstraints = false
        wrap.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.heightAnchor.constraint(equalToConstant: 1),
            sep.leadingAnchor.constraint(equalTo: wrap.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: wrap.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: wrap.bottomAnchor)
        ])
        return wrap
    }

    // MARK: - Actions (send / power / HE)

    private func presentSendAfit() {
        present(SendAfitViewController.create(afit: afitTokens, completeTransaction: { [weak self] in self?.loadAfitBalance() }), animated: true)
    }

    private func presentSendHive() {
        present(SendHiveViewController.create(hive: viewModel.hiveAmount ?? "", hbd: viewModel.hbdAmount ?? "", completeTransaction: { [weak self] in self?.viewModel.refresh() }), animated: true)
    }

    private func presentPowerUp() {
        let activeKey = UserDefaults.standard.activeKey
        guard !activeKey.isEmpty else { showToast(message: "Please set your active key under settings"); return }
        let available = Double(viewModel.hiveAmount ?? "0") ?? 0
        let alert = UIAlertController(title: "Power Up", message: "Available: \(available) HIVE", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Amount (HIVE)"; $0.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Power Up", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let amt = Double(alert.textFields?.first?.text ?? "") ?? 0
            if amt <= 0 || amt > available { self.showToast(message: "Enter a valid amount within balance"); return }
            self.showLoader(true)
            API().powerUpHive(user: self.username, to: self.username, amount: String(format: "%.3f", amt), activeKey: activeKey, completion: { [weak self] info, _ in
                self?.handleBroadcast(info, success: "Power up completed")
            }, failure: { [weak self] e in self?.failToast(e) })
        })
        present(alert, animated: true)
    }

    private func presentPowerDown() {
        let activeKey = UserDefaults.standard.activeKey
        guard !activeKey.isEmpty else { showToast(message: "Please set your active key under settings"); return }
        let available = Double(viewModel.hivePowerAmount ?? "0") ?? 0
        let alert = UIAlertController(title: "Power Down", message: "Available: \(available) HP", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Amount (HP)"; $0.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Power Down", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let amt = Double(alert.textFields?.first?.text ?? "") ?? 0
            if amt <= 0 || amt > available { self.showToast(message: "Enter a valid amount within power"); return }
            let vests = self.viewModel.powerToVests(hpValue: String(amt))
            self.showLoader(true)
            API().powerDownHive(user: self.username, vests: vests, activeKey: activeKey, completion: { [weak self] info, _ in
                self?.handleBroadcast(info, success: "Power down initiated")
            }, failure: { [weak self] e in self?.failToast(e) })
        })
        present(alert, animated: true)
    }

    private enum HETokenAction { case transfer, stake, unstake }

    private func presentHETokenAction(row: Int, action: HETokenAction) {
        guard let tokens = viewModel.hiveEngineBalanceToken?.result, row < tokens.count, let symbol = tokens[row].symbol else { return }
        let available = Double(tokens[row].balance ?? "0") ?? 0
        let staked = Double(tokens[row].stake ?? "0") ?? 0
        let activeKey = UserDefaults.standard.activeKey
        guard !activeKey.isEmpty else { showToast(message: "Please set your active key under settings"); return }
        let maxAmount = action == .unstake ? staked : available
        let title: String = action == .transfer ? "Send \(symbol)" : (action == .stake ? "Stake \(symbol)" : "Unstake \(symbol)")
        let alert = UIAlertController(title: title, message: "Available: \(maxAmount) \(symbol)", preferredStyle: .alert)
        if action == .transfer { alert.addTextField { $0.placeholder = "Recipient"; $0.autocapitalizationType = .none; $0.autocorrectionType = .no } }
        alert.addTextField { $0.placeholder = "Amount"; $0.keyboardType = .decimalPad }
        if action == .transfer { alert.addTextField { $0.placeholder = "Memo (optional)" } }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default) { [weak self] _ in
            guard let self = self else { return }
            let fields = alert.textFields ?? []
            var recipient = self.username, amountText = "", memo = ""
            if action == .transfer {
                recipient = fields[0].text?.trimmingCharacters(in: .whitespaces).byTrimming(string: "@").lowercased() ?? ""
                amountText = fields.count > 1 ? (fields[1].text ?? "") : ""
                memo = fields.count > 2 ? (fields[2].text ?? "") : ""
            } else { amountText = fields.first?.text ?? "" }
            let amount = Double(amountText) ?? 0
            if action == .transfer, recipient.isEmpty || recipient == self.username { self.showToast(message: "Enter a valid recipient"); return }
            if amount <= 0 || amount > maxAmount { self.showToast(message: "Enter a valid amount within balance"); return }
            let actionName = action == .transfer ? "transfer" : (action == .stake ? "stake" : "unstake")
            self.showLoader(true)
            API().hiveEngineTokenOperation(user: self.username, symbol: symbol, to: recipient, quantity: String(format: "%.3f", amount), memo: memo, action: actionName, activeKey: activeKey, completion: { [weak self] info, _ in
                self?.handleBroadcast(info, success: "\(title) completed")
            }, failure: { [weak self] e in self?.failToast(e) })
        })
        present(alert, animated: true)
    }

    private func handleBroadcast(_ info: Any?, success: String) {
        DispatchQueue.main.async {
            self.showLoader(false)
            var ok = false
            if let s = info as? String, let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any] {
                ok = json["success"] != nil
            }
            if ok {
                self.showAlertWith(title: "Success", message: success)
                self.viewModel.refresh()
                self.loadAfitBalance()
                Task { await self.viewModel.getHiveEngineBalance() }
            } else {
                self.showAlertWith(title: "Error", message: "Transaction failed, please try again")
            }
        }
    }

    private func failToast(_ error: NSError) {
        DispatchQueue.main.async { self.showLoader(false); self.showToast(message: error.localizedDescription) }
    }
}

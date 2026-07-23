//
//  MarketViewController.swift
//  Actifit
//
//  Phase 2 — Gadget marketplace (Android MarketActivity parity).
//  Browse in-game gadgets, evaluate purchase requirements, and buy / activate /
//  deactivate via the Actifit relay (performTrx / performTrxPost) + confirmation calls.
//

import UIKit

// MARK: - Models

struct MarketRequirement {
    let item: String
    let level: String
    let count: String
    let isAfit: Bool
    var met: Bool
    let displayText: String
}

struct MarketBoost {
    let amount: String
    let type: String
    let unit: String
    let toFriend: Bool

    var displayText: String {
        let typeText: String
        switch type {
        case "percent_reward", "percent": typeText = "%"
        case "unit": typeText = " "
        default: typeText = type
        }
        let recipient = toFriend ? "to a friend" : "to you"
        return "+ \(amount) \(typeText) \(unit) rewards per report \(recipient)"
    }
}

final class MarketProduct {
    let id: String
    let name: String
    let type: String
    let image: String
    let productDescription: String
    let level: Int
    let priceAfit: Double
    var priceHive: Double
    let validity: String
    let validityVal: Int
    let count: Int
    let active: Bool
    let specialEvent: Bool
    let boosts: [MarketBoost]
    var requirements: [MarketRequirement]
    let isFriendRewarding: Bool

    // Runtime state
    var allReqtsMet: Bool = true
    var ownershipState: Int = 0   // 0 = none, 1 = bought, 2 = active
    var totalBought: Int = 0
    var totalConsumed: Int = 0
    var remainingBoosts: Int = 0

    init?(dict: [String: Any], afitPrice: Double) {
        guard let id = dict["_id"] as? String,
              let type = dict["type"] as? String else { return nil }
        self.id = id
        self.name = dict["name"] as? String ?? ""
        self.type = type
        self.image = dict["image"] as? String ?? ""
        self.productDescription = dict["description"] as? String ?? ""
        self.level = (dict["level"] as? Int) ?? Int("\(dict["level"] ?? "0")") ?? 0
        self.count = (dict["count"] as? Int) ?? 0
        self.active = (dict["active"] as? Bool) ?? false
        self.specialEvent = (dict["specialevent"] as? Bool) ?? false

        // Price: find the AFIT entry
        var afit = 0.0
        if let prices = dict["price"] as? [[String: Any]] {
            for p in prices where (p["currency"] as? String) == "AFIT" {
                if let d = p["price"] as? Double { afit = d }
                else if let s = p["price"] as? String { afit = Double(s) ?? 0 }
            }
        }
        self.priceAfit = afit
        self.priceHive = afitPrice > 0 ? (afit * afitPrice * 1000).rounded() / 1000 : 0

        // Benefits: validity + boosts
        var validityStr = ""
        var validityValue = 0
        var boostList: [MarketBoost] = []
        var friendRewarding = false
        if let benefits = dict["benefits"] as? [String: Any] {
            let span = "\(benefits["time_span"] ?? "")"
            let unit = "\(benefits["time_unit"] ?? "")"
            validityStr = "\(span) \(unit)"
            validityValue = Int(span) ?? 0
            if let boosts = benefits["boosts"] as? [[String: Any]] {
                for b in boosts {
                    let amount = "\(b["boost_amount"] ?? b["boost_min_amount"] ?? "")"
                    let btype = b["boost_type"] as? String ?? ""
                    let bunit = b["boost_unit"] as? String ?? ""
                    let toFriend = (b["boost_beneficiary"] as? String) == "friend"
                    if toFriend { friendRewarding = true }
                    boostList.append(MarketBoost(amount: amount, type: btype, unit: bunit, toFriend: toFriend))
                }
            }
        }
        self.validity = validityStr
        self.validityVal = validityValue
        self.boosts = boostList
        self.isFriendRewarding = friendRewarding

        // Requirements (may be an array or an empty string)
        var reqs: [MarketRequirement] = []
        if let reqArr = dict["requirements"] as? [[String: Any]] {
            for r in reqArr {
                guard let item = r["item"] as? String else { continue }
                let level = "\(r["level"] ?? "")"
                let count = "\(r["count"] ?? "")"
                let isAfit = r["AFIT"] != nil
                let text: String
                if item == "User Rank" {
                    text = "User Rank > \(level)"
                } else if isAfit {
                    text = "AFIT balance >= \(count) AFIT"
                } else {
                    text = "At least \(count) \(item) - L\(level) Consumed"
                }
                reqs.append(MarketRequirement(item: item, level: level, count: count, isAfit: isAfit, met: false, displayText: text))
            }
        }
        self.requirements = reqs
    }
}

// MARK: - View controller

final class MarketViewController: UIViewController {

    private let tableView = UITableView(frame: .zero, style: .plain)
    private var products: [MarketProduct] = []

    private var afitPrice: Double = 0
    private var afitBalance: Double = 0
    private var userRank: Double = 0
    private var nonConsumed: [[String: Any]] = []
    private var consumed: [[String: Any]] = []

    private var username: String {
        return User.current()?.steemit_username.byTrimming(string: "@").lowercased() ?? ""
    }

    static func create() -> MarketViewController {
        return MarketViewController()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Market"
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeTapped))
        setupTable()
        loadEverything()
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 260
        tableView.register(MarketProductCell.self, forCellReuseIdentifier: "MarketProductCell")
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func showLoader(_ show: Bool) {
        if show { ActifitLoader.show(title: "Loading...", animated: true) } else { ActifitLoader.hide() }
    }

    // MARK: Loading (sequential, mirrors Android order)

    private func loadEverything() {
        showLoader(true)
        // 1. AFIT price
        API().getExchangeAfitPrice(completion: { [weak self] info, _ in
            if let s = info as? String,
               let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any],
               let p = json["afitHiveLastPrice"] as? Double {
                self?.afitPrice = p
            }
            self?.loadBalance()
        }, failure: { [weak self] _ in self?.loadBalance() })
    }

    private func loadBalance() {
        API().getWalletBalanceWith(username: username, completion: { [weak self] info, _ in
            if let s = info as? String,
               let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any],
               let tokens = json["tokens"] as? String {
                self?.afitBalance = Double(tokens) ?? 0
            }
            self?.loadRank()
        }, failure: { [weak self] _ in self?.loadRank() })
    }

    private func loadRank() {
        API().getRank(username: username, completion: { [weak self] info, _ in
            if let s = info as? String {
                if let d = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)) {
                    self?.userRank = d
                } else if let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any] {
                    if let r = json["rank"] as? Double { self?.userRank = r }
                    else if let r = json["rank"] as? String { self?.userRank = Double(r) ?? 0 }
                }
            }
            self?.loadNonConsumed()
        }, failure: { [weak self] _ in self?.loadNonConsumed() })
    }

    private func loadNonConsumed() {
        API().getNonConsumedGadgets(username: username, completion: { [weak self] info, _ in
            if let s = info as? String,
               let arr = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [[String: Any]] {
                self?.nonConsumed = arr
            }
            self?.loadConsumed()
        }, failure: { [weak self] _ in self?.loadConsumed() })
    }

    private func loadConsumed() {
        API().getConsumedGadgets(username: username, completion: { [weak self] info, _ in
            if let s = info as? String,
               let arr = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [[String: Any]] {
                self?.consumed = arr
            }
            self?.loadProducts()
        }, failure: { [weak self] _ in self?.loadProducts() })
    }

    private func loadProducts() {
        API().getMarketProducts(completion: { [weak self] info, _ in
            guard let self = self else { return }
            var parsed: [MarketProduct] = []
            if let s = info as? String,
               let arr = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [[String: Any]] {
                for dict in arr {
                    guard let product = MarketProduct(dict: dict, afitPrice: self.afitPrice) else { continue }
                    // Only active in-game gadgets, like Android
                    guard product.active, product.type == "ingame" else { continue }
                    if product.specialEvent && !product.active { continue }
                    self.evaluate(product)
                    parsed.append(product)
                }
            }
            parsed.sort { $0.level < $1.level }
            DispatchQueue.main.async {
                self.showLoader(false)
                self.products = parsed
                self.tableView.reloadData()
            }
        }, failure: { [weak self] _ in
            DispatchQueue.main.async { self?.showLoader(false) }
        })
    }

    // MARK: Requirement + ownership evaluation

    private func evaluate(_ product: MarketProduct) {
        // Ownership from non-consumed gadgets
        var bought = 0
        for entry in nonConsumed where (entry["gadget"] as? String) == product.id {
            bought += 1
            let status = entry["status"] as? String ?? ""
            product.ownershipState = (status == "active") ? 2 : max(product.ownershipState, 1)
            let consumedCount = (entry["posts_consumed"] as? [Any])?.count ?? 0
            product.remainingBoosts = product.validityVal - consumedCount
        }
        product.totalBought = bought
        // Consumed count for this gadget
        product.totalConsumed = consumed.filter { ($0["gadget"] as? String) == product.id }.count

        // Requirements
        var allMet = true
        for i in product.requirements.indices {
            let req = product.requirements[i]
            var met = false
            if req.item == "User Rank" {
                met = userRank >= (Double(req.level) ?? Double(Int(req.level) ?? 0))
            } else if req.isAfit {
                met = afitBalance >= Double(Int(req.count) ?? 0)
            } else {
                let matches = consumed.filter {
                    ($0["gadget_name"] as? String) == req.item &&
                    "\($0["gadget_level"] ?? "")" == req.level
                }.count
                met = matches >= (Int(req.count) ?? 0)
            }
            product.requirements[i].met = met
            if !met { allMet = false }
        }
        product.allReqtsMet = allMet
    }

    // MARK: Transaction helpers

    private func extractTrx(_ info: Any?) -> (refBlockNum: Int, txId: String)? {
        guard let s = info as? String,
              let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any],
              json["success"] != nil,
              let trx = json["trx"] as? [String: Any],
              let tx = trx["tx"] as? [String: Any],
              let refBlockNum = tx["ref_block_num"] as? Int,
              let txId = tx["id"] as? String else { return nil }
        return (refBlockNum, txId)
    }

    private func confirmFailedMessage(_ info: Any?) -> String? {
        // returns nil on success, else an error string
        guard let s = info as? String,
              let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any] else {
            return "Please try again"
        }
        if let err = json["error"] as? String, !err.isEmpty { return err }
        if json["error"] != nil { return "Please try again" }
        return nil
    }

    private func afterSuccess(_ product: MarketProduct, newState: Int, message: String) {
        DispatchQueue.main.async {
            self.showLoader(false)
            product.ownershipState = newState
            self.tableView.reloadData()
            self.showAlertWith(title: "Success", message: message)
        }
    }

    private func fail(_ message: String) {
        DispatchQueue.main.async {
            self.showLoader(false)
            self.showToast(message: message)
        }
    }

    // MARK: Actions

    private func buyWithAfit(_ product: MarketProduct) {
        guard product.priceAfit <= afitBalance else { showToast(message: "You don't have enough AFIT"); return }
        showLoader(true)
        API().broadcastGadgetOperation(username: username, transaction: "buy-gadget", gadgetId: product.id, benefic: nil, completion: { [weak self] info, _ in
            guard let self = self else { return }
            guard let trx = self.extractTrx(info) else { self.fail("Purchase failed, please try again"); return }
            API().confirmGadgetTransaction(confirmBase: ApiUrls.buyGadgetConfirm, username: self.username, gadgetId: product.id, refBlockNum: trx.refBlockNum, txId: trx.txId, benefic: nil, completion: { [weak self] cinfo, _ in
                if let err = self?.confirmFailedMessage(cinfo) { self?.fail(err) }
                else { self?.afterSuccess(product, newState: 1, message: "Gadget purchased. You can now activate it.") }
            }, failure: { [weak self] e in self?.fail(e.localizedDescription) })
        }, failure: { [weak self] e in self?.fail(e.localizedDescription) })
    }

    private func buyWithHive(_ product: MarketProduct) {
        let activeKey = UserDefaults.standard.activeKey
        guard !activeKey.isEmpty else { showToast(message: "Please make sure to set your active key under settings"); return }
        showLoader(true)
        let priceHive = String(format: "%.3f", product.priceHive)
        API().buyGadgetWithHive(username: username, gadgetId: product.id, priceHive: priceHive, activeKey: activeKey, completion: { [weak self] info, _ in
            guard let self = self else { return }
            guard let trx = self.extractTrx(info) else { self.fail("Purchase failed, please try again"); return }
            API().confirmGadgetTransaction(confirmBase: ApiUrls.buyGadgetHiveConfirm, username: self.username, gadgetId: product.id, refBlockNum: trx.refBlockNum, txId: trx.txId, benefic: nil, completion: { [weak self] cinfo, _ in
                if let err = self?.confirmFailedMessage(cinfo) { self?.fail(err) }
                else { self?.afterSuccess(product, newState: 1, message: "Gadget purchased. You can now activate it.") }
            }, failure: { [weak self] e in self?.fail(e.localizedDescription) })
        }, failure: { [weak self] e in self?.fail(e.localizedDescription) })
    }

    private func activate(_ product: MarketProduct, benefic: String?) {
        if product.isFriendRewarding && (benefic ?? "").isEmpty {
            showToast(message: "Please enter a friend to reward"); return
        }
        showLoader(true)
        API().broadcastGadgetOperation(username: username, transaction: "activate-gadget", gadgetId: product.id, benefic: benefic, completion: { [weak self] info, _ in
            guard let self = self else { return }
            guard let trx = self.extractTrx(info) else { self.fail("Activation failed, please try again"); return }
            API().confirmGadgetTransaction(confirmBase: ApiUrls.activateGadgetConfirm, username: self.username, gadgetId: product.id, refBlockNum: trx.refBlockNum, txId: trx.txId, benefic: benefic, completion: { [weak self] cinfo, _ in
                if let err = self?.confirmFailedMessage(cinfo) { self?.fail(err) }
                else { self?.afterSuccess(product, newState: 2, message: "Gadget activated") }
            }, failure: { [weak self] e in self?.fail(e.localizedDescription) })
        }, failure: { [weak self] e in self?.fail(e.localizedDescription) })
    }

    private func deactivate(_ product: MarketProduct) {
        showLoader(true)
        API().broadcastGadgetOperation(username: username, transaction: "deactivate-gadget", gadgetId: product.id, benefic: nil, completion: { [weak self] info, _ in
            guard let self = self else { return }
            guard let trx = self.extractTrx(info) else { self.fail("Deactivation failed, please try again"); return }
            API().confirmGadgetTransaction(confirmBase: ApiUrls.deactivateGadgetConfirm, username: self.username, gadgetId: product.id, refBlockNum: trx.refBlockNum, txId: trx.txId, benefic: nil, completion: { [weak self] cinfo, _ in
                if let err = self?.confirmFailedMessage(cinfo) { self?.fail(err) }
                else { self?.afterSuccess(product, newState: 1, message: "Gadget deactivated") }
            }, failure: { [weak self] e in self?.fail(e.localizedDescription) })
        }, failure: { [weak self] e in self?.fail(e.localizedDescription) })
    }
}

extension MarketViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.isEmpty ? 1 : products.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard !products.isEmpty else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "empty")
            cell.textLabel?.text = "No gadgets available"
            cell.textLabel?.textAlignment = .center
            cell.selectionStyle = .none
            return cell
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: "MarketProductCell", for: indexPath) as! MarketProductCell
        let product = products[indexPath.row]
        cell.configure(with: product)
        cell.onBuyAfit = { [weak self] in self?.buyWithAfit(product) }
        cell.onBuyHive = { [weak self] in self?.buyWithHive(product) }
        cell.onActivate = { [weak self] benefic in self?.activate(product, benefic: benefic) }
        cell.onDeactivate = { [weak self] in self?.deactivate(product) }
        return cell
    }
}

// MARK: - Cell

final class MarketProductCell: UITableViewCell {

    var onBuyAfit: (() -> Void)?
    var onBuyHive: (() -> Void)?
    var onActivate: ((String?) -> Void)?
    var onDeactivate: (() -> Void)?

    private let iconView = UIImageView()
    private let nameLabel = UILabel()
    private let starsLabel = UILabel()
    private let validityLabel = UILabel()
    private let requirementsLabel = UILabel()
    private let boostsLabel = UILabel()
    private let infoLabel = UILabel()
    private let beneficiaryField = UITextField()
    private let buyAfitBtn = UIButton(type: .system)
    private let buyHiveBtn = UIButton(type: .system)
    private let activateBtn = UIButton(type: .system)
    private let deactivateBtn = UIButton(type: .system)
    private let container = UIStackView()
    private var imageTask: URLSessionDataTask?

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        buildUI()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private func styleButton(_ b: UIButton, color: UIColor) {
        b.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        b.titleLabel?.numberOfLines = 2
        b.titleLabel?.textAlignment = .center
        b.setTitleColor(.white, for: .normal)
        b.backgroundColor = color
        b.layer.cornerRadius = 6
        b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
    }

    private func buildUI() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.contentMode = .scaleAspectFit
        iconView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 60).isActive = true

        nameLabel.font = .systemFont(ofSize: 17, weight: .bold)
        nameLabel.numberOfLines = 0
        starsLabel.font = .systemFont(ofSize: 14)
        starsLabel.textColor = .systemOrange
        validityLabel.font = .systemFont(ofSize: 13)
        validityLabel.textColor = .darkGray

        let header = UIStackView(arrangedSubviews: [iconView, {
            let v = UIStackView(arrangedSubviews: [nameLabel, starsLabel, validityLabel])
            v.axis = .vertical; v.spacing = 2
            return v
        }()])
        header.axis = .horizontal
        header.spacing = 12
        header.alignment = .center

        [requirementsLabel, boostsLabel, infoLabel].forEach {
            $0.font = .systemFont(ofSize: 13)
            $0.numberOfLines = 0
        }
        boostsLabel.textColor = .systemGreen
        infoLabel.textColor = .gray

        beneficiaryField.placeholder = "Friend username to reward"
        beneficiaryField.borderStyle = .roundedRect
        beneficiaryField.autocapitalizationType = .none
        beneficiaryField.autocorrectionType = .no
        beneficiaryField.font = .systemFont(ofSize: 14)

        styleButton(buyAfitBtn, color: .systemBlue)
        styleButton(buyHiveBtn, color: .systemIndigo)
        styleButton(activateBtn, color: .systemGreen)
        styleButton(deactivateBtn, color: .systemRed)
        activateBtn.setTitle("Activate", for: .normal)
        deactivateBtn.setTitle("Deactivate", for: .normal)
        buyAfitBtn.addTarget(self, action: #selector(buyAfitTapped), for: .touchUpInside)
        buyHiveBtn.addTarget(self, action: #selector(buyHiveTapped), for: .touchUpInside)
        activateBtn.addTarget(self, action: #selector(activateTapped), for: .touchUpInside)
        deactivateBtn.addTarget(self, action: #selector(deactivateTapped), for: .touchUpInside)

        let buttonRow = UIStackView(arrangedSubviews: [buyAfitBtn, buyHiveBtn, activateBtn, deactivateBtn])
        buttonRow.axis = .horizontal
        buttonRow.spacing = 8
        buttonRow.distribution = .fillEqually

        container.axis = .vertical
        container.spacing = 8
        container.translatesAutoresizingMaskIntoConstraints = false
        [header, requirementsLabel, boostsLabel, infoLabel, beneficiaryField, buttonRow].forEach { container.addArrangedSubview($0) }

        contentView.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        let sep = UIView()
        sep.backgroundColor = UIColor(white: 0.9, alpha: 1)
        sep.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(sep)
        NSLayoutConstraint.activate([
            sep.heightAnchor.constraint(equalToConstant: 1),
            sep.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            sep.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    func configure(with product: MarketProduct) {
        nameLabel.text = product.name
        starsLabel.text = String(repeating: "★", count: max(product.level, 0))
        validityLabel.text = product.validity.trimmingCharacters(in: .whitespaces).isEmpty ? nil : "Valid: \(product.validity)"

        // Requirements with check/cross
        if product.requirements.isEmpty {
            requirementsLabel.text = "No Requirements"
            requirementsLabel.textColor = .darkGray
        } else {
            let lines = product.requirements.map { ($0.met ? "✓ " : "✗ ") + $0.displayText }
            requirementsLabel.attributedText = nil
            requirementsLabel.textColor = .darkGray
            requirementsLabel.text = lines.joined(separator: "\n")
        }

        boostsLabel.text = product.boosts.map { $0.displayText }.joined(separator: "\n")
        boostsLabel.isHidden = product.boosts.isEmpty

        var infoBits: [String] = []
        if product.totalBought > 0 { infoBits.append("Owned: \(product.totalBought)") }
        if product.totalConsumed > 0 { infoBits.append("Consumed: \(product.totalConsumed)") }
        if product.ownershipState != 0 { infoBits.append("Remaining boosts: \(product.remainingBoosts)") }
        infoLabel.text = infoBits.joined(separator: "   •   ")
        infoLabel.isHidden = infoBits.isEmpty

        // Prices
        buyAfitBtn.setTitle("Buy Now\n\(formatted(product.priceAfit)) AFIT", for: .normal)
        buyHiveBtn.setTitle("Buy Now\n\(formatted(product.priceHive)) HIVE", for: .normal)

        // State-driven button visibility
        let bought = product.ownershipState == 1
        let active = product.ownershipState == 2
        buyAfitBtn.isHidden = bought || active
        buyHiveBtn.isHidden = bought || active || product.priceHive <= 0
        activateBtn.isHidden = !bought
        deactivateBtn.isHidden = !active
        beneficiaryField.isHidden = !(bought && product.isFriendRewarding)

        // Eligibility gates the buy buttons
        let enabled = product.allReqtsMet
        [buyAfitBtn, buyHiveBtn].forEach { $0.isEnabled = enabled; $0.alpha = enabled ? 1.0 : 0.4 }

        loadImage(name: product.image)
    }

    private func formatted(_ value: Double) -> String {
        return String(format: "%g", (value * 1000).rounded() / 1000)
    }

    private func loadImage(name: String) {
        iconView.image = nil
        imageTask?.cancel()
        guard !name.isEmpty, let url = URL(string: ApiUrls.gadgetImageBase + name) else { return }
        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async { self?.iconView.image = image }
        }
        imageTask?.resume()
    }

    @objc private func buyAfitTapped() { onBuyAfit?() }
    @objc private func buyHiveTapped() { onBuyHive?() }
    @objc private func activateTapped() { onActivate?(beneficiaryField.text) }
    @objc private func deactivateTapped() { onDeactivate?() }
}

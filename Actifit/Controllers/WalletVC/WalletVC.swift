//
//  WalletVC.swift
//  Actifit
//
//  Created by Hitender kumar on 17/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit

class WalletVC: UIViewController {
    
    @IBOutlet weak var coreBalanceView: CommonWalletHeader!
    @IBOutlet weak var coreBalanceTableView: UITableView!
    @IBOutlet weak var hiveEngineBalanceView: CommonWalletHeader!
    @IBOutlet weak var hiveEngineBalanceTableView: UITableView!
    @IBOutlet weak var yourWalletLabel: UILabel!
    @IBOutlet weak var steemitUsernameLabel: UILabel!
    @IBOutlet weak var actifitTokensHeadingLabel: UILabel!
    @IBOutlet weak var transactionsHeadingLabel: UILabel!
    @IBOutlet weak var afitBtn: UIButton!
    @IBOutlet weak var backBtn : UIButton!
    @IBOutlet weak var usernameTextField : AFTextField!
    var afitTokens: Double = 0.0
    @IBOutlet weak var transactionsTableView : UITableView!
    var balanceCommonHeader: CommonWalletHeader?
    let viewModel = WalletViewModel()
    var hiveEngineBalanceHeader: CommonWalletHeader?
    var transactions = [Transaction]()
    var coreBalanceArray: [BalanceSections] = []
    var hiveEngineBalanceArray: [BalanceSections] = []
    var username = ""
    private var rotationAnimation: CABasicAnimation?
    private var pendingRewardsSummary = ""
    private lazy var claimRewardsButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Claim Rewards", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(named: "AppThemeColor") ?? UIColor.systemBlue
        button.layer.cornerRadius = 22
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.isHidden = true
        button.addTarget(self, action: #selector(claimRewardsTapped), for: .touchUpInside)
        return button
    }()
    private lazy var hiveHistoryButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Hive History", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = UIColor(named: "AppThemeColor") ?? UIColor.systemBlue
        button.layer.cornerRadius = 22
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        button.addTarget(self, action: #selector(hiveHistoryTapped), for: .touchUpInside)
        return button
    }()
    private enum HETokenAction { case transfer, stake, unstake }
    lazy var currentUser = {
        return User.current()
    }()
    
    //MARK: VIEW LIFE CYCLE
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        if let user = self.currentUser {
            self.username = user.steemit_username
            //self.usernameTextField.text = self.username
        }
        self.navigationController?.navigationBar.isHidden = true
    }

  private func setupRotationAnimation() {
    rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
    rotationAnimation?.fromValue = 0
    rotationAnimation?.toValue = CGFloat(Double.pi * 2)
    rotationAnimation?.duration = 1
    rotationAnimation?.repeatCount = .infinity
  }

  private func startRotation(button: UIButton?) {
    guard let rotationAnimation = rotationAnimation, let button = button else { return }
    button.layer.add(rotationAnimation, forKey: "rotationAnimation")
   // button = true
  }

  private func stopRotation(button: UIButton?) {
    guard let button = button else { return }
    button.layer.removeAnimation(forKey: "rotationAnimation")
   // isRefreshRotating = false
  }


    private func setBinding() {
        viewModel.blurtPublisher.receive(on: DispatchQueue.main).sink { balanceSection in
            if self.coreBalanceArray.contains(where: {$0.icon == balanceSection.icon}) == false {
                self.coreBalanceArray.append(balanceSection)
                self.coreBalanceTableView.reloadData()
            } else {
                self.coreBalanceArray[2].updateBalance(balance: balanceSection.balance)
                self.coreBalanceTableView.reloadData()
            }
          //  self.coreBalanceArray.removeAll()
           
        }.store(in: &viewModel.cancellables)
        
        viewModel.hivePublisher.receive(on: DispatchQueue.main).sink { balanceSection in
            if self.coreBalanceArray.contains(where: {$0.icon == balanceSection.icon}) == false {
                self.coreBalanceArray.append(balanceSection)
                self.coreBalanceTableView.reloadData()
            } else  {
                self.coreBalanceArray[1].updateBalance(balance: balanceSection.balance)
                self.coreBalanceTableView.reloadData()
            }
            
           
         
        }.store(in: &viewModel.cancellables)
        
        viewModel.hiveEngineBalancePublisher.receive(on: DispatchQueue.main).sink { hiveBalanceItems in
            self.hiveEngineBalanceArray.removeAll()
            self.hiveEngineBalanceArray.append(contentsOf: hiveBalanceItems)
            self.hiveEngineBalanceTableView.reloadData()
            self.stopRotation(button: self.balanceCommonHeader?.firstButton)
            self.stopRotation(button: self.hiveEngineBalanceHeader?.firstButton)
        }.store(in: &viewModel.cancellables)
        
        viewModel.showLoaderPublisher.receive(on: DispatchQueue.main).sink { showLoader in
          self.stopRotation(button: self.balanceCommonHeader?.firstButton)
          self.stopRotation(button: self.hiveEngineBalanceHeader?.firstButton)
          //  self.showLoader(isShowing: showLoader)
        }.store(in: &viewModel.cancellables)

        viewModel.pendingRewardsPublisher.receive(on: DispatchQueue.main).sink { [weak self] summary in
            self?.pendingRewardsSummary = summary
            self?.claimRewardsButton.isHidden = summary.isEmpty
        }.store(in: &viewModel.cancellables)

        viewModel.claimResultPublisher.receive(on: DispatchQueue.main).sink { [weak self] (success, message) in
            self?.showAlertWith(title: success ? "Success" : "Error", message: message)
            if success {
                self?.pendingRewardsSummary = ""
                self?.claimRewardsButton.isHidden = true
                self?.viewModel.refresh()
                self?.getWalletBalance()
                self?.viewModel.fetchPendingRewards()
            }
        }.store(in: &viewModel.cancellables)
    }
    
    private func setUI() {
        setupRotationAnimation()
        afitBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.transparentIcon.rawValue, size: 20), for: .normal)
        balanceCommonHeader = CommonWalletHeader.fromNib() as CommonWalletHeader
        balanceCommonHeader?.onRefreshTapped = {[weak self] in
          self?.startRotation(button: self?.balanceCommonHeader?.firstButton)

            self?.viewModel.refresh()
            
            self?.getWalletBalance()
            //TODO: refresh
        }
        hiveEngineBalanceHeader = CommonWalletHeader.fromNib() as CommonWalletHeader
        hiveEngineBalanceHeader?.onRefreshTapped = {[weak self] in
          self?.startRotation(button: self?.hiveEngineBalanceHeader?.firstButton)
          Task {
            await self?.viewModel.getHiveEngineBalance()
          }
        }
        balanceCommonHeader?.setUI(icon: NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.walletIcon.rawValue, size: 25), sectionName: "Core Balance", firstBntIcon: NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.balanceRefresh.rawValue, size: 25))
        hiveEngineBalanceHeader?.setUI(icon: NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.walletIcon.rawValue, size: 25), sectionName: "Hive-Engine Balance", firstBntIcon: NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.balanceRefresh.rawValue, size: 25))
        
        coreBalanceView.addSubview(balanceCommonHeader!)
        hiveEngineBalanceView.addSubview(hiveEngineBalanceHeader!)
        setTableViews()
        setupClaimRewardsButton()
        setBinding()
        setupInitials()
        viewModel.fetchPendingRewards()
    }

    private func setupClaimRewardsButton() {
        view.addSubview(claimRewardsButton)
        view.addSubview(hiveHistoryButton)
        NSLayoutConstraint.activate([
            claimRewardsButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            claimRewardsButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            claimRewardsButton.heightAnchor.constraint(equalToConstant: 44),
            hiveHistoryButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hiveHistoryButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            hiveHistoryButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    // MARK: - Phase 1: HE token send/stake/unstake + HIVE power up/down

    private func broadcastResult(info: Any?, successMessage: String) {
        DispatchQueue.main.async {
            self.showLoader(isShowing: false)
            var success = false
            if let response = info as? String,
               let json = (try? JSONSerialization.jsonObject(with: response.utf8Data())) as? [String: Any] {
                success = json["success"] != nil
            }
            if success {
                self.showAlertWith(title: "Success", message: successMessage)
                self.viewModel.refresh()
                self.getWalletBalance()
                Task { await self.viewModel.getHiveEngineBalance() }
            } else {
                self.showAlertWith(title: "Error", message: "Transaction failed, please try again")
            }
        }
    }

    private func presentHETokenAction(row: Int, action: HETokenAction) {
        guard let tokens = viewModel.hiveEngineBalanceToken?.result, row < tokens.count,
              let symbol = tokens[row].symbol else { return }
        let available = Double(tokens[row].balance ?? "0") ?? 0
        let staked = Double(tokens[row].stake ?? "0") ?? 0
        let activeKey = UserDefaults.standard.activeKey
        guard !activeKey.isEmpty else {
            self.showToast(message: "Please make sure to set your active key under settings"); return
        }
        guard let username = currentUser?.steemit_username.byTrimming(string: "@").lowercased() else { return }
        let maxAmount = action == .unstake ? staked : available
        let title: String
        switch action {
        case .transfer: title = "Send \(symbol)"
        case .stake: title = "Stake \(symbol)"
        case .unstake: title = "Unstake \(symbol)"
        }
        let alert = UIAlertController(title: title, message: "Available: \(maxAmount) \(symbol)", preferredStyle: .alert)
        if action == .transfer {
            alert.addTextField { $0.placeholder = "Recipient"; $0.autocapitalizationType = .none; $0.autocorrectionType = .no }
        }
        alert.addTextField { $0.placeholder = "Amount"; $0.keyboardType = .decimalPad }
        if action == .transfer {
            alert.addTextField { $0.placeholder = "Memo (optional)" }
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Confirm", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let fields = alert.textFields ?? []
            var recipient = username
            var amountText = ""
            var memo = ""
            if action == .transfer {
                recipient = fields[0].text?.trimmingCharacters(in: .whitespaces).byTrimming(string: "@").lowercased() ?? ""
                amountText = fields.count > 1 ? (fields[1].text ?? "") : ""
                memo = fields.count > 2 ? (fields[2].text ?? "") : ""
            } else {
                amountText = fields.first?.text ?? ""
            }
            let amount = Double(amountText) ?? 0
            if action == .transfer, recipient.isEmpty { self.showToast(message: "Recipient cannot be empty"); return }
            if action == .transfer, recipient == username { self.showToast(message: "Cannot send funds to self"); return }
            if amount <= 0 { self.showToast(message: "Please provide a proper positive amount"); return }
            if amount > maxAmount { self.showToast(message: "Cannot exceed your available balance"); return }
            let quantity = String(format: "%.3f", amount)
            let actionName = action == .transfer ? "transfer" : (action == .stake ? "stake" : "unstake")
            self.showLoader(isShowing: true)
            API().hiveEngineTokenOperation(user: username, symbol: symbol, to: recipient, quantity: quantity, memo: memo, action: actionName, activeKey: activeKey, completion: { [weak self] info, _ in
                self?.broadcastResult(info: info, successMessage: "\(title) completed successfully")
            }, failure: { [weak self] error in
                DispatchQueue.main.async {
                    self?.showLoader(isShowing: false)
                    self?.showToast(message: error.localizedDescription)
                }
            })
        }))
        present(alert, animated: true)
    }

    private func presentPowerUp() {
        let activeKey = UserDefaults.standard.activeKey
        guard !activeKey.isEmpty else {
            self.showToast(message: "Please make sure to set your active key under settings"); return
        }
        guard let username = currentUser?.steemit_username.byTrimming(string: "@").lowercased() else { return }
        let available = Double(viewModel.hiveAmount ?? "0") ?? 0
        let alert = UIAlertController(title: "Power Up", message: "Available: \(available) HIVE", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Amount (HIVE)"; $0.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Power Up", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let amount = Double(alert.textFields?.first?.text ?? "") ?? 0
            if amount <= 0 { self.showToast(message: "Please provide a proper positive amount"); return }
            if amount > available { self.showToast(message: "Cannot exceed your available balance"); return }
            self.showLoader(isShowing: true)
            API().powerUpHive(user: username, to: username, amount: String(format: "%.3f", amount), activeKey: activeKey, completion: { [weak self] info, _ in
                self?.broadcastResult(info: info, successMessage: "Power up completed successfully")
            }, failure: { [weak self] error in
                DispatchQueue.main.async {
                    self?.showLoader(isShowing: false)
                    self?.showToast(message: error.localizedDescription)
                }
            })
        }))
        present(alert, animated: true)
    }

    private func presentPowerDown() {
        let activeKey = UserDefaults.standard.activeKey
        guard !activeKey.isEmpty else {
            self.showToast(message: "Please make sure to set your active key under settings"); return
        }
        guard let username = currentUser?.steemit_username.byTrimming(string: "@").lowercased() else { return }
        let available = Double(viewModel.hivePowerAmount ?? "0") ?? 0
        let alert = UIAlertController(title: "Power Down", message: "Available: \(available) HP", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Amount (HP)"; $0.keyboardType = .decimalPad }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Power Down", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            let amount = Double(alert.textFields?.first?.text ?? "") ?? 0
            if amount <= 0 { self.showToast(message: "Please provide a proper positive amount"); return }
            if amount > available { self.showToast(message: "Cannot exceed your available power"); return }
            let vests = self.viewModel.powerToVests(hpValue: String(amount))
            self.showLoader(isShowing: true)
            API().powerDownHive(user: username, vests: vests, activeKey: activeKey, completion: { [weak self] info, _ in
                self?.broadcastResult(info: info, successMessage: "Power down initiated successfully")
            }, failure: { [weak self] error in
                DispatchQueue.main.async {
                    self?.showLoader(isShowing: false)
                    self?.showToast(message: error.localizedDescription)
                }
            })
        }))
        present(alert, animated: true)
    }

    @objc private func hiveHistoryTapped() {
        guard let username = currentUser?.steemit_username.byTrimming(string: "@").lowercased(), !username.isEmpty else { return }
        let historyVC = HiveHistoryViewController(username: username)
        let nav = UINavigationController(rootViewController: historyVC)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    @objc private func claimRewardsTapped() {
        let detail = pendingRewardsSummary.isEmpty ? "" : "\n\nPending: \(pendingRewardsSummary)"
        let alert = UIAlertController(title: "Claim Rewards", message: "Do you want to claim your pending rewards?\(detail)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Claim", style: .default, handler: { [weak self] _ in
            self?.viewModel.claimAllRewards()
        }))
        present(alert, animated: true)
    }
    
    private func setTableViews() {
        coreBalanceTableView.register(UINib(nibName: "ExpandedSectionCell", bundle: nil), forCellReuseIdentifier: "ExpandedSectionCell")
        hiveEngineBalanceTableView.register(UINib(nibName: "ExpandedSectionCell", bundle: nil), forCellReuseIdentifier: "ExpandedSectionCell")
        coreBalanceTableView.showsVerticalScrollIndicator = true
        hiveEngineBalanceTableView.showsVerticalScrollIndicator = true
        
    }
    

    
    
    func setupInitials()
    {
        self.applyFinishingTouchToUIElements()
        self.getWalletBalance()
        transactionsHeadingLabel.text         = "actifit_transactions_lbl".localized()
    }
    //MARK: INTERFACE BUILDER ACTIONS
    
    @IBAction func backBtnAction(_ sender : UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func checkBalanceBtnAction(_ sender : UIButton) {
        self.getWalletBalance()
        self.getTransactions()
    }
    
    //MARK: HELPERS
    
    func applyFinishingTouchToUIElements() {
        self.transactionsTableView.tableFooterView = UIView()
        self.backBtn.tintColor = UIColor.white
    }
    
    private func showLoader(message: String? = nil, isShowing: Bool) {
        if isShowing == true {
            ActifitLoader.show(title: message ?? "Loading..." , animated: true)
        } else {
            ActifitLoader.hide()
        }
    }
    
    //MARK: WEB SERVICES
    
    func getWalletBalance() {
        self.username = currentUser?.steemit_username.byTrimming(string: "@").lowercased() ?? ""
        self.view.endEditing(true)
        showLoader(message: Messages.fetching_user_balance, isShowing: true)
        APIMaster.getWalletBalanceWith(username:self.username ,completion: { [weak self] (jsonString, _ ) in
            DispatchQueue.main.async(execute: {
                self?.showLoader(isShowing: false)
            })
            self?.getTransactions()
            var actifitTokens = "Unable to fetch balance"
            
            if let jsonString = jsonString as? String {
                let data = jsonString.utf8Data()
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let jsonInfo = (json as? [String : Any]){
                        if let tokens = jsonInfo["tokens"] as? String {
                            self?.afitTokens = Double(tokens) ?? 0.0
                            actifitTokens = tokens
                            print(tokens)
                        }
                    }
                } catch {
                    print("unable to fetch tokens")
                }
               
                    DispatchQueue.main.async(execute: {
                        if self?.coreBalanceArray.isEmpty == false {
                            if self?.coreBalanceArray.contains(where: { $0.balance == "\(self?.afitTokens.truncatedToThreeDigitsAfterDecimal() ?? 0.0) AFIT"}) == false  {
                                self?.coreBalanceArray[0].updateBalance(balance:"\(self?.afitTokens.formatToThousandSeparated() ?? "") AFIT")
                        }
                        self?.coreBalanceTableView.reloadData()
                        
                    } else {
                        self?.coreBalanceArray.append(BalanceSections(icon: UIImage(named: "logo"), iconAsAwesome: nil, balance: "\(actifitTokens.formatToThreeDecimalPlaces() ?? "") AFIT", staked: nil, actionIcon: nil, actionIconAsAwesome: NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.transactionAction.rawValue, size: 25), allowExpanding: false))
                        //  self?.actfitTokensLabel.text = actifitTokens
                        self?.coreBalanceTableView.reloadData()
                    }
                })
                
            }
        }) { (error) in
            DispatchQueue.main.async(execute: {
                ActifitLoader.hide()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.showAlertWith(title: nil, message: error.localizedDescription)
            })
        }
        
    }
    
    func getTransactions() {
        APIMaster.getTransactions(username: self.username,completion: { [weak self] (jsonString, _) in
            DispatchQueue.main.async(execute: {
                ActifitLoader.hide()
            })
            if let jsonString = jsonString as? String {
                let data = jsonString.utf8Data()
                do {
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    if let jsonArray = (json as? [[String : Any]]){
                        self?.transactions = jsonArray.map({Transaction.init(info: $0)})
                    }
                } catch {
                    self?.transactions.removeAll()
                    print("unable to fetch transactions")
                }
                DispatchQueue.main.async(execute: {
                    self?.transactionsTableView.reloadData()
                })
            }
        }) { (error) in
            DispatchQueue.main.async(execute: {
                ActifitLoader.hide()
            })
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
                self.showAlertWith(title: nil, message: error.localizedDescription)
            })
        }
    }
    
    func openSendBalance() {
        self.present(SendHiveViewController.create(hive: self.viewModel.hiveAmount ?? "", hbd: self.viewModel.hbdAmount ?? "", completeTransaction: {[weak self] in
            self?.viewModel.refresh()
        }), animated: true)
    }
}

extension WalletVC : UITableViewDataSource, UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch tableView {
        case coreBalanceTableView: return coreBalanceArray.count
        case hiveEngineBalanceTableView: return hiveEngineBalanceArray.count
        default: return transactions.count
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpandedSectionCell") as? ExpandedSectionCell
        cell?.selectionStyle = .none
        switch tableView {
        case coreBalanceTableView:
            cell?.actionBtnView.isHidden = false
            let item = coreBalanceArray[indexPath.row]
            cell?.balanceSectionObject = item
            cell?.onExpandTapped = {[weak self ] expanded in
                if item.allowExpanding == true {
                    self?.coreBalanceArray[indexPath.row].updateExpansion(expand: expanded)
                    self?.coreBalanceTableView.reloadData()
                } else {
                    self?.present(SendAfitViewController.create(afit: self?.afitTokens ?? 0.0, completeTransaction: {[weak self] in
                        self?.getWalletBalance()
                    }), animated: true)
                }
                
            }
            
            cell?.onSendBtnTapped =  { [weak self] in
                self?.openSendBalance()

            }
            // HIVE row (only expandable core row) → power up / down
            if item.allowExpanding == true {
                cell?.onStakedBtnTapped = { [weak self] in self?.presentPowerUp() }
                cell?.onUnstakeBtnTapped = { [weak self] in self?.presentPowerDown() }
            }
            return cell!
        case hiveEngineBalanceTableView:
            cell?.actionBtnView.isHidden = true
            cell?.balanceSectionObject = hiveEngineBalanceArray[indexPath.row]
            cell?.onExpandTapped = {[weak self ] expanded in
                self?.hiveEngineBalanceArray[indexPath.row].updateExpansion(expand: expanded)
                self?.hiveEngineBalanceTableView.reloadData()
            }
            cell?.onSendBtnTapped = { [weak self] in self?.presentHETokenAction(row: indexPath.row, action: .transfer) }
            cell?.onStakedBtnTapped = { [weak self] in self?.presentHETokenAction(row: indexPath.row, action: .stake) }
            cell?.onUnstakeBtnTapped = { [weak self] in self?.presentHETokenAction(row: indexPath.row, action: .unstake) }
            return cell!
        default:
            let cell : TransactionTableViewCell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell", for: indexPath) as! TransactionTableViewCell
            let transaction = self.transactions[indexPath.row]
            cell.configureWith(transaction: transaction)
            return cell
            
        }
        
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch tableView {
        case hiveEngineBalanceTableView:
            let item = hiveEngineBalanceArray[indexPath.row]
            if item.isExpanded == true {
                return 140
            } else {
                return 80
            }
        case coreBalanceTableView:
            let item = coreBalanceArray[indexPath.row]
            if item.isExpanded == true {
                return 120
            } else {
                return 80
            }
        default: return UITableViewAutomaticDimension
        }
    }
}

extension Double {
    /// Formats a double to three decimal places and includes thousand separators.
    func formatToThreeDecimalPlacesWithSeparators() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        return formatter.string(from: NSNumber(value: self)) ?? "0.000"
    }

    func formatToThousandSeparated() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3

        // Format the double value
        return formatter.string(from: NSNumber(value: self)) ?? String(self)
    }
}

extension CGFloat {
    /// Formats a CGFloat to three decimal places and includes thousand separators.
    func formatToThreeDecimalPlacesWithSeparators() -> String {
        Double(self).formatToThreeDecimalPlacesWithSeparators()
    }
}

extension String {
    /// Converts a numeric string to a formatted string with thousand separators and retains the decimal part.
    func formatToThousandSeparated() -> String {
        guard let doubleValue = Double(self) else { return self }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3

        // Ensure the string is formatted with separators
        return formatter.string(from: NSNumber(value: doubleValue)) ?? self
    }
}

// MARK: - Phase 1: Hive on-chain transaction history

struct HiveHistoryItem {
    let title: String
    let amount: String
    let date: String
    let memo: String
}

/// Programmatic (storyboard-free) list of the user's on-chain Hive history
/// (transfers, power up/down, reward claims) via condenser_api.get_account_history.
final class HiveHistoryViewController: UITableViewController {
    private var items: [HiveHistoryItem] = []
    private let username: String

    init(username: String) {
        self.username = username
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Hive History"
        view.backgroundColor = .white
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeTapped))
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 64
        fetch()
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    private func fetch() {
        ActifitLoader.show(title: "Loading...", animated: true)
        API().getHiveAccountHistory(username: username, start: -1, completion: { [weak self] info, _ in
            guard let self = self else { return }
            let parsed = HiveHistoryViewController.parse(response: (info as? String)?.utf8Data() ?? Data(), username: self.username)
            DispatchQueue.main.async {
                ActifitLoader.hide()
                self.items = parsed
                self.tableView.reloadData()
            }
        }, failure: { _ in
            DispatchQueue.main.async { ActifitLoader.hide() }
        })
    }

    static func parse(response data: Data, username: String) -> [HiveHistoryItem] {
        guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let result = json["result"] as? [[Any]] else { return [] }
        var out: [HiveHistoryItem] = []
        for entry in result.reversed() {
            guard entry.count >= 2,
                  let op = entry[1] as? [String: Any],
                  let opArr = op["op"] as? [Any], opArr.count >= 2,
                  let type = opArr[0] as? String,
                  let d = opArr[1] as? [String: Any] else { continue }
            let ts = (op["timestamp"] as? String) ?? ""
            switch type {
            case "transfer":
                let to = d["to"] as? String ?? ""
                let from = d["from"] as? String ?? ""
                let amount = d["amount"] as? String ?? ""
                let memo = d["memo"] as? String ?? ""
                let outgoing = (from == username)
                out.append(HiveHistoryItem(title: outgoing ? "Transfer Out → \(to)" : "Transfer In ← \(from)",
                                           amount: (outgoing ? "-" : "+") + amount, date: ts, memo: memo))
            case "transfer_to_vesting":
                out.append(HiveHistoryItem(title: "Power Up", amount: d["amount"] as? String ?? "", date: ts, memo: ""))
            case "withdraw_vesting":
                out.append(HiveHistoryItem(title: "Power Down", amount: "-" + (d["vesting_shares"] as? String ?? ""), date: ts, memo: ""))
            case "claim_reward_balance":
                let rewardHive = d["reward_hive"] as? String ?? ""
                let rewardHbd = d["reward_hbd"] as? String ?? ""
                out.append(HiveHistoryItem(title: "Claim Rewards", amount: rewardHive, date: ts,
                                           memo: rewardHbd.isEmpty ? "" : "HBD: \(rewardHbd)"))
            default:
                continue
            }
        }
        return out
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.isEmpty ? 1 : items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "hiveHistoryCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "hiveHistoryCell")
        cell.selectionStyle = .none
        if items.isEmpty {
            cell.textLabel?.text = "No transactions found"
            cell.detailTextLabel?.text = ""
            return cell
        }
        let item = items[indexPath.row]
        cell.textLabel?.text = "\(item.title)   \(item.amount)"
        cell.textLabel?.numberOfLines = 0
        let subtitle = [item.date, item.memo].filter { !$0.isEmpty }.joined(separator: "  •  ")
        cell.detailTextLabel?.text = subtitle
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .gray
        return cell
    }
}

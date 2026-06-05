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
        setBinding()
        setupInitials()
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
            return cell!
        case hiveEngineBalanceTableView:
            cell?.actionBtnView.isHidden = true
            cell?.balanceSectionObject = hiveEngineBalanceArray[indexPath.row]
            cell?.onExpandTapped = {[weak self ] expanded in
                self?.hiveEngineBalanceArray[indexPath.row].updateExpansion(expand: expanded)
                self?.hiveEngineBalanceTableView.reloadData()
            }
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

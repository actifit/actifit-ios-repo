//
//  WalletViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 10/11/2023.
//

import Foundation
import UIKit
import Combine
class WalletViewModel {
    let httpClient = HTTPClient()
    var blurtObject: BlurtResponse?
    var allHiveEngineTokens: AllHiveEngineTokensResponse?
    var hiveEngineBalanceToken: HiveEngineBalanceResponse?
    var hiveObject: HiveObject?
    var chainInfo: BlockchainInfoResponse?
    var cancellables = Set<AnyCancellable>()
    var hiveAmount: String?
    var hbdAmount: String?
    var hivePowerAmount: String?
    private let showLoaderSubject =  PassthroughSubject<Bool, Never>()
    var showLoaderPublisher: AnyPublisher<Bool, Never> {
        return showLoaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    private let hiveSubject =  PassthroughSubject<BalanceSections, Never>()
    var hivePublisher: AnyPublisher<BalanceSections, Never> {
        return hiveSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    private let blurtSubject = PassthroughSubject<BalanceSections,Never>()
    var blurtPublisher: AnyPublisher<BalanceSections, Never> {
        return blurtSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    private let hiveEngineBalanceSubject =  PassthroughSubject<[BalanceSections], Never>()
    var hiveEngineBalancePublisher: AnyPublisher<[BalanceSections], Never> {
        return hiveEngineBalanceSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    init() {
      Task {
          await self.getChainInfo()

      }

    }
    
    func refresh() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.getAccountData()
        })
    }
    
    func getAccountData() {
        guard let username = User.current()?.steemit_username else { return }
        
        let dispatchGroup = DispatchGroup()

        API().getAccountData(username: username) { info, statusCode in
            if let response = info as? String {
                print(response)
                let data = response.utf8Data()
                let decoder = JSONDecoder()

                dispatchGroup.enter()
                DispatchQueue.global().async {
                    defer { dispatchGroup.leave() }
                    
                    do {
                        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]

                        if json?["HIVE"] is [String: Any] {
                            self.hiveObject = try decoder.decode(HiveObject.self, from: data)
                            self.generateHPValues()
                        }

                        if json?["BLURT"] is [String: Any] {
                            self.blurtObject = try? decoder.decode(BlurtResponse.self, from: data)
                            self.generateBlurt()
                        }
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            }
        } failure: { error in
            print(error.localizedDescription)
        }

        dispatchGroup.notify(queue: .main) {
          
        }
    }

    
    
  func getHiveEngineBalance() async {
    guard let username = User.current()?.steemit_username else { return }
    let balanceModel = await HTTPClient().getHiveEngineBalance(username: username, tableType: TableType.balances)
    switch balanceModel {
    case .success(let success):
      self.hiveEngineBalanceToken = success
      Task {
        await self.getAllHiveEngineTokens()
      }
    case .failure(let failure):
      print("Error decoding JSON: \(failure.localizedDescription)")

    }
  }
    
    func generateHiveEngineBalanceTableValues() {
        var balanceItems: [BalanceSections] = []
        self.hiveEngineBalanceToken?.result?.forEach({ tokenInfo in
            let symbol = self.getTokenURL(symbol: tokenInfo.symbol ?? "")
            var iconImg: UIImage? = nil
            if symbol == "" {
                iconImg = self.generateTokenImg(symbol: tokenInfo.symbol ?? "")
            }
            let object = BalanceSections(icon: iconImg, iconAsAwesome: nil, balance: "\(tokenInfo.balance?.formatToThreeDecimalPlaces() ?? "")  \(tokenInfo.symbol ?? "")", staked: "\(tokenInfo.stake?.formatToThreeDecimalPlaces() ?? "")  \(tokenInfo.symbol ?? "")", actionIcon: nil, actionIconAsAwesome: NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.expandAction.rawValue , size: 25), allowExpanding: true, iconURL: symbol)
            balanceItems.append(object)
        })
        self.hiveEngineBalanceSubject.send(balanceItems)
    }
    
    func getTokenURL(symbol: String) -> String {
        if var token = allHiveEngineTokens?.result?.filter({$0.symbol  == symbol}).first {
            return token.extractIconURL()
        } 
            return ""
    }
        
    func generateTokenImg(symbol: String) -> UIImage {
        var generatedImage: UIImage?
        if Thread.isMainThread {
                generatedImage = createImage(symbol: symbol)
        } else {
            DispatchQueue.main.sync {
                generatedImage = createImage(symbol: symbol)
            }
        }
        return generatedImage ?? UIImage()
    }

    
    private func createImage(symbol: String) -> UIImage {
        let myLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        myLabel.clipsToBounds = true
        myLabel.layer.cornerRadius = myLabel.frame.width / 2
        myLabel.layer.borderWidth = 1
        myLabel.textAlignment = .center
        let symbolLetter = symbol.prefix(1)
        myLabel.text = String(symbolLetter)
        myLabel.textColor = .black
        myLabel.backgroundColor = .white

        return myLabel.asImage()
    }
    
    func getAllHiveEngineTokens() async {//users tokens
        guard let username = User.current()?.steemit_username else { return }
      let hiveEngines = await HTTPClient().getHiveEngineToken(username: username, tableType: TableType.tokens)
      switch hiveEngines {
      case .success(let success):
        self.allHiveEngineTokens = success
        self.generateHiveEngineBalanceTableValues()
      case .failure(let failure):
        print("Error decoding JSON: \(failure.localizedDescription)")
      }
    }
    
    
    func getChainInfo() async {
      showLoaderSubject.send(true)
      let chainInfo = await HTTPClient().getChainInfo()
      switch chainInfo {
      case .success(let success):
          self.chainInfo = success
          Task {
              await self.getHiveEngineBalance()

          }
          self.getAccountData()

      case .failure(let failure):
        print(failure.localizedDescription)
      }
    }
    
    
    func generateHPValues() {
        let hpBalanceVal = vestsToPower(vestsValue: self.hiveObject?.hive.vesting_shares ?? "", powerType: .hive)
        let delegatedVal = vestsToPower(vestsValue: self.hiveObject?.hive.delegated_vesting_shares ?? "", powerType: .hive)
        let unstakingVal = vestsToPower(vestsValue: self.hiveObject?.hive.vesting_withdraw_rate ?? "", powerType: .hive)

        let hpBalance = CGFloat(Double(hpBalanceVal.stringWithoutCommas()) ?? 0).truncatedToThreeDigitsAfterDecimal()
        let delegated = CGFloat(Double(delegatedVal.stringWithoutCommas()) ?? 0).truncatedToThreeDigitsAfterDecimal()
        let unstaking = CGFloat(Double(unstakingVal.stringWithoutCommas()) ?? 0).truncatedToThreeDigitsAfterDecimal()

        let ownedPower: CGFloat = hpBalance - delegated - unstaking
        
        let ownedPowerVal = "\(ownedPower.truncatedToThreeDigitsAfterDecimal())"
        self.hivePowerAmount = ownedPowerVal
        let fullPower = vestsToPower(vestsValue: self.hiveObject?.hive.post_voting_power ?? "", powerType: .hive)
        var finalString =  "\(ownedPowerVal.formatToThousandSeparated())HP \(fullPower.formatToThreeDecimalPlacesWithSeparators())HP"

        self.hiveSubject.send(BalanceSections(icon: UIImage(named: "hive-icon"), iconAsAwesome: nil, balance: "\(self.hiveObject?.hive.balance?.formatToThreeDecimalPlaces() ?? "")\n\(self.hiveObject?.hive.hbd_balance?.formatToThreeDecimalPlaces() ?? "")", staked: finalString, actionIcon: nil, actionIconAsAwesome: NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.expandAction.rawValue, size: 25), allowExpanding: true))
        self.hiveAmount = (self.hiveObject?.hive.balance ?? "").extractDouble()
        self.hbdAmount = (self.hiveObject?.hive.hbd_balance ?? "").extractDouble()
        self.showLoaderSubject.send(false)
     
    }
    
    func generateBlurt() {
        let blurtBalance = self.blurtObject?.blurt.balance
        let bpBalance = "\(vestsToPower(vestsValue: self.blurtObject?.blurt.vestingShares ?? "", powerType: .blurt)) BP"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.blurtSubject.send(BalanceSections(icon: UIImage(named: "blurt-icon"), iconAsAwesome: nil, balance: blurtBalance ?? "", staked: bpBalance, actionIcon: nil, actionIconAsAwesome:nil, allowExpanding: false ))
        })
    
    }
    
    // MARK: - Phase 1: Claim rewards

    private let claimResultSubject = PassthroughSubject<(Bool, String), Never>()
    var claimResultPublisher: AnyPublisher<(Bool, String), Never> {
        return claimResultSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    private let pendingRewardsSubject = PassthroughSubject<String, Never>()
    var pendingRewardsPublisher: AnyPublisher<String, Never> {
        return pendingRewardsSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }

    /// Fetches pending author/curation rewards and emits a human-readable summary ("" if none).
    func fetchPendingRewards() {
        guard let username = User.current()?.steemit_username else { return }
        API().getPendingRewards(username: username, completion: { info, _ in
            guard let response = info as? String else { return }
            let data = response.utf8Data()
            guard let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
                  let rewards = json["pendingRewards"] as? [String: Any] else {
                self.pendingRewardsSubject.send("")
                return
            }
            self.pendingRewardsSubject.send(self.summarizePendingRewards(rewards))
        }, failure: { error in
            print(error.localizedDescription)
        })
    }

    private func summarizePendingRewards(_ rewards: [String: Any]) -> String {
        var parts: [String] = []
        func add(_ value: Any?, _ label: String) {
            if let s = value as? String, let d = Double(s.extractDouble() ?? "0"), d > 0 {
                parts.append("\(d.truncatedToThreeDigitsAfterDecimal()) \(label)")
            } else if let d = value as? Double, d > 0 {
                parts.append("\(d.truncatedToThreeDigitsAfterDecimal()) \(label)")
            }
        }
        add(rewards["reward_hive_balance"] ?? rewards["HIVE"], "HIVE")
        add(rewards["reward_hbd_balance"] ?? rewards["HBD"], "HBD")
        add(rewards["reward_vesting_hive"] ?? rewards["HP"], "HP")
        return parts.joined(separator: ", ")
    }

    /// Claims all pending rewards. Emits (success, message).
    func claimAllRewards() {
        guard let username = User.current()?.steemit_username else { return }
        showLoaderSubject.send(true)
        API().claimRewards(username: username, completion: { info, _ in
            self.showLoaderSubject.send(false)
            guard let response = info as? String else {
                self.claimResultSubject.send((false, "Unable to claim rewards, please try again"))
                return
            }
            let data = response.utf8Data()
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let hive = json?["hive"] as? [String: Any]
            if hive?["success"] != nil {
                self.claimResultSubject.send((true, "Rewards claimed successfully"))
            } else if let err = hive?["error"] as? String, !err.isEmpty {
                self.claimResultSubject.send((false, err))
            } else {
                self.claimResultSubject.send((false, "Unable to claim rewards, please try again"))
            }
        }, failure: { error in
            self.showLoaderSubject.send(false)
            self.claimResultSubject.send((false, error.localizedDescription))
        })
    }

    /// Inverse of `vestsToPower` — converts an HP amount to VESTS (for power-down).
    func powerToVests(hpValue: String, powerType: PowerType = .hive) -> String {
        let vestingFund = powerType == .hive ? (self.chainInfo?.hive?.totalVestingFundHive ?? "") : (self.chainInfo?.blurt?.totalVestingFundHive ?? "")
        let totalShares = powerType == .hive ? (self.chainInfo?.hive?.totalVestingShares ?? "") : (self.chainInfo?.blurt?.totalVestingShares ?? "")
        let fund = Double(vestingFund.split(separator: " ").first.map(String.init) ?? "0") ?? 0
        let shares = Double(totalShares.split(separator: " ").first.map(String.init) ?? "0") ?? 0
        let hp = Double(hpValue.replacingOccurrences(of: ",", with: "")) ?? 0
        guard fund > 0 else { return "0.000000" }
        let vests = (hp * shares) / fund
        return String(format: "%.6f", vests)
    }

    func vestsToPower(vestsValue: String, powerType: PowerType) -> CGFloat {
        var powerVal: CGFloat = 0.0
        var totalVests: CGFloat = 1.0
        var vests: CGFloat = 0.0

        let vestingFund = powerType == .hive ?  self.chainInfo?.hive?.totalVestingFundHive ?? "" : self.chainInfo?.blurt?.totalVestingFundHive ?? ""
        let entries = vestingFund.split(separator: " ")
        powerVal = CGFloat(Double(entries.first ?? "0.0")!)

        let vestsList = (powerType == .hive ? self.chainInfo?.hive?.totalVestingShares ?? "" : self.chainInfo?.blurt?.totalVestingShares ?? "").split(separator: " ")
        totalVests = CGFloat(Double(vestsList.first ?? "0.0")!)

        let newVestsValue = vestsValue.split(separator: " ").first
        vests = CGFloat(Double(newVestsValue ?? "0.0")!)
        return ((powerVal * vests) / totalVests).truncatedToThreeDigitsAfterDecimal()
    }
    
}

enum PowerType {
    case hive
    case blurt
}


struct BalanceSections {
    var generatedIcon: UIImage?
    let iconURL: String?
    let allowExpanding: Bool?
    var isExpanded: Bool = false
    let icon: UIImage?
    let iconAsAwesome: NSAttributedString?
    var balance: String?
    let staked: String?
    let actionIcon: UIImage?
    let actionIconAsAwesome: NSAttributedString?
    init(icon: UIImage?, iconAsAwesome: NSAttributedString?, balance: String?, staked: String?, actionIcon: UIImage?, actionIconAsAwesome: NSAttributedString?, allowExpanding: Bool?, iconURL: String? = nil) {
        self.icon = icon
        self.iconAsAwesome = iconAsAwesome
        self.balance = balance
        self.staked = staked
        self.actionIcon = actionIcon
        self.actionIconAsAwesome = actionIconAsAwesome
        self.allowExpanding = allowExpanding
        self.iconURL = iconURL
    }
    
    mutating func updateExpansion(expand: Bool) {
        self.isExpanded = expand
    }
    
    mutating func updateGeneratedIcon(icon: UIImage) {
        self.generatedIcon = icon
    }
    
    mutating func updateBalance(balance: String?) {
        self.balance = balance
    }
}

extension CGFloat {
    func stringWithoutCommas() -> String {
        return String(describing: self).replacingOccurrences(of: ",", with: "")
    }
}

extension CGFloat {
    func truncatedToThreeDigitsAfterDecimal() -> CGFloat {
        let stringValue = String(format: "%.6f", self)

        if let decimalIndex = stringValue.firstIndex(of: ".") {
            let endIndex = stringValue.index(decimalIndex, offsetBy: 4)
            let truncatedString = stringValue[..<endIndex]

            let truncatedValue = CGFloat(Double(truncatedString) ?? 0.000)
                return truncatedValue
        }
        return self
    }
}

extension String {
    func extractDouble() -> String? {
        // Split the string by whitespaces
        let components = self.components(separatedBy: .whitespaces)
        
        // Find the first component that can be converted to a Double
        if let doubleString = components.first {
            return doubleString
        }
        
        return nil
    }
}

extension Double {
    func truncatedToThreeDigitsAfterDecimal() -> Double {
        let stringValue = String(format: "%.6f", self) // Format to six decimal places initially

        if let decimalIndex = stringValue.firstIndex(of: ".") {
            let endIndex = stringValue.index(decimalIndex, offsetBy: 4) // 4 includes the decimal point and 3 digits
            let truncatedString = stringValue[..<endIndex]

            return Double(truncatedString) ?? 0.000
        }
        return self
    }
}


extension UILabel {
    func asImage() -> UIImage {
           UIGraphicsBeginImageContextWithOptions(bounds.size, false, 0.0)
           defer { UIGraphicsEndImageContext() }

           let context = UIGraphicsGetCurrentContext()!

           // Set background color to white
           UIColor.white.setFill()
           context.fill(bounds)

           // Draw rounded rectangle
           let roundedRect = UIBezierPath(roundedRect: bounds, cornerRadius: layer.cornerRadius)
           context.addPath(roundedRect.cgPath)
           context.clip()

           // Render label into the context
           layer.render(in: context)

           // Get the image from the context
           return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
       }
}

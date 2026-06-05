//
//  AdsOptionsViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 28/10/2023.
//

import UIKit
import GoogleMobileAds
class AdsOptionsViewController: UIViewController {
  @IBOutlet weak var mainView: UIView!

  @IBOutlet weak var descriptionLabel: UILabel!
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!

  @IBOutlet weak var freeRewardBtn: UIButton!
  var tier = 1
  @IBOutlet weak var rewardImageView: UIImageView!
  @IBOutlet weak var closeBtn: UIButton!
  @IBOutlet weak var tenKButton: UIButton!
  @IBOutlet weak var sevenKBtn: UIButton!
  @IBOutlet weak var fiveKBtn: UIButton!
  var prizeType: PrizeButtonType? = nil
  var daysSteps: Int! = 0
  var animateButton = true
  var isAddSuccessfullyCompleted: Bool = false
  var onPrizeSelection:((PrizeButtonType) -> ())?
  var rewardAd: GADRewardedAd?
  var bodyData: [ExtraPrizesModel] = {
    return [ExtraPrizesModel(title: NSLocalizedString("free_rewards", comment: ""), descript:  NSLocalizedString("free_rewards_Details", comment: "")), ExtraPrizesModel(title:  NSLocalizedString("5k_extra_reward", comment: ""), descript: NSLocalizedString("5k_reward_details", comment: "")), ExtraPrizesModel(title: NSLocalizedString("7k_extra_reward", comment: ""), descript: NSLocalizedString("7k_reward_details", comment: "")), ExtraPrizesModel(title:  NSLocalizedString("10k_extra_reward", comment: ""), descript:  NSLocalizedString("10_reward_details", comment: ""))]
  }()
  var latestFreeReward: String {
    return UserDefaults.standard.freeReward
  }

  var latestFiveKReward: String {
    return UserDefaults.standard.fiveKReward
  }

  var latestSevenKReward: String {
    return UserDefaults.standard.sevenKReward
  }

  var latestTenKReward: String {
    return UserDefaults.standard.tenKReward
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.setUI()
  }

  private func generateNewAd(isFirstTime: Bool) {
    if rewardAd == nil || isFirstTime == false {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
        SwiftLoader().sharedInstance.show(animated: true)
        GADRewardedAd.load(withAdUnitID: "ca-app-pub-2770948859841315/8644692724", request: GADRequest()) { ad, error in
            if let error = error {
                return
            }
          SwiftLoader().sharedInstance.hide()
          self.rewardAd = ad
        }
      })
    }
  }

  private func setButtonTitles() {
    closeBtn.setTitle(NSLocalizedString("close_upper", comment: ""), for: .normal)
    freeRewardBtn.setTitle(NSLocalizedString("free_rewards", comment: ""), for: .normal)
    fiveKBtn.setTitle(NSLocalizedString("5k_extra_reward", comment: ""), for: .normal)
    sevenKBtn.setTitle(NSLocalizedString("7k_extra_reward", comment: ""), for: .normal)
    tenKButton.setTitle(NSLocalizedString("10k_extra_reward", comment: ""), for: .normal)
    freeRewardBtn.layer.cornerRadius = 5
    freeRewardBtn.clipsToBounds = true

    fiveKBtn.layer.cornerRadius = 5
    fiveKBtn.clipsToBounds = true

    sevenKBtn.layer.cornerRadius = 5
    sevenKBtn.clipsToBounds = true

    tenKButton.layer.cornerRadius = 5
    tenKButton.clipsToBounds = true
  }

  @IBAction func rewardBtnTapped(_ sender: UIButton) {
    if let type = generatePrizeType(tag: sender.tag) {
      prizeType = type
      handlePrizeSelection(prize: prizeType!, buttonText: sender.titleLabel?.text)
    }
  }

  private func generatePrizeType(tag: Int) -> PrizeButtonType? {
    switch tag {
    case 1: return .free
    case 2: return .five
    case 3: return .seven
    case 4: return .ten
    default: return nil
    }
  }

  static func create(ad: GADRewardedAd? = nil, steps: Int, animateButton: Bool, prizeSelection: ((PrizeButtonType) ->())?) -> AdsOptionsViewController {
    let vc = UIStoryboard(name: "TransparetPopup", bundle: nil).instantiateViewController(withIdentifier: "AdsOptionsViewController") as! AdsOptionsViewController
    vc.onPrizeSelection = prizeSelection
    vc.daysSteps = steps
    vc.animateButton = animateButton
    vc.rewardAd = ad
    vc.modalPresentationStyle = .overFullScreen
    return vc
  }

  private func animateButtonCall() {
    if animateButton {
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
        if self.daysSteps >= 0 && UserDefaults.standard.freeReward == "" {
          self.setButtonAnimation(self.freeRewardBtn)
        }
        if self.daysSteps  >= 5000 && UserDefaults.standard.fiveKReward == "" {
          self.setButtonAnimation(self.fiveKBtn)
        }
        if self.daysSteps >= 7000 && UserDefaults.standard.sevenKReward == "" {
          self.setButtonAnimation(self.sevenKBtn)
        }
        if self.daysSteps >= 10000 && UserDefaults.standard.tenKReward == "" {
          self.setButtonAnimation(self.tenKButton)
        }
      })
    }
  }

  private func setUI() {
    setButtonTitles()
    freeRewardBtn.tag = 1
    fiveKBtn.tag = 2
    sevenKBtn.tag = 3
    tenKButton.tag = 4
    titleLabel.text = NSLocalizedString("earn_extra_prizes_title", comment: "")
    descriptionLabel.text =  NSLocalizedString("earn_extra_prizes_descript", comment: "")

    mainView.layer.cornerRadius = 5
    mainView.clipsToBounds = true
    tableView.register(UINib(nibName: "BottomButtonsCell", bundle: nil), forCellReuseIdentifier: "BottomButtonsCell")
    tableView.register(UINib(nibName: "BodyCell", bundle: nil), forCellReuseIdentifier: "BodyCell")
    tableView.separatorStyle = .none
    setImageUI()
    animateButtonCall()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
      if self.latestFreeReward != "" {
        self.updateButtonWithPrize(prizeType: .free)
      }
      if self.latestFiveKReward != "" {
        self.updateButtonWithPrize(prizeType: .five)
      }
      if self.latestSevenKReward != "" {
        self.updateButtonWithPrize(prizeType: .seven)
      }
      if self.latestTenKReward != "" {
        self.updateButtonWithPrize(prizeType: .ten)
      }
    })
  }

  private func setImageUI() {
    rewardImageView.image = generateImageFromUnicode()
  }

  private func generateImageFromUnicode() -> UIImage? {
    let unicodeValue = 127873

    if let emojiImage = imageFromUnicode(unicodeValue) {
      return emojiImage
    }
    return nil
  }

  func imageFromUnicode(_ unicodeValue: Int) -> UIImage? {
    // Create a string from the Unicode value
    let unicodeString = String(UnicodeScalar(unicodeValue)!)

    // Create an attributed string with the Unicode string
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 35)
    ]
    let attributedString = NSAttributedString(string: unicodeString, attributes: attributes)

    // Get an image from the attributed string
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 40, height: 40), false, 0.0)
    attributedString.draw(at: .zero)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image
  }


  @IBAction func closeBtnTapped(_ sender: Any) {
    onPrizeSelection?(PrizeButtonType.stringType(type:UserDefaults.standard.latestPrizeType))
    dismiss(animated: true)
  }


    //TODO: remove the error popups
  private func updateButtonWithPrize(prizeType: PrizeButtonType) {
    if prizeType ==  .free {
      if UserDefaults.standard.freeReward != "" {
        let title = "\(NSLocalizedString("free_rewards", comment: ""))\n\(UserDefaults.standard.freeReward) AFIT"
        freeRewardBtn.setTitle(NSLocalizedString(title, comment: ""), for: .normal)
        stopScaling(button: freeRewardBtn)
      } else {
          //TODO: remove before uploading to production
          showToastMessage(text: "The free reward is not been saved locally")
      }
    }
    if prizeType ==  .five {
      if UserDefaults.standard.fiveKReward != "" {
        let title = "\(NSLocalizedString("5k_extra_reward", comment: ""))\n\(UserDefaults.standard.fiveKReward) AFIT"
        fiveKBtn.setTitle(NSLocalizedString(title, comment: ""), for: .normal)
        stopScaling(button: fiveKBtn)
      } else {
          //TODO: remove before uploading to production
          showToastMessage(text: "The 5K reward is not been saved locally")
      }

    }
    if prizeType ==  .seven {
      if UserDefaults.standard.sevenKReward != "" {
        let title = "\(NSLocalizedString("7k_extra_reward", comment: ""))\n\(UserDefaults.standard.sevenKReward) AFIT"
        sevenKBtn.setTitle(NSLocalizedString(title, comment: ""), for: .normal)
        stopScaling(button: sevenKBtn)
      } else {
          //TODO: remove before uploading to production
          showToastMessage(text: "The 7K reward is not been saved locally")
      }
    }
    if prizeType ==  .ten {
      if UserDefaults.standard.tenKReward != "" {
        let title = "\(NSLocalizedString("10k_extra_reward", comment: ""))\n\(UserDefaults.standard.tenKReward) AFIT"
        tenKButton.setTitle(NSLocalizedString(title, comment: ""), for: .normal)
        stopScaling(button: tenKButton)
      } else {
          //TODO: remove before uploading to production
          showToastMessage(text: "The 10K reward is not been saved locally")
      }
    }
  }

  func setButtonAnimation(_ button: UIButton) {
    UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: {
      button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
    }, completion: nil)

  }

  func stopScaling(button: UIButton) {
    button.layer.removeAllAnimations()
    button.transform = CGAffineTransform.identity
  }


  func handlePrizeSelection(prize: PrizeButtonType, buttonText: String?) {
    if prize == .close {
      dismiss(animated: true)
      return
    }

    switch prize {
    case .free:
      if  daysSteps >= 0 && prize == .free {
        if UserDefaults.standard.freeReward == "" {
          showAd(buttonText: buttonText ?? "", prize: prize)
        } else {
          showToast(message: NSLocalizedString("already_climed_reward", comment: ""))
        }
      } else {
        showToast(message: NSLocalizedString("not_eligible_for_reward", comment: ""))
      }
    case .five:
      if daysSteps >= 5000 && prize == .five {
        if UserDefaults.standard.fiveKReward == "" {
          showAd(buttonText: buttonText ?? "", prize: prize)
        } else {
          showToast(message: NSLocalizedString("already_climed_reward", comment: ""))
        }
      } else {
        showToast(message: NSLocalizedString("not_eligible_for_reward", comment: ""))
      }
    case .seven:

      if daysSteps >= 7000 && prize == .seven  {
        if UserDefaults.standard.sevenKReward == "" {
          showAd(buttonText: buttonText ?? "", prize: prize)
        } else {
          showToast(message: NSLocalizedString("already_climed_reward", comment: ""))
        }
      } else {
        showToast(message: NSLocalizedString("not_eligible_for_reward", comment: ""))
      }
    case .ten:
      if self.daysSteps >= 10000 && prize == .ten {
        if UserDefaults.standard.tenKReward == "" {
          showAd(buttonText: buttonText ?? "", prize: prize)
        }
        else {
          showToast(message: NSLocalizedString("already_climed_reward", comment: ""))
        }
      } else {
        showToast(message: NSLocalizedString("not_eligible_for_reward", comment: ""))
      }
    default: showToast(message: NSLocalizedString("not_eligible_for_reward", comment: ""))
    }

  }

  private func generateTier() -> Int {
    switch prizeType {
    case .free: tier = 1
    case .five: tier = 2
    case .seven: tier = 3
    case .ten: tier = 4
    default: return 1
    }
    return tier
  }

//TODO: remove the else case 
  private func showAd(buttonText: String, prize: PrizeButtonType) {
    UserDefaults.standard.getLatestAdDate = Date().currentDay()
    let userName = User.current()?.steemit_username
    let vc = AdsViewController()
    vc.rewardedAd = rewardAd
    vc.buttonText = buttonText
    vc.userName = userName
    vc.tier = generateTier()
    vc.prizeType = prize
    vc.onAdCompletion = { [weak self] completed, pType , rewardAmount in
        guard let self = self else {return }
        self.hideProgressIndicator()
      if completed && pType != nil {
        UserDefaults.standard.latestPrizeType = pType!.toString()
        // self?.generateNewAd(isFirstTime: false)
        let claimed = NSLocalizedString("claimed_reward", comment: "")
        let formattedString = String(format: claimed, rewardAmount)
        self.updateButtonWithPrize(prizeType: pType!)
        self.showToastMessage(text: formattedString)
        UserDefaults.standard.getLatestAdDate = Date().currentDay()
      } else {
          self.showToastMessage(text: " ad completed? \(completed),  reward amount? \(rewardAmount) ad type: \(pType)")
      }
      self.generateNewAd(isFirstTime: false)
      self.animateButton = false
      self.prizeType = pType
      self.isAddSuccessfullyCompleted = completed
      self.tableView.reloadData()
    }
    self.showProgressIndicator()
    present(vc, animated: true)
  }

  private func showToastMessage(text: String) {
    showToast(message: text)
  }


}

extension AdsOptionsViewController: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return 4
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let bodyCell = tableView.dequeueReusableCell(withIdentifier: "BodyCell") as? BodyCell
    bodyCell?.bodyDataModel = bodyData[indexPath.row]
    return bodyCell!

  }

}

struct ExtraPrizesModel {
  let title: String
  let descript: String
  init(title: String, descript: String) {
    self.title = title
    self.descript = descript
  }
}

enum PrizeButtonType {
  case close
  case free
  case five
  case seven
  case ten
  func toString() -> String {
    switch self {
    case .close:
      return "close"
    case .free:
      return "free"
    case .five:
      return "five"
    case .seven:
      return "seven"
    case .ten:
      return "ten"
    }
  }
  static func stringType(type: String) -> PrizeButtonType {
    switch type {
    case "free" : return .free
    case "five" : return .five
    case "seven" : return .seven
    case "ten" : return .ten
    default: return .close
    }
  }

}

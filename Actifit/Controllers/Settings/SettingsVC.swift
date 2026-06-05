//
//  SettingsVC.swift
//  Actifit
//
//  Created by Hitender kumar on 20/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit
import DropDown
import Localizr_swift

class SettingsVC: UIViewController {

  @IBOutlet weak var logoutButton: UIButton!

  @IBOutlet weak var mainHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var scrollView: UIScrollView!
  @IBOutlet weak var fundsPasswordTextField: UITextField!
  @IBOutlet weak var activeKeyTextField: UITextField!
  @IBOutlet weak var settingsLabel: UILabel!
  @IBOutlet weak var activityDataSource: UILabel!
  @IBOutlet weak var phoneSensorLabel: UILabel!
  @IBOutlet weak var fitBitLabel: UILabel!
  @IBOutlet weak var fitBitSettingHeadingLabel: UILabel!
  @IBOutlet weak var fetchMeasurementLabel: UILabel!
  @IBOutlet weak var fetchStepsLabel: UILabel!
  @IBOutlet weak var steemPostPayoutLabel: UILabel!
  @IBOutlet weak var fiftyPercentLabel: UILabel!
  @IBOutlet weak var hundredPercentLabel: UILabel!
  @IBOutlet weak var languageTitleLabel: UILabel!
  @IBOutlet weak var measurementSystemTitleLabel: UILabel!
  @IBOutlet weak var metricLabel: UILabel!
  @IBOutlet weak var USLabel: UILabel!
  @IBOutlet weak var donateToCharityLabel: UILabel!
  @IBOutlet weak var donateRewardToCharity: UILabel!
  @IBOutlet weak var availabelCharitiesLabel: UILabel!
  @IBOutlet weak var charityInfo: UILabel!
  @IBOutlet weak var dailyReminderPost: UILabel!
  @IBOutlet weak var remindMeToPostLabel: UILabel!
  @IBOutlet weak var versionLabel: UILabel!
  @IBOutlet weak var saveSettings: UIButton!
  @IBOutlet weak var firstNotificationLbl: UILabel!
  @IBOutlet weak var secondNotificationLbl: UILabel!
  @IBOutlet weak var thirdnotificationLbl: UILabel!
  @IBOutlet weak var forthnotificationLbl: UILabel!
  @IBOutlet weak var fifthNotificationLbl: UILabel!
  @IBOutlet weak var sixthNotificationLbl: UILabel!

  @IBOutlet weak var notificationsStack: UIStackView!
  @IBOutlet weak var mainContainerInScrollViewHeightConstraint: NSLayoutConstraint!

  @IBOutlet weak var dailyTipButton: UIButton!
  @IBOutlet weak var languageButton: UIButton!
  @IBOutlet weak var backBtn : UIButton!
  @IBOutlet weak var metricMeasurementSystemBtn : UIButton!
  @IBOutlet weak var USMeasurementSystemBtn : UIButton!
  @IBOutlet weak var deviceSensortSystemBtn : UIButton!
  @IBOutlet weak var fitBitSystemBtn : UIButton!
  @IBOutlet weak var fullPaySystemBtn : UIButton!
  @IBOutlet weak var sbdSPPaySystemBtn : UIButton!

  @IBOutlet weak var donateTopCharityBtn : UIButton!
  @IBOutlet weak var metricDotView : UIView!
  @IBOutlet weak var usDotView : UIView!

  @IBOutlet weak var deviceSensorDotView : UIView!
  @IBOutlet weak var fitBitDotView : UIView!

  @IBOutlet weak var fullPayDotView : UIView!
  @IBOutlet weak var sbdSPPayDotView : UIView!

  @IBOutlet weak var charityLinkTextView : UITextView!
  @IBOutlet weak var saveSettingsBtn : UIButton!
  @IBOutlet weak var showCharityBtn : UIButton!

  @IBOutlet weak var lblVersion : UILabel!

  @IBOutlet weak var metricMeasurementSystemBtnDotViewWidthConstraint : NSLayoutConstraint!
  @IBOutlet weak var metricMeasurementSystemBtnDotViewHeightConstraint : NSLayoutConstraint!
  @IBOutlet weak var USMeasurementSystemBtnDotViewWidthConstraint  : NSLayoutConstraint!
  @IBOutlet weak var USMeasurementSystemBtnDotViewHeightConstraint  : NSLayoutConstraint!

  @IBOutlet weak var deviceSensorSystemBtnDotViewWidthConstraint : NSLayoutConstraint!
  @IBOutlet weak var deviceSensorSystemBtnDotViewHeightConstraint : NSLayoutConstraint!
  @IBOutlet weak var fitBitSystemBtnDotViewWidthConstraint  : NSLayoutConstraint!
  @IBOutlet weak var fitBitSystemBtnDotViewHeightConstraint  : NSLayoutConstraint!

  @IBOutlet weak var fullPaySystemBtnDotViewWidthConstraint : NSLayoutConstraint!
  @IBOutlet weak var fullPaySystemBtnDotViewHeightConstraint : NSLayoutConstraint!
  @IBOutlet weak var sbdSPPaySystemBtnDotViewWidthConstraint  : NSLayoutConstraint!
  @IBOutlet weak var sbdSPPaySystemBtnDotViewHeightConstraint  : NSLayoutConstraint!

  @IBOutlet weak var fitBitSettingView: UIView!
  @IBOutlet weak var fitBitSettingHeightCons: NSLayoutConstraint!

  @IBOutlet weak var fetchMeasurements: UIButton!
  @IBOutlet weak var fetchSteps: UIButton!

  @IBOutlet weak var remindBtn : UIButton!
  @IBOutlet weak var timePicker : UIDatePicker!


  @IBOutlet weak var steamChainRedDot: UIView!
  @IBOutlet weak var blurtChainRedDot: UIView!
  @IBOutlet weak var hiveChainRedDot: UIView!

  @IBOutlet weak var steamChainButton: UIButton!
  @IBOutlet weak var blurtChainButton: UIButton!
  @IBOutlet weak var hiveChainButton: UIButton!


  @IBOutlet weak var enableNotificationsRedDot: UIView!
  @IBOutlet weak var disableNotificationsRedDot: UIView!

  @IBOutlet weak var enableNotificationsButton: UIButton!
  @IBOutlet weak var disableNotificationssButton: UIButton!

  @IBOutlet weak var firstNotificationBtn: UIButton!
  @IBOutlet weak var secondNotificationBtn: UIButton!
  @IBOutlet weak var thirdNotificationBtn: UIButton!
  @IBOutlet weak var forthNotificationBtn: UIButton!
  @IBOutlet weak var fifthNotificationBtn: UIButton!
  @IBOutlet weak var sixthNotificationBtn: UIButton!

  @IBOutlet weak var liquidDotView: UIView!
  @IBOutlet weak var declinePayoutDotView: UIView!

  @IBOutlet weak var declinePayoutBtn: UIButton!
  @IBOutlet weak var liquidHBDBtn: UIButton!

  @IBOutlet weak var seventhNotificationBtn: UIButton!

  @IBOutlet weak var seventhNotificationLabel: UILabel!

  @IBOutlet weak var eightNotificationBtn: UIButton!

  @IBOutlet weak var eightsNotificationLabel: UILabel!

  var isTipsSelected : Bool {
    return UserDefaults.standard.showTips
  }
  var isMetricSystemSelected = true
  var isDonateToCharitySelected = false
  var isDeviceSensorSystemSelected = true
  var fitBitMeasurement = false
  var isSbdSPPaySystemSelected = false
  var is100SPSelected = false
  var isLiquidSPSelected = false
  var isDeclinePayoutSelected = false
  var isReminderSelected = false
  var charities = [Charity]()
  var charityName = ""
  var charityDisplayName = ""
  let dropDown = DropDown()
  var selectedIndex = 0
  var notification = false
  var chain = "HIVE"
  var steemChain = ""
  var blurtChain = ""
  var notifications = [NotificationServer]()
  var isHiveSelected = true
  var isSteemSelected = false
  var isBlurtSelected = false
  var isFirstNotificationSelected = false
  var isSecondNotificationSelected = false
  var isThirdNotificationSelected = false
  var isForthNotificationSelected = false
  var isFifthNotificationSelected = false
  var isSixthNotificationSelected = false
  var isSeventhNotificationSelected = false
  var isEigthNotificationSelected = false

  @IBOutlet weak var notificationStackView: UIStackView!
  @IBOutlet weak var heightConstraintForNotificationView: NSLayoutConstraint!
  //MARK: VIEW LIFE CYCLE

  var settings =  Settings.current()

  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    UIApplication.shared.unregisterForRemoteNotifications()
    UserDefaults.standard.setValue(self.notification, forKey: "notifications")
    if User.current()?.private_posting_key != nil && User.current()?.steemit_username != nil{
      checkLoginAuth()
    }

    let selectedLanguage = UserDefaults.standard.string(forKey: "SelectedLanguage")
    if selectedLanguage  != nil{
      self.languageButton.setTitle(selectedLanguage, for: .normal)
    }

    self.loadCharities()
    lblVersion.text = "Actifit App Version:" + UIApplication.appVersion!
    isReminderSelected = UserDefaults.standard.bool(forKey: "isReminderSelected")
    if let settings = self.settings {
      self.isMetricSystemSelected = settings.measurementSystem == MeasurementSystem.metric.rawValue
      self.isDonateToCharitySelected = settings.isDonatingCharity
      self.isDeviceSensorSystemSelected = settings.isDeviceSensorSystemSelected
      self.fitBitMeasurement = settings.fitBitMeasurement
      self.isReminderSelected = settings.isReminderSelected
      self.isSbdSPPaySystemSelected = settings.isSbdSPPaySystemSelected
      self.isLiquidSPSelected = settings.isLiquidHBDSelected
      self.isDeclinePayoutSelected = settings.isDeclinePayoutSelected
      self.charityName = settings.charityName
      self.charityDisplayName = settings.charityDisplayName
      if settings.steemChain == "Steem"{
        // blurtChain(select: false)
        // steamChain(select: true)
        self.steamChainButton.isSelected = true

        self.steamChainButton.layer.borderWidth = 2.0
        self.steamChainButton.layer.borderColor = UIColor.clear.cgColor
        self.steamChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
        self.steamChainButton.tintColor = ColorTheme
      }
      if settings.blurtChain == "Blurt"{
        // blurtChain(select: true)
        // steamChain(select: false)
        self.blurtChainButton.isSelected = true

        self.blurtChainButton.layer.borderColor =  UIColor.clear.cgColor
        self.blurtChainButton.layer.borderWidth = 2.0
        self.blurtChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
        self.blurtChainButton.tintColor = ColorTheme
      }
      if !self.charityName.isEmpty {
        self.setTextViewLinkString()
      }
      self.showCharityBtn.setTitle(self.charityDisplayName, for: .normal)
    }else {
      isSbdSPPaySystemSelected = true
    }
    self.applyFinihingTouchToUIElements()
    self.setDropDown()
    self.setupInitials()
    saveSettingsBtn.contentHorizontalAlignment = .center
    if let notificationSelected = settings?.notificationSelected  {
      enableNotifications(select: notificationSelected)
      disableNotifications(select: !notificationSelected)
    }
    getNotifications()
    self.dailyTipButton.layer.borderColor = UIColor.darkGray.cgColor
    self.dailyTipButton.layer.borderWidth = 2.0
    self.dailyTipButton.layer.cornerRadius = 2.0
    if isTipsSelected {
      dailyTipButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate).withTintColor(.white), for: .normal)
      dailyTipButton.backgroundColor = .primaryRedColor()
      dailyTipButton.tintColor = .white
    }

    activeKeyTextField.text =   UserDefaults.standard.activeKey
    fundsPasswordTextField.text =  UserDefaults.standard.fundPassword
   // self.navigationController?.navigationBar.barTintColor = .primaryRedColor()

    if DeviceType.isSmallScreen {
      changeConstraintMultiplier(&mainHeightConstraint, multiplier: 3.15)
    } else {
      changeConstraintMultiplier(&mainHeightConstraint, multiplier: 2.65)
    }
  }

  func changeConstraintMultiplier(_ constraint: inout NSLayoutConstraint, multiplier: CGFloat) {
    // Remove the old constraint
    NSLayoutConstraint.deactivate([constraint])

    // Create a new constraint with the same properties but a different multiplier
    let newConstraint = NSLayoutConstraint(
      item: constraint.firstItem as Any,
      attribute: constraint.firstAttribute,
      relatedBy: constraint.relation,
      toItem: constraint.secondItem,
      attribute: constraint.secondAttribute,
      multiplier: multiplier,
      constant: constraint.constant
    )
    newConstraint.priority = constraint.priority
    newConstraint.identifier = constraint.identifier

    // Add the new constraint
    NSLayoutConstraint.activate([newConstraint])

    // Update the reference to the new constraint
    constraint = newConstraint

    // Force layout update
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }


  func setupInitials()
  {
    settingsLabel.text                  = "settings_title".localized()
    activityDataSource.text             = "activity_source_lbl".localized()
    phoneSensorLabel.text               = "device_sensors_option_lbl".localized()
    fitBitLabel.text                    = "fitbit_option_lbl".localized()
    fitBitSettingHeadingLabel.text      = "fitbit_settings_lbl".localized()
    fetchMeasurementLabel.text          = "fitbit_measurements_lbl".localized()
    fetchStepsLabel.text                = "fitbit_fetch_steps".localized()
    steemPostPayoutLabel.text           = "steem_post_payout".localized()
    fiftyPercentLabel.text              = "pay_option_50_50".localized()
    hundredPercentLabel.text            = "pay_option_full_sp".localized()
    languageTitleLabel.text             = "Language".localized()
    measurementSystemTitleLabel.text    = "measure_system_lbl".localized()
    metricLabel.text                    = "metric_system_option_lbl".localized()
    USLabel.text                        = "us_system_option_lbl".localized()
    donateToCharityLabel.text           = "donate_charity_lbl".localized()
    donateRewardToCharity.text          = "donate_charity_checkbox".localized()
    availabelCharitiesLabel.text        = "charity_options_lbl".localized()
    charityInfo.text                    = "charity_info_lbl".localized()
    dailyReminderPost.text              = "daily_post_reminder_lbl".localized()
    remindMeToPostLabel.text            = "post_reminder_checkbox".localized()
    versionLabel.text                   = "app_version_string".localized() + " " + UIApplication.appVersion!
    saveSettingsBtn.titleLabel!.text    = "save_settings_btn_lbl".localized()
  }


  @IBAction func logoutTapped(_ sender: Any) {
    showAlertWith(title: "", message: "Are you sure you want to logout?", okActionTitle: "Yes", cancelActionTitle: "No", okClickedCompletion: OkClickedCompletion { finished in
      self.logout()
    }, cancelClickedCompletion: CancelClickedCompletion {finished in

    })
  }

  @IBAction func dailyTipButtonTapped(_ sender: Any) {
    if isTipsSelected {
      dailyTipButton.setImage(UIImage(), for: .normal)
      dailyTipButton.backgroundColor = .white

      UserDefaults.standard.showTips = false
    } else {
      UserDefaults.standard.showTips = true
      dailyTipButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate).withTintColor(.white), for: .normal)
      dailyTipButton.backgroundColor = .primaryRedColor()
      dailyTipButton.tintColor = .white

    }
  }


  @IBAction func declinePayoutBtnTapped(_ sender: Any) {
    isLiquidSPSelected = false
    isDeclinePayoutSelected = true
    is100SPSelected = false
    self.isSbdSPPaySystemSelected = false
    selectLiquidHBD(select: false)
    selectDeclinePayout(select: true)
    selectsbdSPPaySystem(select: false)
    selectfullPaySystem(select: false)
  }

  @IBAction func liquidHBDBtnTapped(_ sender: Any) {
    isLiquidSPSelected = true
    isDeclinePayoutSelected = false
    is100SPSelected = false
    self.isSbdSPPaySystemSelected = false
    selectLiquidHBD(select: true)
    selectDeclinePayout(select: false)
    selectsbdSPPaySystem(select: false)
    selectfullPaySystem(select: false)
  }

    func logout() {
        User.deleteCurrentUser()
        clearUserDefaults()
        if let appDelegate = UIApplication.shared.delegate as? AFAppDelegate {
            let loginVC = UIStoryboard(name: "Login", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            appDelegate.window?.rootViewController = loginVC
            appDelegate.window?.makeKeyAndVisible()
        }

//        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//               let sceneDelegate = scene.delegate as? SceneDelegate {
//
//                let loginVC = UIStoryboard(name: "Login", bundle: nil)
//                    .instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
//
//                // Add a smooth transition to the login screen
//                UIView.transition(with: sceneDelegate.window!,
//                                  duration: 0.5,
//                                  options: .transitionFlipFromRight,
//                                  animations: {
//                                      sceneDelegate.window?.rootViewController = loginVC
//                                  }, completion: { _ in
//                                      sceneDelegate.window?.makeKeyAndVisible()
//                                  })
//            }
    }

  private func clearUserDefaults() {
    UserDefaults.standard.setXcstkn = nil
    UserDefaults.standard.username = ""
    UserDefaults.standard.authToken = ""
    UserDefaults.standard.privatePostingKey = ""
  }

  fileprivate func updateLanguage(_ index: Int) {
    if index == 0{
      Localizr.update(locale: "en")
    }

    if index == 1{
      Localizr.update(locale: "pt-PT")
    }

    if index == 2{
      Localizr.update(locale: "ko")
    }
    if index == 3{
      Localizr.update(locale: "ar")
      L102Language.setAppleLAnguageTo(lang: "ar")
      UIView.appearance().semanticContentAttribute = .forceRightToLeft


    }else{
      L102Language.setAppleLAnguageTo(lang: "en")
      UIView.appearance().semanticContentAttribute = .forceLeftToRight

    }
    if index == 4{
      Localizr.update(locale: "yo")
    }
    if index == 5{
      Localizr.update(locale: "nl")
    }
    if index == 6{
      Localizr.update(locale: "hi")
    }
    if index == 7{
      Localizr.update(locale: "it")
    }
    if index == 8{
      Localizr.update(locale: "de")
    }
    self.setupInitials()

  }

  func setDropDown()
  {
    dropDown.anchorView = self.languageButton
    dropDown.dataSource = ["English", "Portuguesa", "한국어", "العربية", "Yoruba", "Nederlands" , "हिंदी", "Italiano" , "Deutsche"]
    dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
      self.selectedIndex = index

      self.languageButton.setTitle(item, for: .normal)
    }
    dropDown.width = self.languageButton.bounds.width
    dropDown.bottomOffset = CGPoint(x: 0, y:(dropDown.anchorView?.plainView.bounds.height)!)
    dropDown.direction = .bottom
    dropDown.backgroundColor = UIColor.white

  }

  //MARK: INTERFACE BUILDER ACTIONS

  @IBAction func languageButtonAction(_ sender: Any) {
    self.dropDown.show()
  }


  @IBAction func backBtnAction(_ sender : UIButton) {
    self.navigationController?.popViewController(animated: true)
  }

  @IBAction func metricMeasurementSystemBtnAction(_ sender : UIButton) {
    self.isMetricSystemSelected = true
    self.selectMetricSystem(select: true)
    self.selectUSSystem(select: false)
  }

  @IBAction func usMeasurementSystemBtnAction(_ sender : UIButton) {
    self.isMetricSystemSelected = false
    self.selectUSSystem(select: true)
    self.selectMetricSystem(select: false)
  }

  @IBAction func steamChainButtonAction(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isSteemSelected = sender.isSelected
    self.steamChainButton.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.steamChainButton.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.steamChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.steamChainButton.tintColor = ColorTheme

      self.steemChain = "Steem"
    } else {
      self.steamChainButton.setImage(nil, for: .normal)
      self.steemChain = ""
    }
    // blurtChain(select: false)
    // steamChain(select: true)

  }

  @IBAction func blurtChainButtonAction(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isBlurtSelected = sender.isSelected
    self.blurtChainButton.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.blurtChainButton.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.blurtChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.blurtChainButton.tintColor = ColorTheme
      self.blurtChain = "Blurt"
    } else {
      self.blurtChainButton.setImage(nil, for: .normal)
      self.blurtChain = ""
    }

    // blurtChain(select: true)
    // steamChain(select: false)

  }

  @IBAction func hiveChainButtonAction(_ sender: UIButton) {
  }

  @IBAction func enableNotificationsButtonAction(_ sender: Any) {
    if User.current()?.steemit_username == nil{
      self.showAlertWith(title: nil, message: "Please login first to enable this")
      return
    }
    else{
      enableNotifications(select: true)
      disableNotifications(select: false)
      self.notification = true

      self.notificationsStack.isHidden = false
      self.heightConstraintForNotificationView.constant = CGFloat(Double(self.notifications.count * 35) + 83.5)
      //mainContainerInScrollViewHeightConstraint.constant = 1000 + 203
    }

  }

  @IBAction func disableNotificationsButtonAction(_ sender: Any) {
    enableNotifications(select: false)
    disableNotifications(select: true)
    self.notification = false

    self.notificationsStack.isHidden = true
    self.heightConstraintForNotificationView.constant = 83.5
    //   mainContainerInScrollViewHeightConstraint.constant = 900
  }



  @IBAction func deviceSensorSystemBtnAction(_ sender : UIButton) {
    self.isDeviceSensorSystemSelected = true
    self.selectDeviceSensorSystem(select: true)
    self.selectFitBitSystem(select: false)
    applyFinihingTouchToUIElements()
  }

  @IBAction func fitBitSystemBtnAction(_ sender : UIButton) {
    self.isDeviceSensorSystemSelected = false
    self.selectDeviceSensorSystem(select: false)
    self.selectFitBitSystem(select: true)
    applyFinihingTouchToUIElements()
  }

  @IBAction func sbdSPPaySystemBtnAction(_ sender : UIButton) {
    self.isSbdSPPaySystemSelected = true
    isLiquidSPSelected = false
    isDeclinePayoutSelected = false
    self.is100SPSelected = false
    self.selectsbdSPPaySystem(select: true)
    self.selectfullPaySystem(select: false)
    selectLiquidHBD(select: false)
    selectDeclinePayout(select: false)
    UserDefaults.standard.set(false, forKey: "isSbdSPPaySystemSelected")
  }

  @IBAction func fullSPaySystemBtnAction(_ sender : UIButton) {
    self.isSbdSPPaySystemSelected = false
    isLiquidSPSelected = false
    isDeclinePayoutSelected = false
    self.is100SPSelected = true
    self.selectsbdSPPaySystem(select: false)
    self.selectfullPaySystem(select: true)
    selectLiquidHBD(select: false)
    selectDeclinePayout(select: false)
    UserDefaults.standard.set(true, forKey: "isSbdSPPaySystemSelected")
  }

  @IBAction func donateTopCharityBtnAction(_ sender : UIButton) {
    sender.isSelected = !sender.isSelected
    self.isDonateToCharitySelected = sender.isSelected
    self.donateTopCharityBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.donateTopCharityBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.donateTopCharityBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.donateTopCharityBtn.tintColor = ColorTheme
    } else {
      self.donateTopCharityBtn.setImage(nil, for: .normal)
    }
  }

  @IBAction func fetchMeasuremtnsBtn(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.fitBitMeasurement = sender.isSelected
    self.fetchMeasurements.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.fetchMeasurements.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.fetchMeasurements.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.fetchMeasurements.tintColor = ColorTheme
    } else {
      self.fetchMeasurements.setImage(nil, for: .normal)
    }
  }
  @IBAction func fetchStepsAction(_ sender: Any) {
  }
  @IBAction func reminderBtnAction(_ sender : UIButton) {
    sender.isSelected = !sender.isSelected
    self.isReminderSelected = sender.isSelected
    UserDefaults.standard.set(self.isReminderSelected, forKey: "isReminderSelected")
    self.remindBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.remindBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.remindBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.remindBtn.tintColor = ColorTheme
    } else {
      self.remindBtn.setImage(nil, for: .normal)
    }
  }

  @IBAction func showCharitiesBtnAction(_ sender : UIButton) {
    if self.charities.count == 0 {
      self.showAlertWith(title: nil, message: "No Charity available")
      return
    }

    if let nib = Bundle.main.loadNibNamed("ActivityTypesView", owner: self, options: nil) {
      var objActivityTypesView : ActivityTypesView? = nib[0] as? ActivityTypesView
      objActivityTypesView?.activityTypesOrCharities = self.charities.map({$0.display_name})
      objActivityTypesView?.selectedActivities = (self.charityDisplayName).components(separatedBy: CharacterSet.init(charactersIn: ","))
      objActivityTypesView?.isForCharity = true
      objActivityTypesView?.activitiesTableView.reloadData()
      self.view.addSubview(objActivityTypesView!)
      objActivityTypesView?.prepareForNewConstraints { (v) in
        v?.setLeadingSpaceFromSuperView(leadingSpace: 0)
        v?.setTrailingSpaceFromSuperView(trailingSpace: 0)
        v?.setTopSpaceFromSuperView(topSpace: 0)
        v?.setBottomSpaceFromSuperView(bottomSpace: 0)
      }
      objActivityTypesView?.SelectedActivityTypesCompletion = { selectedActivities in
        if selectedActivities.count > 0 {
          self.charityDisplayName = selectedActivities[0]
          self.charityName = self.charities.first(where: {$0.display_name == self.charityDisplayName})?.charity_name ?? ""
          self.showCharityBtn.setTitle(self.charityDisplayName, for: .normal)
          self.setTextViewLinkString()
        }
        objActivityTypesView?.selectedActivities.removeAll()
        objActivityTypesView?.removeFromSuperview()
        objActivityTypesView = nil
      }
    }
  }

  func localSettingsSaving(){
    //metric system
    self.updateLanguage(self.selectedIndex)
    UserDefaults.standard.set(self.languageButton.titleLabel?.text ?? "English", forKey: "SelectedLanguage")
    UserDefaults.standard.set(!isDeviceSensorSystemSelected, forKey: "isFitSystemSelected")
    UserDefaults.standard.activeKey = activeKeyTextField.text ?? ""
    UserDefaults.standard.fundPassword = fundsPasswordTextField.text ?? ""
    UserDefaults.standard.synchronize()


    if let settings = self.settings {

      settings.update(measurementSystem: self.isMetricSystemSelected ? .metric : .us, isDonatingCharity: self.isDonateToCharitySelected, charityName: charityName, charityDisplayName: charityDisplayName, isDeviceSensorSystemSelected: self.isDeviceSensorSystemSelected,isSbdSPPaySystemSelected: self.isSbdSPPaySystemSelected,isReminderSelected: self.isReminderSelected, fitBitMeasurement: self.fitBitMeasurement, appVersion: UIApplication.appVersion!, notificationSelected: self.notification, hiveChainSelected: self.chain, steemChainSelected: self.steemChain, blurtChainSelected: self.blurtChain, isLiquidHBDSelected: self.isLiquidSPSelected, isDeclinePayoutSelected: self.isDeclinePayoutSelected, is100PSelected: is100SPSelected)
    } else {
      Settings.saveWith(info: [SettingsKeys.measurementSystem : (self.isMetricSystemSelected ? MeasurementSystem.metric.rawValue : MeasurementSystem.us.rawValue), SettingsKeys.isDonatingCharity : false, SettingsKeys.charityName :  charityName, SettingsKeys.charityDisplayName : charityDisplayName, SettingsKeys.datasource: isDeviceSensorSystemSelected, SettingsKeys.postpayout : isSbdSPPaySystemSelected, SettingsKeys.reminder : isReminderSelected, SettingsKeys.fitBitMeasurement : fitBitMeasurement,SettingsKeys.AppVersion:UIApplication.appVersion!, SettingsKeys.notifications: self.notification, SettingsKeys.hiveChain: self.chain, SettingsKeys.steemChain: self.steemChain, SettingsKeys.blurtChain: self.blurtChain, SettingsKeys.isLiquidHBD: self.isLiquidSPSelected, SettingsKeys.isDeclinePayment: self.isDeclinePayoutSelected, SettingsKeys.is100SP: self.is100SPSelected])
    }

    self.showAlertWithOkCompletion(title: nil, message: "Setting have been saved") { (cl) in
      self.navigationController?.popViewController(animated: true)
    }

    UIApplication.shared.cancelAllLocalNotifications()
    if isReminderSelected{
      setNotification()
    }
  }

  @IBAction func saveSettingsBtnAction(_ sender : UIButton) {
    saveSettingsAPI()


  }

  func setNotification(){
    let notification = UILocalNotification()

    /* Time and timezone settings */
    let date:Date = timePicker.date;
    UserDefaults.standard.set(date.toString(dateFormat: "HH:mm"), forKey: "ReminderDate")
    notification.fireDate = date
    notification.repeatInterval = NSCalendar.Unit.day
    notification.timeZone = NSCalendar.current.timeZone
    notification.alertTitle = "Actifit Reminder"
    notification.alertBody = "You haven't posted today's activity report!"

    /* Action settings */
    notification.hasAction = true
    notification.alertAction = "View"

    /* Badge settings */
    notification.applicationIconBadgeNumber =
    UIApplication.shared.applicationIconBadgeNumber + 1
    /* Additional information, user info */


    /* Schedule the notification */
    UIApplication.shared.scheduleLocalNotification(notification)

  }
  //Notification types
  func setNotificationView(){
    if notifications.count != 0 {
      // setNotificationSections()

    }

  }


  private func generateNotificationSections() {
    self.heightConstraintForNotificationView.constant = CGFloat(Double(self.notifications.count * 35) + 83.5)
    notificationStackView.spacing  = 2.5

    notifications.forEach { element in
      let customView = createCustomView(notification: element)
      self.notificationStackView.addArrangedSubview(customView)

    }


  }

  @IBAction func seventhNotificationBtnTapped(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isSeventhNotificationSelected = sender.isSelected
    self.seventhNotificationBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.seventhNotificationBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.seventhNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.seventhNotificationBtn.tintColor = ColorTheme
    } else {
      self.seventhNotificationBtn.setImage(nil, for: .normal)
    }
  }

  @IBAction func eightNotificationBtnTapped(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isEigthNotificationSelected = sender.isSelected
    self.eightNotificationBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.eightNotificationBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.eightNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.eightNotificationBtn.tintColor = ColorTheme
    } else {
      self.eightNotificationBtn.setImage(nil, for: .normal)
    }
  }


  @IBAction func firstNotificationBtnAction(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isFirstNotificationSelected = sender.isSelected
    self.firstNotificationBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.firstNotificationBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.firstNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.firstNotificationBtn.tintColor = ColorTheme
    } else {
      self.firstNotificationBtn.setImage(nil, for: .normal)
    }
  }
  @IBAction func secondNotificationBtnAction(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isSecondNotificationSelected = sender.isSelected
    self.secondNotificationBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.secondNotificationBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.secondNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.secondNotificationBtn.tintColor = ColorTheme
    } else {
      self.secondNotificationBtn.setImage(nil, for: .normal)
    }

  }
  @IBAction func thirdNotificationBtnAction(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isThirdNotificationSelected = sender.isSelected
    self.thirdNotificationBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.thirdNotificationBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.thirdNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.thirdNotificationBtn.tintColor = ColorTheme
    } else {
      self.thirdNotificationBtn.setImage(nil, for: .normal)
    }
  }
  @IBAction func forthNotificationBtnAction(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isForthNotificationSelected = sender.isSelected
    self.forthNotificationBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.forthNotificationBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.forthNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.forthNotificationBtn.tintColor = ColorTheme
    } else {
      self.forthNotificationBtn.setImage(nil, for: .normal)
    }
  }
  @IBAction func fifthNotificationBtnAction(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isFifthNotificationSelected = sender.isSelected
    self.fifthNotificationBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.fifthNotificationBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.fifthNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.fifthNotificationBtn.tintColor = ColorTheme
    } else {
      self.fifthNotificationBtn.setImage(nil, for: .normal)
    }
  }
  @IBAction func sixthNotificationBtnAction(_ sender: UIButton) {
    sender.isSelected = !sender.isSelected
    self.isSixthNotificationSelected = sender.isSelected
    self.sixthNotificationBtn.layer.borderColor = sender.isSelected ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    self.sixthNotificationBtn.layer.borderWidth = sender.isSelected ? 0.0 : 2.0
    if sender.isSelected {
      self.sixthNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.sixthNotificationBtn.tintColor = ColorTheme
    } else {
      self.sixthNotificationBtn.setImage(nil, for: .normal)
    }
  }



  //MARK: HELPERS


  func applyFinihingTouchToUIElements() {
    logoutButton.layer.cornerRadius = 2
    logoutButton.clipsToBounds = true
    self.saveSettingsBtn.layer.cornerRadius = 2.0
    self.showCharityBtn.layer.cornerRadius = 2.0
  //  self.backBtn.setImage(#imageLiteral(resourceName: "back_black").withRenderingMode(.alwaysTemplate), for: .normal)
   // self.backBtn.tintColor = UIColor.white

    self.metricDotView.backgroundColor = ColorTheme
    self.usDotView.backgroundColor = ColorTheme

    self.deviceSensorDotView.backgroundColor = ColorTheme
    self.fitBitDotView.backgroundColor = ColorTheme

    self.fullPayDotView.backgroundColor = ColorTheme
    self.sbdSPPayDotView.backgroundColor = ColorTheme
    declinePayoutDotView.backgroundColor = ColorTheme

    //        liquidHBDBtn.layer.cornerRadius = liquidHBDBtn.frame.size.width / 2
    //        liquidHBDBtn.layer.borderWidth = 2
    //        liquidHBDBtn.layer.borderColor = ColorTheme.cgColor
    //
    //        declinePayoutBtn.layer.borderColor = ColorTheme.cgColor
    //        declinePayoutBtn.layer.cornerRadius = declinePayoutBtn.frame.size.width / 2
    //        declinePayoutBtn.layer.borderWidth = 2
    //
    liquidDotView.backgroundColor = ColorTheme
    metricMeasurementSystemBtn.layer.cornerRadius = metricMeasurementSystemBtn.frame.size.width / 2
    USMeasurementSystemBtn.layer.cornerRadius = USMeasurementSystemBtn.frame.size.width / 2

    deviceSensortSystemBtn.layer.cornerRadius = deviceSensortSystemBtn.frame.size.width / 2
    fitBitSystemBtn.layer.cornerRadius = fitBitSystemBtn.frame.size.width / 2

    fullPaySystemBtn.layer.cornerRadius = fullPaySystemBtn.frame.size.width / 2
    sbdSPPaySystemBtn.layer.cornerRadius = sbdSPPaySystemBtn.frame.size.width / 2

    liquidHBDBtn.layer.cornerRadius = liquidHBDBtn.frame.size.width / 2
    declinePayoutBtn.layer.cornerRadius = liquidHBDBtn.frame.size.width / 2

    metricDotView.layer.cornerRadius = metricDotView.frame.size.width / 2
    usDotView.layer.cornerRadius = usDotView.frame.size.width / 2

    // steamChainRedDot.layer.cornerRadius = steamChainRedDot.frame.size.width / 2
    // blurtChainRedDot.layer.cornerRadius = blurtChainRedDot.frame.size.width / 2
    // hiveChainRedDot.layer.cornerRadius = hiveChainRedDot.frame.size.width / 2

    // steamChainButton.layer.cornerRadius = steamChainButton.frame.size.width / 2
    // blurtChainButton.layer.cornerRadius = steamChainButton.frame.size.width / 2
    // hiveChainButton.layer.cornerRadius = steamChainButton.frame.size.width / 2


    enableNotificationsRedDot.layer.cornerRadius = enableNotificationsRedDot.frame.size.width / 2
    disableNotificationsRedDot.layer.cornerRadius = disableNotificationsRedDot.frame.size.width / 2

    enableNotificationsButton.layer.cornerRadius = enableNotificationsButton.frame.size.width / 2
    disableNotificationssButton.layer.cornerRadius = disableNotificationssButton.frame.size.width / 2

    deviceSensorDotView.layer.cornerRadius = deviceSensorDotView.frame.size.width / 2
    fitBitDotView.layer.cornerRadius = fitBitDotView.frame.size.width / 2

    fullPayDotView.layer.cornerRadius = fullPayDotView.frame.size.width / 2
    fullPayDotView.clipsToBounds = true
    sbdSPPayDotView.layer.cornerRadius = sbdSPPayDotView.frame.size.width / 2

    liquidDotView.layer.cornerRadius = liquidDotView.frame.size.width / 2
    declinePayoutDotView.layer.cornerRadius = declinePayoutDotView.frame.size.width / 2
    self.hiveChainButton.layer.borderColor = UIColor.darkGray.cgColor
    self.hiveChainButton.layer.borderWidth = 2.0
    self.hiveChainButton.layer.cornerRadius = 2.0
    self.steamChainButton.layer.borderColor = UIColor.darkGray.cgColor
    self.steamChainButton.layer.borderWidth = 2.0
    self.steamChainButton.layer.cornerRadius = 2.0
    self.blurtChainButton.layer.borderColor = UIColor.darkGray.cgColor
    self.blurtChainButton.layer.borderWidth = 2.0
    self.blurtChainButton.layer.cornerRadius = 2.0

    self.donateTopCharityBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.donateTopCharityBtn.layer.borderWidth = 2.0
    self.donateTopCharityBtn.layer.cornerRadius = 2.0

    self.firstNotificationBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.firstNotificationBtn.layer.borderWidth = 2.0
    self.firstNotificationBtn.layer.cornerRadius = 2.0
    self.secondNotificationBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.secondNotificationBtn.layer.borderWidth = 2.0
    self.secondNotificationBtn.layer.cornerRadius = 2.0
    self.thirdNotificationBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.thirdNotificationBtn.layer.borderWidth = 2.0
    self.thirdNotificationBtn.layer.cornerRadius = 2.0
    self.forthNotificationBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.forthNotificationBtn.layer.borderWidth = 2.0
    self.forthNotificationBtn.layer.cornerRadius = 2.0
    self.fifthNotificationBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.fifthNotificationBtn.layer.borderWidth = 2.0
    self.fifthNotificationBtn.layer.cornerRadius = 2.0
    self.sixthNotificationBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.sixthNotificationBtn.layer.borderWidth = 2.0
    self.sixthNotificationBtn.layer.cornerRadius = 2.0

    self.seventhNotificationBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.seventhNotificationBtn.layer.borderWidth = 2.0
    self.seventhNotificationBtn.layer.cornerRadius = 2.0

    self.eightNotificationBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.eightNotificationBtn.layer.borderWidth = 2.0
    self.eightNotificationBtn.layer.cornerRadius = 2.0

    self.remindBtn.layer.borderColor = UIColor.darkGray.cgColor
    self.remindBtn.layer.borderWidth = 2.0
    self.remindBtn.layer.cornerRadius = 2.0

    self.fetchMeasurements.layer.borderColor = UIColor.darkGray.cgColor
    self.fetchMeasurements.layer.borderWidth = 2.0
    self.fetchMeasurements.layer.cornerRadius = 2.0

    self.fetchSteps.layer.borderColor = UIColor.darkGray.cgColor
    self.fetchSteps.layer.borderWidth = 0.0
    self.fetchSteps.layer.cornerRadius = 2.0
    self.fetchSteps.isEnabled = true
    self.fetchSteps.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
    self.fetchSteps.tintColor = UIColor.darkGray

    //update UI
    selectMetricSystem(select: self.isMetricSystemSelected)
    selectUSSystem(select: !self.isMetricSystemSelected)

    selectfullPaySystem(select: settings?.is100SPSelected ?? false)
    selectsbdSPPaySystem(select: settings?.isSbdSPPaySystemSelected ?? false)
    selectLiquidHBD(select: settings?.isLiquidHBDSelected ?? false)
    selectDeclinePayout(select: settings?.isDeclinePayoutSelected ?? false)
    if settings?.is100SPSelected == nil && settings?.isSbdSPPaySystemSelected == nil && settings?.isLiquidHBDSelected == nil && settings?.isDeclinePayoutSelected == nil {
      selectsbdSPPaySystem(select: settings?.isSbdSPPaySystemSelected ?? true)
    }

    selectDeviceSensorSystem(select: isDeviceSensorSystemSelected)
    selectFitBitSystem(select: !isDeviceSensorSystemSelected)
    if self.isDonateToCharitySelected {
      self.donateTopCharityBtn.isSelected = true
      self.donateTopCharityBtn.layer.borderWidth = 0.0
      self.donateTopCharityBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.donateTopCharityBtn.tintColor = ColorTheme
    }

    if self.fitBitMeasurement{
      self.fetchMeasurements.isSelected = true
      self.fetchMeasurements.layer.borderWidth = 0.0
      self.fetchMeasurements.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.fetchMeasurements.tintColor = ColorTheme
    }
    if self.isReminderSelected {
      self.remindBtn.isSelected = true
      self.remindBtn.layer.borderWidth = 0.0
      self.remindBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.remindBtn.tintColor = ColorTheme
      let reminderTime = UserDefaults.standard.string(forKey: "ReminderDate")
      if reminderTime == nil{
        return
      }
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat =  "HH:mm"
      let date = dateFormatter.date(from: reminderTime!)
      timePicker.date = date!

    }

    if !self.isDeviceSensorSystemSelected{
      fitBitSettingView.isHidden = false
      fitBitSettingHeightCons.constant = 100
      updateViewConstraints()
    }else{
      fitBitSettingView.isHidden = true
      fitBitSettingHeightCons.constant = 0
      updateViewConstraints()
    }

    if self.isFirstNotificationSelected {
      self.firstNotificationBtn.isSelected = true
      self.firstNotificationBtn.layer.borderWidth = 0.0
      self.firstNotificationBtn.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.firstNotificationBtn.tintColor = ColorTheme
    }

    if self.isSteemSelected{
      self.steamChainButton.isSelected = true
      self.steamChainButton.layer.borderWidth = 0.0
      self.steamChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.steamChainButton.tintColor = ColorTheme
    }
    if self.isBlurtSelected{
      self.blurtChainButton.isSelected = true
      self.blurtChainButton.layer.borderWidth = 0.0
      self.blurtChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.blurtChainButton.tintColor = ColorTheme
    }
    if self.isHiveSelected{
      self.hiveChainButton.isSelected = true
      self.hiveChainButton.layer.borderWidth = 0.0
      self.hiveChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      self.hiveChainButton.tintColor = ColorTheme
    }
  }

  func setTextViewLinkString() {
    self.charityLinkTextView.attributedText = self.charitySteemitUrl().attributedString(font: UIFont.systemFont(ofSize: 14), textColor: ColorTheme)
    self.charityLinkTextView.linkTextAttributes = [NSAttributedStringKey.link.rawValue : ColorTheme]
  }

  func selectMetricSystem(select : Bool) {
    self.metricMeasurementSystemBtn.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.metricMeasurementSystemBtn.layer.borderWidth = 2.0

    self.metricMeasurementSystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.metricMeasurementSystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
  //  self.view.layoutIfNeeded()
   // self.metricMeasurementSystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
   // self.metricMeasurementSystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.view.layoutIfNeeded()
  }

  func selectUSSystem(select : Bool) {
    self.USMeasurementSystemBtn.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.USMeasurementSystemBtn.layer.borderWidth = 2.0
    self.USMeasurementSystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
    self.USMeasurementSystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.view.layoutIfNeeded()
  }

  func steamChain(select : Bool) {
    self.steamChainButton.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.steamChainButton.layer.borderWidth = 2.0
    self.steamChainRedDot.backgroundColor = select ? ColorTheme : UIColor.clear

  }

  func blurtChain(select : Bool) {
    self.blurtChainButton.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.blurtChainButton.layer.borderWidth = 2.0
    self.blurtChainRedDot.backgroundColor = select ? ColorTheme : UIColor.clear
  }

  func hiveChain(select : Bool) {
    self.hiveChainButton.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.hiveChainButton.layer.borderWidth = 2.0
    self.hiveChainRedDot.backgroundColor = select ? ColorTheme : UIColor.clear
  }

  func enableNotifications(select : Bool) {
    self.enableNotificationsButton.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.enableNotificationsButton.layer.borderWidth = 2.0
    self.enableNotificationsRedDot.backgroundColor = select ? ColorTheme : UIColor.clear

  }

  func disableNotifications(select : Bool) {
    self.disableNotificationssButton.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.disableNotificationssButton.layer.borderWidth = 2.0
    self.disableNotificationsRedDot.backgroundColor = select ? ColorTheme : UIColor.clear

  }

  func selectDeviceSensorSystem(select : Bool) {
    if select{
      //mainContainerInScrollViewHeightConstraint.constant = 900 + 203
    }

    self.deviceSensortSystemBtn.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.deviceSensortSystemBtn.layer.borderWidth = 2.0
    self.deviceSensorSystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
    self.deviceSensorSystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.view.layoutIfNeeded()
  }

  func selectFitBitSystem(select : Bool) {
    if select{
      //     mainContainerInScrollViewHeightConstraint.constant = 1000
    }

    self.fitBitSystemBtn.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.fitBitSystemBtn.layer.borderWidth = 2.0
    self.fitBitSystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.fitBitSystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
    self.view.layoutIfNeeded()
  }

  func selectsbdSPPaySystem(select : Bool) {
    self.sbdSPPaySystemBtn.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.sbdSPPaySystemBtn.layer.borderWidth = 2.0
    self.sbdSPPaySystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
    self.sbdSPPaySystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.view.layoutIfNeeded()
  }

  func selectLiquidHBD(select : Bool) {

    //  is100SPSelected = false
    self.liquidHBDBtn.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.liquidHBDBtn.layer.borderWidth = 2.0
    liquidDotView.isHidden  = !select
    //self.sbdSPPaySystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
    // self.sbdSPPaySystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.view.layoutIfNeeded()
  }

  func selectDeclinePayout(select : Bool) {

    // is100SPSelected = false
    self.declinePayoutBtn.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.declinePayoutBtn.layer.borderWidth = 2.0
    declinePayoutDotView.isHidden  = !select
    //self.sbdSPPaySystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
    // self.sbdSPPaySystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.view.layoutIfNeeded()
  }


  func selectfullPaySystem(select : Bool) {
    self.fullPaySystemBtn.layer.borderColor = select ? ColorTheme.cgColor : UIColor.darkGray.cgColor
    self.fullPaySystemBtn.layer.borderWidth = 2.0
    self.fullPaySystemBtnDotViewHeightConstraint.constant = select ? 10 : 0.0
    self.fullPaySystemBtnDotViewWidthConstraint.constant = select ? 10 : 0.0
    self.view.layoutIfNeeded()
  }

  func charitySteemitUrl() -> String {
    return "https://steemit.com/@" + self.charityName
  }

  //MARK: WEB SERVICES


  func loadCharities() {
    ActifitLoader.show(title: Messages.loading_charities, animated: true)
    APIMaster.getCharities(completion: { [weak self] (jsonString, _ ) in
      DispatchQueue.main.async(execute: {
        ActifitLoader.hide()
      })
      if let jsonString = jsonString as? String {
        let data = jsonString.utf8Data()
        do {
          let json = try JSONSerialization.jsonObject(with: data, options: [])
          if let jsonArray = (json as? [[String : Any]]){
            self?.charities = jsonArray.map({Charity.init(info: $0)})
            self?.fillDefaultCharity()
          }
        } catch {
         //TODO: throw error
        }
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

  private func fillDefaultCharity() {

  }

  override
  func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

  }

  func getNotifications(){
    //ActifitLoader.show(title: Messages.loading_notifications, animated: true)
    APIMaster.getNotifications(completion: { [weak self] (jsonString, _ ) in
      guard let self = self else { return }
      DispatchQueue.main.async(execute: {
        ActifitLoader.hide()
      })
      self.getUserSettings()
      if let jsonString = jsonString as? String {
        let data = jsonString.utf8Data()
        do {
          let json = try JSONSerialization.jsonObject(with: data, options: [])
          if let jsonArray = (json as? [[String : Any]]){
            // self?.charities = jsonArray.map({Charity.init(info: $0)})
            self.notifications = jsonArray.map({ NotificationServer.init(info: $0)})

          }
        } catch {
          print("unable to notifications")
        }
      }
      DispatchQueue.main.async(execute: {

        self.setNotificationView()
      })

    }) { (error) in
      DispatchQueue.main.async(execute: {
        ActifitLoader.hide()
      })
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
        self.showAlertWith(title: nil, message: error.localizedDescription)
      })
    }


  }

  private func setNotificationSections(settings: NSDictionary) {
    //        notificationStackView.spacing  = 5
    settings.forEach { element in
      if let value = element.key as? String {
        for notification in self.notifications {
          if notification.category == value, let status = element.value as? Bool {
            // notification.isSelected = status
            notification.changeSelection(selected: status)
          }
        }
      }
      //
    }
    generateNotificationSections()
    //   print(notifications.filter {$0.isSelected == true})
  }


  func createCustomView(notification: NotificationServer) -> UIView {
    let customView = UIView()
    customView.translatesAutoresizingMaskIntoConstraints = false
    customView.heightAnchor.constraint(equalToConstant: 30).isActive = true
    let label = UILabel()
    label.text = notification.name
    label.translatesAutoresizingMaskIntoConstraints = false
    let button = UIButton()
    button.addTarget(self, action: #selector(buttonTapped(sender:)), for: .touchUpInside)
    button.heightAnchor.constraint(equalToConstant: 25).isActive = true
    button.widthAnchor.constraint(equalToConstant: 25).isActive = true
    button.translatesAutoresizingMaskIntoConstraints = false
    button.layer.borderColor =   UIColor.darkGray.cgColor
    button.layer.borderWidth =   2.0
    button.tintColor = .white
    button.tag = notification.category.hashValue
    if notification.isSelected {
      button.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      button.tintColor = .white
      button.backgroundColor = .primaryRedColor()
    } else {
      button.backgroundColor = .white
      button.setImage(nil, for: .normal)
    }

    // Add label and button to the customView
    customView.addSubview(label)
    customView.addSubview(button)
    NSLayoutConstraint.activate([
      button.leadingAnchor.constraint(equalTo: customView.leadingAnchor, constant: 5),
      button.centerYAnchor.constraint(equalTo: customView.centerYAnchor),
    ])

    // Layout constraints for label
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: button.trailingAnchor, constant: 5),
      label.centerYAnchor.constraint(equalTo: button.centerYAnchor),
    ])
    return customView
  }

  @objc func buttonTapped(sender: UIButton) {
    let notSelected = sender.currentImage
    let notification = self.notifications.first { $0.category.hashValue == sender.tag }

    // sender.layer.borderColor = notSelected != nil ? UIColor.clear.cgColor :  UIColor.darkGray.cgColor
    //sender.layer.borderWidth =  notSelected != nil ? 0.0 : 2.0
    if notSelected == nil {
      sender.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
      sender.tintColor = .white
      sender.backgroundColor = .primaryRedColor()
    } else {
      sender.backgroundColor = .white
      sender.setImage(nil, for: .normal)
    }
    guard notification != nil else  {return }
    notification!.changeSelection(selected: !notification!.isSelected)

    // sender.isSelected.toggle()
  }


  func getUserSettings() {
      guard  User.current()?.steemit_username != nil  else {
          return
      }
    // ActifitLoader.show(title: Messages.loading_userSettings, animated: true)
    APIMaster.getUserSettings(params: User.current()!.steemit_username, completion: { [weak self] (jsonString, _ ) in
      guard let self = self else {return}
      DispatchQueue.main.async(execute: {
        ActifitLoader.hide()
      })
      if let jsonString = jsonString as? String {
        let data = jsonString.utf8Data()
        do {
          let json = try JSONSerialization.jsonObject(with: data, options: [])
          if let jsonArray = (json as? NSDictionary){
            if let settings = jsonArray.value(forKey: "settings") as? NSDictionary{

              DispatchQueue.main.async {
                self.setNotificationSections(settings: settings)
                //TODO: refresh the notification with selected or not
                if settings.value(forKey: "notifications_active") as! Bool == true{
                  UIApplication.shared.registerForRemoteNotifications()
                  UserDefaults.standard.setValue(true, forKey: "notifications")
                  self.enableNotifications(select: true)
                  self.disableNotifications(select: false)
                  self.notification = true
                  self.notificationsStack.isHidden = false
                }
                if let postTarget = settings.value(forKey: "post_target_bchain") as? String{
                  if (settings.value(forKey: "post_target_bchain") as! String == "HIVE"){
                  }
                  else if settings.value(forKey: "post_target_bchain") as! String == "HIVE|Blurt"{
                    // self!.blurtChain(select: true)
                    // self!.steamChain(select: false)
                    self.blurtChainButton.isSelected = true
                    self.blurtChainButton.layer.borderWidth = 0.0
                    self.blurtChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
                    self.blurtChainButton.tintColor = ColorTheme
                    self.blurtChain = "Blurt"
                  }
                  else if settings.value(forKey: "post_target_bchain") as! String == "HIVE|Steem"{
                    //  self!.blurtChain(select: false)
                    //  self!.steamChain(select: true)
                    self.steamChainButton.isSelected = true
                    self.steamChainButton.layer.borderWidth = 0.0
                    self.steamChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
                    self.steamChainButton.tintColor = ColorTheme
                    self.steemChain = "Steem"
                  }
                  else if settings.value(forKey: "post_target_bchain") as! String == "HIVE|Steem|Blurt"{
                    //  self!.blurtChain(select: false)
                    //  self!.steamChain(select: true)
                    self.steamChainButton.isSelected = true
                    self.steamChainButton.layer.borderWidth = 0.0
                    self.steamChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
                    self.steamChainButton.tintColor = ColorTheme
                    self.steemChain = "Steem"
                    self.blurtChainButton.isSelected = true
                    self.blurtChainButton.layer.borderWidth = 0.0
                    self.blurtChainButton.setImage(#imageLiteral(resourceName: "check").withRenderingMode(.alwaysTemplate), for: .normal)
                    self.blurtChainButton.tintColor = ColorTheme
                    self.blurtChain = "Blurt"
                  }

                }


              }
              // )

            }

          }
        } catch {
          print("unable to user settings")
        }
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

  func checkLoginAuth(){
    var json: [String: Any] = [:]
    if User.current()?.steemit_username != "" && User.current()?.steemit_username != nil
    {
      json["username"] = User.current()?.steemit_username
    }

    if User.current()?.private_posting_key != "" && User.current()?.private_posting_key != nil{
      json["ppkey"] = User.current()?.private_posting_key
    }

    if self.steemChain != "" && self.blurtChain != ""{
      json["bchain"] = [self.chain, self.steemChain, self.blurtChain]  //default always HIVE
    }
    else if self.steemChain == "" && self.blurtChain != ""{
      json["bchain"] = [self.chain, self.blurtChain]
    }
    else if self.steemChain != "" && self.blurtChain == ""{
      json["bchain"] = [self.chain, self.steemChain]
    }
    else if self.steemChain == "" && self.blurtChain == ""{
      json["bchain"] = ["HIVE"]
    }
    json["keeploggedin"] = "false" //TODO make dynamic
    json["loginsource"] = "ios"

    // ActifitLoader.show(title: Messages.loginMessage, animated: true)
    //        APIMaster.checkLogin(info: json, completion: { [weak self] (jsonString, _ ) in
    //            guard let self = self else { return }
    //           DispatchQueue.main.async(execute: {
    //               ActifitLoader.hide()
    //           })
    //           if let jsonString = jsonString as? String {
    //               let data = jsonString.utf8Data()
    //               do {
    //                   let json = try JSONSerialization.jsonObject(with: data, options: [])
    //                   if let jsonArray = (json as? NSDictionary){
    //                     // self?.leaderboardArray  = jsonArray
    //                       UserDefaults.standard.setValue(jsonArray.value(forKey:"token"), forKey: "authToken")
    //                       print("Auth Token From login = \(jsonArray.value(forKey:"token"))")
    //
    //                       DispatchQueue.main.async {
    //
    //                           self.getNotifications()
    //                       }
    //
    //
    //                   }
    //               } catch {
    //
    //                   print("unable to login")
    //               }
    //               DispatchQueue.main.async(execute: {
    //
    //               })
    //           }
    //       }) { (error) in
    //           DispatchQueue.main.async(execute: {
    //               ActifitLoader.hide()
    //           })
    //           DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
    //               self.showAlertWith(title: nil, message: error.localizedDescription)
    //           })
    //       }

  }

  
  func saveSettingsAPI(){
    guard let username = User.current()?.steemit_username else {
      localSettingsSaving()
      return
    }

    localSettingsSaving()

      var json: [String: Any] = [:]
      if self.steemChain == "" && self.blurtChain == ""{
        json["post_target_bchain"] = "HIVE" //default always HIVE
      }
      else if self.steemChain != "" && self.blurtChain == "" {
        json["post_target_bchain"] = "HIVE|\(self.steemChain)"
      }
      else if self.steemChain == "" && self.blurtChain != "" {
        json["post_target_bchain"] = "HIVE|\(self.blurtChain)"
      }
      else if self.steemChain != "" && self.blurtChain != "" {
        json["post_target_bchain"] = "HIVE|\(self.steemChain)\("|")\(self.blurtChain)"
      }

      json["notifications_active"] = self.notification
      UserDefaults.standard.setValue(self.notification, forKey: "notifications")
      for i in 0 ..< notifications.count{
        if notifications[i].isSelected {
          json[notifications[i].category] = true
        }
      }

      // ActifitLoader.show(title: Messages.loading_userSettings, animated: true)
      APIMaster.updateUserSettings(username: User.current()!.steemit_username, settings: json, completion: { [weak self] (jsonString, _ ) in
        DispatchQueue.main.async(execute: {
          ActifitLoader.hide()
        })
        if let jsonString = jsonString as? String {
          let data = jsonString.utf8Data()
          do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonArray = (json as? NSDictionary){
              if (jsonArray.value(forKey: "success") != nil){
                DispatchQueue.main.async(execute: {
                  //   ActifitLoader.showLoaderStatusImage(sourceVC: self, navigateBack: false , success: true, status: Messages.updatedSettings)
                  //   ActifitLoader.delegate = self as? SwiftLoaderDismissDelegate
                  self!.localSettingsSaving()
                })
              }
            }
          } catch {
            print("unable to update settings")
          }
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
}

extension SettingsVC : UITextViewDelegate {
  func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
    return true
  }
}

extension Date
{
  func toString( dateFormat format  : String ) -> String
  {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    return dateFormatter.string(from: self)
  }

}



//
//  ActivityTrackingVC.swift
//  Actifit
//
//  Created by Hitender kumar on 03/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit
import CoreMotion
import EFCountingLabel
import AVFoundation
import Charts
import Combine
import RealmSwift
import UserNotifications
import FontAwesome_swift
import SafariServices
import SwiftUI
let StepsUpdatedNotification = "StepsUpdatedNotification"

class ActivityTrackingVC: UIViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate,ChartViewDelegate {
  private var coordinator = Coordinator()
  //MARK: OUTLETS
//  var appDelegate = UIApplication.shared.delegate as? AFAppDelegate

  var  gadgetHorizontalStackView = UIStackView()

  @IBOutlet weak var redChatDot: UIView!
  @IBOutlet weak var exchangeListBtn: UIButton!
  @IBOutlet weak var noGadgetsLabel: UILabel!
  @IBOutlet weak var gadgetScrollView: UIScrollView!
  @IBOutlet weak var votingScrollVIiew: UIScrollView!
  @IBOutlet weak var stepsCountLabel : EFCountingLabel!

  @IBOutlet weak var topGuestHeader: UIView!
  var authenticationController: AuthenticationController?
  @IBOutlet weak var switchBtn: UIButton!
  @IBOutlet weak var threeSpeakVideoBtn: UIButton!
  @IBOutlet weak var topUserHeaderView: UIStackView!
  @IBOutlet weak var gatgetTopView: UIView!

  @IBOutlet weak var afitImageView: UIImageView!
  @IBOutlet weak var hiveImageView: UIImageView!
  @IBOutlet weak var blurtImageView: UIImageView!
  @IBOutlet weak var sportImageView: UIImageView!
  @IBOutlet weak var bottomWalletButton: UIButton!
  @IBOutlet weak var afitBalanceLabel: UILabel!
  @IBOutlet weak var exclamationButton: UIButton!
  @IBOutlet weak var graphsStackVIew: UIStackView!
  @IBOutlet weak var username: UILabel!
  @IBOutlet weak var rank: UILabel!
  @IBOutlet weak var todayDate: UILabel!
  @IBOutlet weak var piechartView: PieChartView!
  @IBOutlet weak var dailybarChart: BarChartView!
  @IBOutlet weak var datebarChart: BarChartView!
  @IBOutlet weak var userImage: UIImageView!
  private var viewModel = ActivityTrackingViewModel()
  private var cancellables = Set<AnyCancellable>()
  @IBOutlet weak var collectionVIew: UICollectionView!
  var swipteTimer: Timer?
  let autoScrollDuration: TimeInterval = 2.0 // Ad
  @IBOutlet weak var walletButton: UIButton!

  @IBOutlet weak var percentageLabel: UILabel!
  @IBOutlet weak var notificationButton: UIButton!

  @IBOutlet weak var settingsButton: UIButton!

  @IBOutlet weak var giftButton: UIButton!
  @IBOutlet weak var topSettingsButton: UIButton!
  @IBOutlet weak var trophyButton: UIButton!
  var pageControl: UIPageControl!
  @IBOutlet weak var gaugeButton: UIButton!
  var  bannerImages: [BannerImageModel] = []
  @IBOutlet weak var swipeGraphsButton: UIButton!
  @IBOutlet weak var votingLabel: UILabel!
  @IBOutlet weak var votingButton: UIButton!
  @IBOutlet weak var marketBtn: UIButton!
  @IBOutlet weak var postAndEarnButton: UIButton!
  @IBOutlet weak var referralsBtn: UIButton!
  @IBOutlet weak var socialBtn: UIButton!
  @IBOutlet weak var pictureBtn: UIButton!
  @IBOutlet weak var historyBtn: UIButton!
  @IBOutlet weak var socialsBtn: UIButton!
  @IBOutlet weak var listBtn: UIButton!
  @IBOutlet weak var marketMenuBtn: UIButton!
  @IBOutlet weak var videoTutorialBtn: UIButton!
  @IBOutlet weak var appleWatchBtn: UIButton!
  @IBOutlet weak var wavesBtn: UIButton!
  @IBOutlet weak var chatBtn: UIButton!

  @IBOutlet weak var cloudBtn: UIButton!
  let activityManager = CMMotionActivityManager()
  private let pedometer = CMPedometer()
  /// Real distance (metres) / active calories (kcal) from the active source; `-1` means the
  /// source didn't provide it, so the dashboard falls back to a step-derived estimate.
  private var liveDistanceMeters: Double = -1
  private var liveCalories: Double = -1

  var startDate = Date()
  var timer : Timer?
  var timerAfterFifteen : Timer?
  let album = ActifitAlbum()
//  var stepsArray = [Double]()
  var timeIntervel = [String]()
  var timeArray: [String] = []
  var labels = [String]()
  var dailyLabels = [String]()
  var unitsSold = [Double]()
  var entries = [BarChartDataEntry]()
  var entriesFifteenMinuteIntervel = [BarChartDataEntry]()
  var timeSlot = [String]()
  var initialStepCount = 0
  var revampGoalLabel: UILabel?
  var revampPctLabel: UILabel?
  var revampBigStepLabel: UILabel?
  var revampGiftBtn: UIButton?
  /// Throttles re-fetching the server AFIT estimate as steps change (avoids spamming the endpoint).
  private var lastEstRewardSteps: Int = -1
  /// Last step count pushed into the revamp hero, so every source (device /
  /// HealthKit / Fitbit) refreshes it while we avoid re-animating on no-op repeats.
  var lastRevampSteps = -1
  var auraView: AuraView?
  var streakDayCircles: [UIView] = []
  var streakDayLabels: [UILabel] = []
  var streakCountLabel: UILabel?
  var revampRewardHintLabel: UILabel?
  var revampVotingLabel: UILabel?
  var revampEstRewardLabel: UILabel?
  var revampNudgeCard: UIView?
  var revampCommunityStack: UIStackView?
  var revampRouteSummaryLabel: UILabel?
  var revampTweetBanners: [BannerImageModel] = []
  var lastNewsCarouselWidth: CGFloat = 0
  weak var revampScrollView: UIScrollView?
  var revampSourceLogoBtn: UIButton?
  var revampCloudBtn: UIButton?
  var revampPostFab: UIButton?
  var revampPostFabWidth: NSLayoutConstraint?
  var revampPostFabCollapsed = false
  var heatmapCells: [(day: Int, view: UIView)] = []
  var activityDateToSave = Date()
  private var activityUpdateTimer: Timer?
  private var isQueryingActivity = false

  let serialQueue = DispatchQueue(label: "com.actifit.serialQueue")
  override func viewDidLoad() {
    super.viewDidLoad()
    setUI()
    setAccessibilityIdentifiers()
    checkForUpdates()
    setupRevampedDashboard()
  }

  // The revamp news carousel is re-pointed after layout; its full-width paging cells
  // need a valid collection-view width. Re-lay them out once the width is known.
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    if let cv = collectionVIew, cv.bounds.width > 0, lastNewsCarouselWidth != cv.bounds.width {
      lastNewsCarouselWidth = cv.bounds.width
      cv.collectionViewLayout.invalidateLayout()
      cv.reloadData()
    }
  }

  /// Stable identifiers for the icon-only dashboard shortcuts so UI tests can
  /// target them reliably (they have no visible text label).
  private func setAccessibilityIdentifiers() {
    wavesBtn?.accessibilityIdentifier = "waves"
    marketBtn?.accessibilityIdentifier = "store"
    giftButton?.accessibilityIdentifier = "gift"
    referralsBtn?.accessibilityIdentifier = "referrals"
    swipeGraphsButton?.accessibilityIdentifier = "stats"
  }

  @IBAction func postAndEarnTapped(_ sender: Any) {
    if viewModel.isLoggedIn {
      if viewModel.canPost {
        let postToseemitVC = PostToSeemitView(coordinator: self.coordinator)
        let childView = UIHostingController(rootView: postToseemitVC)
          if let navigationController = self.navigationController {
              childView.navigationController?.navigationBar.isHidden = true
              self.navigationController?.pushViewController(childView, animated: true)

          } else {
              self.present(childView, animated: true)
          }
        coordinator.$action.sink { [weak self] action in
          switch action {
          case .sharePost(let url):
            self?.navigationController?.popViewController(animated: true)
            let itemsToShare = [url]
            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            self?.present(activityViewController, animated: true, completion: nil)
          case .dismiss:
            self?.navigationController?.popViewController(animated: true)
          case .viewPost(let url):
            let safary = SFSafariViewController(url: URL(string: url)!)

            self?.navigationController?.popViewController(animated: true)
            self?.present(safary, animated: true)
          default: break
          }
           }.store(in: &cancellables)
      } else {
        self.showAlertWith(title: nil, message: Messages.one_post_per_day_error)
      }
    } else {
      showToast(message: "Please login first")
      return
    }
  }

  @IBAction func switchBtnTapped(_ sender: Any) {
    toogleCloudAndWatchBtns()
  }

  private func toogleCloudAndWatchBtns() {
    viewModel.switchSensor(isThirdParty: !viewModel.isThirdPartySensor)
    if !viewModel.isThirdPartySensor {
      cloudBtn.isHidden = true
      appleWatchBtn.isHidden = true
      queryAndUpdateDatafromMidnight()
    } else {
      cloudBtn.isHidden = false
      appleWatchBtn.isHidden = false
      pieChart(stepsCount: viewModel.lastFitbitSteps)
    }
  }

  @IBAction func appleWatchTapped(_ sender: Any) {
    if let lastSyncDate = viewModel.lastSyncFitbitDate, lastSyncDate != "" {
      showToast(message: "Last Synchronization at: \(lastSyncDate)")
    }
  }
  
  @IBAction func cloudBtnTapped(_ sender: Any) {
    // The cloud button syncs the currently-selected source.
    switch viewModel.trackingMode {
    case .health:
      syncHealthSteps()
    case .fitbit:
      self.authenticationController = AuthenticationController(delegate: self)
      self.authenticationController?.login(fromParentViewController: self)
    case .device:
      break   // device mode auto-syncs; no manual sync needed
    }
  }

  /// Reads today's step count from Apple Health (Watch/Health app) and displays it.
  func syncHealthSteps() {
    HealthKitManager.shared.requestAuthorization { [weak self] success, _ in
      guard let self = self, success else { return }
      HealthKitManager.shared.retrieveTodayMetrics { steps, distanceMeters, kcal in
        DispatchQueue.main.async {
          self.viewModel.lastHealthSteps = Int(steps)
          self.viewModel.updateHealthSyncDate()
          self.initialStepCount = Int(steps)
          // Real Health distance/calories (-1 when Health has no source → estimate).
          self.liveDistanceMeters = distanceMeters
          self.liveCalories = kcal
          self.lastRevampSteps = -1   // force the rings to refresh with the new real values
          self.showStepsCount(count: Int(steps))
          self.showToast(message: "Synced \(Int(steps)) steps from Apple Health")
        }
      }
    }
  }

  func getHealthKitPermission() {
      HealthKitManager.shared.requestAuthorization { [weak self] (success, error) in
        guard let self = self else { return }
          if success {
              print("Permission accepted.")
              HealthKitManager.shared.retrieveStepCount { (steps) in
                  print("Steps Retrieved:", steps)
                  DispatchQueue.main.async {
                    self.initialStepCount = Int(steps)
                      if self.viewModel.isThirdPartySensor {
                          self.showStepsCount(count: self.viewModel.lastFitbitSteps)
                      } else {
                          self.showStepsCount(count: Int(steps))
                      }
                  }
              }
          }
      }
  }

  @IBAction func bottomMenuBtnTapped(_ sender: UIButton ) {
    switch sender.tag {
    case 1: break;
    case 2: snapPicBtnAction()
    case 3: viewTrackingHistoryAction()
    case 4: viewDailyLeaderboardAction()
    case 5: openSocialMediaPopup()
    case 6: break;
    case 7: openVideoTutorial()
    case 8:
      blinkChatIcon(blink: false)
      openChat();
    default: break
    }
  }

  private func openChat() {
    let vc = ChatViewController()
    vc.modalPresentationStyle = .overFullScreen
    self.present(vc, animated: true)
  }

  private func openVideoTutorial() {
    self.present(TutorialVideoViewController.create(), animated: true)
  }

  @IBAction func wavesBtnTapped(_ sender: Any) {
    self.present(WavesPopupViewController.create(steps: initialStepCount, appversion: ApplicationHelper.appVersion), animated: true)
  }

  @IBAction func exchangeBtnTapped(_ sender: Any) {
    self.present(MarketExchangeViewController.create(), animated: true)
  }

  @IBAction func rankBtnAction(_ sender: Any) {
    if rank.text ?? "" != ""{
      guard let url = URL(string: "https://actifit.io/userrank") else { return }
      UIApplication.shared.open(url)
    }
  }

  @IBAction func threeSpeakVideoBtnTapped(_ sender: Any) {
    self.present(ThreeSpeakVideoViewController.create(), animated: true)
  }
  
  override var preferredStatusBarStyle: UIStatusBarStyle {
    return .lightContent
  }

  func checkForUpdates() {
    Task {
      do {
        let updateAvailable = await ApplicationHelper.isUpdateAvailable()
        if updateAvailable {
          let vc = TransparentPopupViewController.create(title: "A new update is available", description: "A new version of Actifit is available on the app store. Click here to update your version",  cancelButtonText: "Skip", actionButtonText: "Update", noteSize: .small, onActionButtonTapped: {
            UIApplication.shared.open(ApplicationHelper().getAppStoreURL)
          })
          self.present(vc, animated: true)
        }
      }
    }
  }

  private func setUI() {
    getHealthKitPermission()
    appleWatchBtn.isHidden = viewModel.isThirdPartySensor ? false : true
    cloudBtn.isHidden  = viewModel.isThirdPartySensor ? false : true
    blinkChatIcon(blink: false)
    redChatDot.layer.cornerRadius = redChatDot.frame.width / 2
    redChatDot.clipsToBounds = true
    if viewModel.isLoggedIn {
      self.topUserHeaderView.isHidden = false
      self.topGuestHeader.isHidden = true
    } else {
      self.topUserHeaderView.isHidden = true
      self.topGuestHeader.isHidden = false
    }
    postAndEarnButton.layer.cornerRadius = 5
    postAndEarnButton.clipsToBounds = true
    wavesBtn.layer.cornerRadius = 5
    wavesBtn.clipsToBounds = true
    collectionVIew.register(UINib(nibName: "BannerImageCell", bundle: nil), forCellWithReuseIdentifier: "BannerImageCell")
    let layout = UICollectionViewFlowLayout()
    layout.scrollDirection = .horizontal
    collectionVIew.collectionViewLayout = layout
    print("History Count" + "\(viewModel.historyFifteenMinute.count)")
    // EFCountingLabel 5.x removed the `format` String property (it only affected
    // count animations, which this label never uses — text is set directly).
    let gesture = UITapGestureRecognizer(target: self, action: #selector(profileBtnAction))
    userImage.isUserInteractionEnabled = true
    userImage.addGestureRecognizer(gesture)
    self.userImage.layer.cornerRadius = 16
    self.userImage.clipsToBounds = true
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationDidEnterBackground, object: nil)
    notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationWillEnterForeground, object: nil)
    checkActifitUserID()
    barEntry()
    setButtonIcons()
    setBindings()
    dailybarChart.isHidden = true
    swipeGraphsButton.setTitle(NSLocalizedString("hourly", comment: ""), for: .normal)
    swipeGraphsButton.backgroundColor = .primaryRedColor()
    swipeGraphsButton.tintColor = .white
    swipeGraphsButton.layer.cornerRadius = 5
    swipeGraphsButton.layer.masksToBounds = true
    votingLabel.translatesAutoresizingMaskIntoConstraints = false
    votingScrollVIiew.translatesAutoresizingMaskIntoConstraints = false
    votingLabel.numberOfLines = 1
    votingLabel.lineBreakMode = .byTruncatingTail
    votingScrollVIiew.addSubview(votingLabel)
    switchBtn.layer.cornerRadius  = 5
    switchBtn.clipsToBounds = true
    NSLayoutConstraint.activate([
      votingLabel.leadingAnchor.constraint(equalTo: votingScrollVIiew.leadingAnchor),
      votingLabel.topAnchor.constraint(equalTo: votingScrollVIiew.topAnchor),
      votingLabel.bottomAnchor.constraint(equalTo: votingScrollVIiew.bottomAnchor),
      votingLabel.widthAnchor.constraint(greaterThanOrEqualTo: votingScrollVIiew.widthAnchor)
    ])
    setGadgetScrolling()
  }

  @IBAction func referralsBtnTapped(_ sender: Any) {
    if viewModel.isLoggedIn {
      self.present(ReferralsPopupViewController.create(), animated: true)
    } else {
      showToast(message: "Please login first")
    }
  }

  private func setGadgetScrolling() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
    gadgetScrollView.addGestureRecognizer(tapGesture)
    gadgetScrollView.contentInset = UIEdgeInsets.zero
    gadgetScrollView.contentOffset = CGPoint(x: 0, y: 0)
    gadgetHorizontalStackView.alignment = .leading
    gadgetHorizontalStackView.axis = .horizontal
    gadgetHorizontalStackView.spacing = 5
    gadgetScrollView.addSubview(gadgetHorizontalStackView)
    gadgetHorizontalStackView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      gadgetHorizontalStackView.leadingAnchor.constraint(equalTo: gadgetScrollView.leadingAnchor),
      gadgetHorizontalStackView.topAnchor.constraint(equalTo: gadgetScrollView.topAnchor),
      gadgetHorizontalStackView.trailingAnchor.constraint(equalTo: gadgetScrollView.trailingAnchor),
      gadgetHorizontalStackView.bottomAnchor.constraint(equalTo: gadgetScrollView.bottomAnchor),
    ])
  }

  @objc func profileBtnAction(_ sender: UITapGestureRecognizer) {
    openNativeProfile()
  }

  /// Opens the native "Living Fitness Identity" profile for the logged-in user
  /// (replaces the old web-profile Safari open).
  func openNativeProfile() {
    guard let username = User.current()?.steemit_username else { return }
    let vc = ProfileViewController(username: username, isSelf: true)
    vc.modalPresentationStyle = .fullScreen
    present(vc, animated: true)
  }

  private func scaleEarnButton() {
    if viewModel.canPost && viewModel.isLoggedIn && self.initialStepCount >= 5000 {
      UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .allowUserInteraction, .autoreverse]) {
        self.postAndEarnButton.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
      }
    }
  }

  private func scaleWaveBtn() {
    if viewModel.isLoggedIn && self.initialStepCount >= 2000 {
      UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .allowUserInteraction, .autoreverse]) {
        self.wavesBtn.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
      }
    }
  }

  private func blinkChatIcon(blink: Bool) {
    if blink == false {
      redChatDot.isHidden = true
    } else {
      redChatDot.isHidden = false
      UIView.animate(withDuration: 1.0, delay: 0, options: [.repeat, .autoreverse], animations: {
        self.redChatDot.alpha = self.redChatDot.isHidden ? 1.0 : 0.0
      }, completion: { _ in
        self.redChatDot.isHidden.toggle()
      })
    }
  }

  private func scalePrizeButton() {
      if viewModel.shouldScalePrizeButton  {
          viewModel.initializePrizesValues()
      UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: {
        self.giftButton?.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
        // The revamp dashboard shows its own gift button (the visible one) — bounce it too.
        self.revampGiftBtn?.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
      }, completion: nil)
    }
  }


  func stopPrizeButtonScaling() {
    giftButton?.layer.removeAllAnimations()
    giftButton?.transform = CGAffineTransform.identity
    revampGiftBtn?.layer.removeAllAnimations()
    revampGiftBtn?.transform = CGAffineTransform.identity
  }

  func stopPostButtonScaling() {
    postAndEarnButton.layer.removeAllAnimations()
    postAndEarnButton.transform = CGAffineTransform.identity

  }

  @IBAction func loginBtnTapped(_ sender: Any) {
    dismiss(animated: true)
  }

  @IBAction func signupBtnTapped(_ sender: Any) {

    let controller = SFSafariViewController(url: AppConstants.createAccountURL)
    present(controller, animated: true, completion: nil)
  }

  @objc func handleTap(_ sender: UITapGestureRecognizer) {
    if sender.state == .ended {
      present(TransparentPopupViewController.create(title: NSLocalizedString("virtual_gadgets", comment: ""), description: NSLocalizedString("virtual_gadgets_details", comment: ""), cancelButtonText: NSLocalizedString("close_upper", comment: ""), actionButtonText: NSLocalizedString("market", comment: ""), noteSize: .medium, onActionButtonTapped: { [weak self] in
        self?.openGadgetMarket()
      }), animated: true)
    }
  }

  private func openGadgetMarket() {
    dismiss(animated: true) { [weak self] in
      guard let self = self else { return }
      let nav = UINavigationController(rootViewController: MarketViewController.create())
      nav.modalPresentationStyle = .fullScreen
      self.present(nav, animated: true)
    }
  }

  @IBAction func giftButtonTapped(_ sender: Any) {
    if viewModel.isLoggedIn {
        present(AdsOptionsViewController.create(steps: viewModel.isThirdPartySensor ? viewModel.lastFitbitSteps : initialStepCount ,animateButton: viewModel.canSeeAd,  prizeSelection: { [weak self] prizeType in
          if(prizeType != .close) {
            self?.stopPrizeButtonScaling()
          }
        }), animated: true)

    } else {
      showToast(message: "Please login first")
    }
  }


  @IBAction func exclamationButtonTapped(_ sender: Any) {
    var body = NSLocalizedString("eligible_tokens_earn", comment: "")
    if(viewModel.blurtObject?.id == nil) {
      body.append(NSLocalizedString("no_blurt_account", comment: ""))
    } else {
      if let balanceString =  viewModel.blurtObject?.balance {
        if let balance = Double.parse(from: balanceString) {
          if balance < 5 {
            body.append(NSLocalizedString("low_blurt_balance", comment: ""))
          } else {

          }
        }
      }
    }
    if let doubleTokens = Double(viewModel.afitTokenObject?.tokens ?? "0.0") {
      if doubleTokens < 5000 {
        body.append(NSLocalizedString("low_afit_balance", comment: ""))
        body.append(NSLocalizedString("minimum_actifity_start", comment: ""))
      }
    }
    body.append(NSLocalizedString("other_token_rewards", comment: ""))
    openPopup(title: NSLocalizedString("potential_token_earnings", comment: ""), description: body, cancelTitle: NSLocalizedString("close_upper", comment: ""), size: .large)
  }

  private func openSocialMediaPopup() {
    let vc = SocialMediaPopupViewController.create()
    present(vc, animated: true)
  }

  private func openDailtyTip(dataModel: [DailyTipsModel]) {
      let vc = TipPopupViewController.create(tips: dataModel, title: NSLocalizedString("random_activit_tip", comment: ""), onClose: { 
    })
    self.present(vc, animated: true)
  }


  @IBAction func swipeGraphsTapped(_ sender: Any) {
    let isDailyChartAHidden = dailybarChart.isHidden
    let isDateChartHidden = datebarChart.isHidden
    // Calculate the new visibility state for the views
    let updatedDayChartVisibility = isDailyChartAHidden ? false : true
    let updatedDateChartVisibilty = isDateChartHidden ? true : false
    self.dailybarChart.alpha = 0.0
    self.datebarChart.alpha = 0.0
    UIView.animate(withDuration: 0.5, animations: {
      self.dailybarChart.alpha = updatedDayChartVisibility ? 0.0 : 1.0
      self.datebarChart.alpha = updatedDateChartVisibilty ? 0.0 : 1.0
      self.dailybarChart.isHidden = updatedDayChartVisibility
      self.datebarChart.isHidden = updatedDateChartVisibilty
    })

    swipeGraphsButton.setTitle(NSLocalizedString(isDailyChartAHidden ? "daily" :"hourly", comment: ""), for: .normal)
  }

  private func setGadgetUI() {
    DispatchQueue.main.async {
      if self.viewModel.gadgetsList.isEmpty {
        self.gatgetTopView.isHidden = true
        self.noGadgetsLabel.isHidden = false
        self.noGadgetsLabel.font = UIFont.systemFont(ofSize: 15)
        self.noGadgetsLabel.textColor = .darkGray
        self.noGadgetsLabel.text = NSLocalizedString("no_active_gadgets", comment: "")
        self.noGadgetsLabel.numberOfLines = 0

      } else {
        self.gatgetTopView.isHidden = false
        self.noGadgetsLabel.isHidden = true
        for index in 0..<self.viewModel.gadgetsList.count {
          let resizedImg = self.resizedImage(image: self.viewModel.gadgetsList[index].image ?? UIImage(), targetSize: CGSize(width: 25, height: 25))
          let customItemView = self.createCustomItemView(imageName: resizedImg, digit: self.viewModel.gadgetsList[index].gadgetsLevel)

          customItemView.widthAnchor.constraint(equalToConstant: 40).isActive = true
          customItemView.heightAnchor.constraint(equalToConstant: 35).isActive = true
          self.gadgetHorizontalStackView.addArrangedSubview(customItemView)
        }
      }
      let totalWidth = CGFloat(self.viewModel.gadgetsList.count) * 40 + CGFloat(self.viewModel.gadgetsList.count - 1) * 10 // Considering width + spacing
      self.gadgetHorizontalStackView.widthAnchor.constraint(equalToConstant: totalWidth).isActive = true
      self.gadgetScrollView.contentSize = CGSize(width: totalWidth, height: 40)// Adjust height as needed
      if self.viewModel.gadgetsList.count < 3 {
        self.gadgetScrollView.isScrollEnabled = false
      } else {
        self.gadgetScrollView.isScrollEnabled = true
      }
    }
  }

  func createCustomItemView(imageName: UIImage?, digit: Int) -> UIView {
    let customItemView = UIView()
    let imageView = UIImageView(image:imageName!)
    customItemView.addSubview(imageView)
    let digitLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 10, height: 20))
    digitLabel.translatesAutoresizingMaskIntoConstraints = false
    digitLabel.text = "\(digit)"
    digitLabel.font = UIFont.systemFont(ofSize: 12)
    digitLabel.textColor = .primaryRedColor()
    digitLabel.backgroundColor = .white
    digitLabel.textAlignment = .center
    digitLabel.layer.cornerRadius = 10
    digitLabel.clipsToBounds = true
    customItemView.addSubview(digitLabel)

    NSLayoutConstraint.activate([
      imageView.topAnchor.constraint(equalTo: customItemView.topAnchor),
      imageView.leadingAnchor.constraint(equalTo: customItemView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: customItemView.trailingAnchor),
      imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
      digitLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 20), // Align label with the left edge
      digitLabel.widthAnchor.constraint(equalToConstant: 15),
      digitLabel.heightAnchor.constraint(equalToConstant: 20),
      digitLabel.bottomAnchor.constraint(equalTo: customItemView.bottomAnchor, constant: 5)
    ])
    return customItemView
  }

  func resizedImage(image: UIImage, targetSize: CGSize) -> UIImage {
    let renderer = UIGraphicsImageRenderer(size: targetSize)
    let resizedImage = renderer.image { _ in
      image.draw(in: CGRect(origin: .zero, size: targetSize))
    }
    return resizedImage
  }


  func startAutoScrollTimer() {
    swipteTimer = Timer.scheduledTimer(timeInterval: autoScrollDuration, target: self, selector: #selector(scrollToNextPage), userInfo: nil, repeats: true)
  }

  @objc func scrollToNextPage() {
    let nextPage = pageControl.currentPage + 1
    if nextPage < bannerImages.count {
      let indexPath = IndexPath(item: nextPage, section: 0)
      collectionVIew.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
      pageControl.currentPage = nextPage
    } else {
      pageControl.currentPage = 0
      let indexPath = IndexPath(item: pageControl.currentPage, section: 0)
      collectionVIew.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }
  }

  func setupPageControl() {
    pageControl = UIPageControl()
    pageControl.currentPageIndicatorTintColor = .white
    pageControl.pageIndicatorTintColor = .lightGray
    pageControl.translatesAutoresizingMaskIntoConstraints = false
    collectionVIew.superview?.addSubview(pageControl) // Add to the collection view's superview
    pageControl.centerXAnchor.constraint(equalTo: collectionVIew.centerXAnchor).isActive = true
    pageControl.bottomAnchor.constraint(equalTo: collectionVIew.bottomAnchor, constant: -5).isActive = true
    pageControl.numberOfPages = bannerImages.count
    pageControl.hidesForSinglePage = false
    pageControl.currentPage = 0
  }

  private func setBindings() {

    viewModel.chatBlinkingtriggerPublisher.receive(on: DispatchQueue.main).sink { blink in
      self.blinkChatIcon(blink: blink)
    }.store(in: &cancellables)
    let greyBackground = UIColor(red: 210/255, green: 215/255, blue: 211/255, alpha: 0.5)
    viewModel.blurtPublisher.receive(on: DispatchQueue.main).sink { isDisabled in
      if isDisabled {
        self.blurtImageView.image = UIImage(named: "blurt-icon")?.withTintColor(greyBackground)
        self.blurtImageView.tintColor = greyBackground
      }
    }.store(in: &cancellables)

    viewModel.loaderVisibilityPublisher.receive(on: DispatchQueue.main).sink { showLoader in
      self.changeLoaderStatus(showLoader: showLoader)
    }.store(in: &cancellables)

    viewModel.bannerImagesPublisher.receive(on: DispatchQueue.main).sink { [weak self] bannerItems in
      self?.bannerImages = (self?.revampTweetBanners ?? []) + bannerItems
      self?.setupPageControl()
      DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
        self?.startAutoScrollTimer()
      })
      self?.collectionVIew.reloadData()
    }.store(in: &cancellables)

    viewModel.votingStatusPublisher.receive(on: DispatchQueue.main).sink { votingModel in
      self.votingLabel.text = votingModel.status?.isVoting == false ? votingModel.rewardStart :
      "💰 Rewards Cycle In Progress - Distributing Rewards 💰"
      self.votingScrollVIiew.contentSize = CGSize(width: self.votingLabel.intrinsicContentSize.width, height: 0)
      if votingModel.status?.isVoting == false {
        self.automateVotingScroll()
      }
    }.store(in: &cancellables)

    viewModel.afitTokenPublisher.receive(on: DispatchQueue.main).sink { [weak self] afitTokenModel in
      guard let self = self else {return}
      if let tokens = afitTokenModel.tokens {
      if let doubleTokens = Double(tokens) {
        self.afitBalanceLabel.text = "\(self.viewModel.formatNumberForAfitBalance(doubleTokens)) AFIT"
        if doubleTokens < 5000 {
          self.afitImageView.tintColor = greyBackground
          self.afitImageView.image = UIImage(named: "actifit-mini-icon")?.withTintColor(greyBackground)
        }
      }
    }
    }.store(in: &cancellables)

    viewModel.dailyTipPublisher.receive(on: DispatchQueue.main).sink { [weak self] dailyTips in
      self?.openDailtyTip(dataModel: dailyTips )
    }.store(in: &cancellables)

    viewModel.gadgetPublisher.receive(on: DispatchQueue.main).sink { [weak self] gadgets  in
      guard let self = self else {return}
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
        self.setGadgetUI()
      })
    }.store(in: &cancellables)

    viewModel.pollSurveryPublisher.receive(on: DispatchQueue.main).sink { [weak self] votingModel in
      let pollVC = PollDisplayViewController.create(pollViewModel: PollDisplayViewModel(survey: votingModel))
      pollVC.modalPresentationStyle = .overFullScreen
      self?.present(pollVC, animated: true)
    }.store(in: &cancellables)

    viewModel.rcPercentagePublisher.receive(on: DispatchQueue.main).sink { [weak self] percentage in
      self?.percentageLabel.text = percentage
    }.store(in: &cancellables)

    viewModel.userProfileImagePublisher.receive(on: DispatchQueue.main).sink { [weak self] profilePic in
      guard let self = self else {return}
      if let image = profilePic {
        self.userImage.isHidden = false
        self.userImage.image = image
      }
      else{
        self.userImage.isHidden = true
      }
    }.store(in: &cancellables)

  }

  func automateVotingScroll() {
    if viewModel.statusModel?.status?.isVoting == true {
      let totalScrollDistance = max(0, votingScrollVIiew.contentSize.width - votingScrollVIiew.bounds.width)

      // Set up a timer to scroll the content
      let timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] timer in
        guard let self = self else {
          timer.invalidate()
          return
        }
        let currentOffset = self.votingScrollVIiew.contentOffset.x
        var newOffset = currentOffset + 1.0 // Adjust the scrolling speed as needed
        if newOffset >= totalScrollDistance + 3 {
          // Reset the content offset to start from the beginning
          newOffset = 0
        }
        self.votingScrollVIiew.setContentOffset(CGPoint(x: newOffset, y: 0), animated: false)
      }
      timer.fire()
    }
  }


  func openResourceCreditsPopUp() {
    openPopup(title: NSLocalizedString("resource_credit_title", comment: ""), description: NSLocalizedString("resource_credits_desc", comment: ""), cancelTitle: NSLocalizedString("close_upper", comment: ""), size: .large)
  }

  func openUserRankPopUp() {
    openPopup(title: NSLocalizedString("user_rank_title", comment: ""), description: NSLocalizedString("user_rand_desc", comment: ""), cancelTitle: NSLocalizedString("close_upper", comment: ""), actionTitle: NSLocalizedString("user_rank_Details_upper", comment: ""), size: .large)
  }

  func openPopup(title: String, description: String, cancelTitle: String, actionTitle: String? = nil, size: NoteSize) {
    present(TransparentPopupViewController.create(title: title, description: description, cancelButtonText: cancelTitle, actionButtonText: actionTitle, noteSize: size), animated: true)
  }

  private func openNotificationScreen() {
    navigationController?.pushViewController(NotificationsViewController.create(), animated: true)
  }

  @IBAction func votingButtonTapped(_ sender: Any) {
    openPopup(title: NSLocalizedString("actifit_reward_cycle", comment: ""), description: NSLocalizedString("reward_cycle_details", comment: ""), cancelTitle: "CLOSE", size: .large)
  }

  func changeLoaderStatus(showLoader: Bool) {
    DispatchQueue.main.async {
      showLoader ? SwiftLoader().sharedInstance.show(title: "Loading", animated: true) : SwiftLoader().sharedInstance.hide()
    }
  }

  private func setButtonIcons() {
    trophyButton.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.trophyIcon.rawValue, size: 30), for: .normal)
   // topSettingsButton.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.settingsIcon.rawValue, size: 30), for: .normal)
    notificationButton.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.notificationIcon.rawValue, size: 30), for: .normal)
    walletButton.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.walletIcon.rawValue, size: 30), for: .normal)
    bottomWalletButton.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.walletIcon.rawValue, size: 25), for: .normal)
    let gaugeImage = UIImage(named: "gauge")?.withTintColor(.primaryRedColor())
    let resizedImage = gaugeImage!.imageWithSize(CGSize(width: 30, height: 30))
    gaugeButton.setImage(resizedImage, for: .normal)
    gaugeButton.imageView?.frame = CGRect(x: 0, y: 0, width: 20, height: 20)

    gaugeButton.tintColor = .primaryRedColor()
    votingButton.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.votingIcon.rawValue, size: 30), for: .normal)
    hiveImageView.image = UIImage(named: "hive-icon")
    sportImageView.image = UIImage(named: "sports-icon")
    blurtImageView.image = UIImage(named: "blurt-icon")
    afitImageView.image = UIImage(named: "actifit-mini-icon")
    if let originalImage = UIImage(named: "exclamation-icon")?.withTintColor(.primaryRedColor()) {
        let size = CGSize(width: 25, height: 25)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        originalImage.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        exclamationButton.setImage(resizedImage, for: .normal)
    }

    marketBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.marketButton.rawValue, size: 27), for: .normal)

    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 25) // Adjust the font size
    ]

    let attributedTitle = NSAttributedString(string: viewModel.setGiftButtonUnicodeImage(), attributes: attributes)
    giftButton.setAttributedTitle(attributedTitle, for: .normal)
    giftButton.layer.cornerRadius = 5
    giftButton.clipsToBounds = true
    referralsBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.referralsButton.rawValue, size: 23), for: .normal)
    exchangeListBtn.layer.cornerRadius = 5
    exchangeListBtn.clipsToBounds = true
    exchangeListBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.exchangeList.rawValue, size: 27), for: .normal)
    referralsBtn.layer.cornerRadius = 5
    referralsBtn.clipsToBounds = true
    pictureBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.pictureIcon.rawValue, size: 27), for: .normal)
    let image = UIImage(named: "social-icon")?.imageWithSize(CGSize(width: 30, height: 30))
    socialsBtn.setImage(image!.withTintColor(.primaryRedColor()), for: .normal)
    chatBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.chatIcon.rawValue, size: 27), for: .normal)
    videoTutorialBtn.setImage(UIImage(systemName: "questionmark")?.imageWithSize(CGSize(width: 33, height: 27))?.withTintColor(.primaryRedColor()), for: .normal)
    wavesBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.chatIcon.rawValue, size: 14), for: .normal)
  }

  @IBAction func gaugeButtonTapped(_ sender: Any) {
    openResourceCreditsPopUp()
  }

  @IBAction func onTrophyButtonTapped(_ sender: Any) {
    openUserRankPopUp()
  }

  @IBAction func settingstapped(_ sender: Any) {
    if viewModel.isLoggedIn {
      self.navigationController?.pushViewController(SettingsVC.instantiateWithStoryboard(appStoryboard: .SB_Main), animated: true)
    } else {
      showToast(message: "Please login first")
    }

  }

  @IBAction func notificationsTapped(_ sender: Any) {
    openNotificationScreen()
  }

  @IBAction func walletTapped(_ sender: Any) {
    if viewModel.isLoggedIn {
      navigationController?.pushViewController(WalletAccordionViewController(), animated: true)
    } else {
      showToast(message: "Please login first")
    }
  }

  @IBAction func marketPlaceBtnTapped(_ sender: Any) {
    present(TransparentPopupViewController.create(title: NSLocalizedString("virtual_gadgets", comment: ""), description: NSLocalizedString("virtual_gadgets_details", comment: ""), cancelButtonText: NSLocalizedString("close_upper", comment: ""), actionButtonText: NSLocalizedString("market", comment: ""), noteSize: .medium, onActionButtonTapped: { [weak self] in
      self?.openGadgetMarket()
    }), animated: true)
  }

  func setBtnFontSize(button: UIButton) -> UIButton{
    button.titleLabel?.minimumScaleFactor = 0.5
    button.titleLabel?.numberOfLines = 0
    button.titleLabel?.adjustsFontSizeToFitWidth = true
    return button
  }

  func pieChart(stepsCount: Int)  {
    var  unitsSold = [Double]()
    var  months = [String]()
    let textColor = UIColor.primaryRedColor()
    let dayString = String(describing: stepsCount)
    let centerText = NSAttributedString(string: dayString , attributes: [
      NSAttributedStringKey.foregroundColor:textColor,NSAttributedStringKey.font:UIFont.systemFont(ofSize: 14)])
    piechartView.centerAttributedText = centerText
    piechartView.centerTextRadiusPercent = 1.0
    unitsSold.append(Double(stepsCount))
    months.append("a")
    if (Double(stepsCount) < 5000.0) {
      unitsSold.append(Double(5000.0 - Double(stepsCount)))
      unitsSold.append(Double(5000.0))
      months.append("a")
      months.append("a")
    } else if (Double(stepsCount) < 10000.0) {
      unitsSold.append(Double(10000.0 - Double(stepsCount)))
      months.append("a")
    }

    setChart(dataPoints: months, values: unitsSold)
    piechartView.chartDescription.text = ""

    piechartView.drawEntryLabelsEnabled = false
    piechartView.legend.formToTextSpace = 20
    piechartView.legend.enabled = false
    piechartView.holeRadiusPercent = 0.5
    piechartView.transparentCircleColor = UIColor.clear
    piechartView.drawSlicesUnderHoleEnabled = true
  }

  func setChart(dataPoints: [String], values: [Double]) {
    var dataEntries: [ChartDataEntry] = []
    for i in 0..<dataPoints.count {
      print("Count" + "\(i)")
      let dataEntry = ChartDataEntry(x: Double(i), y:Double(values[i]))
      dataEntries.append(dataEntry)
    }

    let pieChartDataSet = PieChartDataSet(entries: dataEntries, label: "Units Sold")
    let pieChartData = PieChartData(dataSet: pieChartDataSet)
    piechartView.data = pieChartData
    pieChartDataSet.drawValuesEnabled = false
    pieChartDataSet.sliceSpace =  1.0
    pieChartDataSet.highlightEnabled = true
    var colors: [UIColor] = []
    let primaryRedColot = UIColor.primaryRedColor()
    let grayColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
    let greenColor = UIColor.primaryGreenColor()
    if initialStepCount < 5000 {
      colors.append(primaryRedColot)
      colors.append(grayColor)
      colors.append(grayColor)
    }

    else if initialStepCount > 5000 && initialStepCount < 10000 {
      colors.append(grayColor)
      colors.append(greenColor)
      colors.append(greenColor)
    } else {
      colors.append(greenColor)
      colors.append(greenColor)
      colors.append(greenColor)
    }
    pieChartDataSet.colors = colors
  }

  func displayUserAndRank(){
    let comparingDate = Date().dateString()
    todayDate.text =  Date().getTodaysDateWithMonthAndDay()
    let lastRankRequest = UserDefaults.standard.string(forKey: "rankLastRequest")?.date()
    var fetchNewRankVal = false
    if lastRankRequest == nil || UserDefaults.standard.string(forKey: "rank") == nil{
      fetchNewRankVal = true
    }else if comparingDate.date()! > lastRankRequest! {
      fetchNewRankVal = true
    }
    if fetchNewRankVal == false {
      self.rank.text = UserDefaults.standard.string(forKey: "rank")
        if viewModel.user != nil {
        username.isHidden = false
        self.username.text = viewModel.userName
      } else {
        username.isHidden = true
      }
      return
    }
    if let currentUser = viewModel.user {
      if currentUser.steemit_username == "" {
        return
      }
      UserDefaults.standard.set(comparingDate, forKey: "rankLastRequest")
      APIMaster.getRank(username: currentUser.steemit_username,completion: { (response, _ ) in
        if let response = response as? String {
          let data = response.utf8Data()
          do {
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            if let jsonInfo = (json as? NSDictionary){
              if let rank =  jsonInfo["user_rank"] {
                DispatchQueue.main.async(execute: {
                  // let totalRanks = "/100";
                  self.rank.text = "\(rank)"
                  self.username.text = "@\(currentUser.steemit_username)"
                  UserDefaults.standard.set(self.rank.text, forKey: "rank")
                  UserDefaults.standard.set(self.username.text, forKey: "username")
                })
              }
            }
          } catch {

          }
        }
      }, failure: nil)
    }
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.clearFitBitSteps()
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute:  {
      self.scaleEarnButton()
      self.scaleWaveBtn()
    })

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
      self.scalePrizeButton()
    })
    self.navigationController?.setNavigationBarHidden(animated, animated: false)
    self.checkAuthorizationStatusAndStartTracking()
    displayUserAndRank()
    everyDayChart()
      if !self.viewModel.canPost {
          DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
              self.stopPostButtonScaling()
          })
      }
  }

  func showStepsEveryFifttenMinutes() {
    var i:Int =  viewModel.stepsArray.count - 1
    for _ in  viewModel.stepsArray{
      let dateFormatter = DateFormatter()
      dateFormatter.locale = NSLocale.current
      dateFormatter.dateFormat = "hh:mm"
        entriesFifteenMinuteIntervel.append(BarChartDataEntry(x: Double(i), y: viewModel.stepsArray[i]))
      i -= 1
    }
    labels.reverse()
    entriesFifteenMinuteIntervel.reverse()
    let xAxis = dailybarChart.xAxis
    xAxis.labelPosition = .top
    xAxis.labelFont = .systemFont(ofSize: 8)
    xAxis.granularityEnabled = true
    xAxis.granularity = 0.5
    // Keep the hourly axis readable instead of cramming all 96 quarter-hour ticks.
    xAxis.setLabelCount(8, force: false)
    xAxis.labelRotationAngle = -45
    xAxis.spaceMax = 73.0
    let leftAxisFormatter = NumberFormatter()
    leftAxisFormatter.minimumFractionDigits = 0
    leftAxisFormatter.maximumFractionDigits = 1
    leftAxisFormatter.negativeSuffix = ""
    leftAxisFormatter.positiveSuffix = ""
    let leftAxis = dailybarChart.leftAxis
    leftAxis.labelFont = .systemFont(ofSize: 8)
    leftAxis.labelCount = 8
    leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
    leftAxis.labelPosition = .outsideChart
    leftAxis.spaceTop = 0.15
    leftAxis.axisMinimum = 0
    let rightAxis = dailybarChart.rightAxis
    rightAxis.enabled = true
    rightAxis.labelFont = .systemFont(ofSize: 8)
    rightAxis.labelCount = 8
    rightAxis.valueFormatter = leftAxis.valueFormatter
    rightAxis.spaceTop = 0.15
    rightAxis.axisMinimum = 0
    dailybarChart.delegate = self
    let set1 = BarChartDataSet(entries: entriesFifteenMinuteIntervel, label: "Today Activity Details")
    let data = BarChartData(dataSet: set1)
    data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 8)!)
    data.barWidth = 0.1
    dailybarChart.data = data
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    stopPostButtonScaling()
    stopPrizeButtonScaling()
  }

  func snapPicBtnAction() {
    checkCameraAuthorizationStatus()
  }

  func viewTrackingHistoryAction() {
    self.navigationController?.pushViewController(TrackingHistoryVC.instantiateWithStoryboard(appStoryboard: .SB_Main), animated: true)
  }

  func viewDailyLeaderboardAction() {
    self.navigationController?.pushViewController(DailyLeaderBoardBVC.instantiateWithStoryboard(appStoryboard: .SB_Main), animated: true)
  }

  func tempTime(){
    let calendar = Calendar.current
    let comp = calendar.dateComponents([.hour, .minute], from: Date())
    let hour = comp.hour ?? 0
    let minute = comp.minute ?? 0
    print(hour)
    let finalMinut:Int = (hour * 60) + minute
    print(finalMinut)
    let lastTime: Double = Double(hour) // 10pm
    var currentTime: Double = 0
    let incrementMinutes: Double = 15 // increment by 15 minutes

    while currentTime <= lastTime {
      currentTime += (incrementMinutes/60)
      let hours = Int(floor(currentTime))
      let minutes = Int(currentTime.truncatingRemainder(dividingBy: 1)*60)
      if minutes == 0 {
        timeIntervel.append("\(hours):00")
      } else {
        timeIntervel.append("\(hours):\(minutes)")
      }
    }
  }

  func addtimeIntoDate(minutes:Int)  -> Date {
    var timeInterval = DateComponents()
    timeInterval.month = 0
    timeInterval.day = 0
    timeInterval.hour = minutes/60
    timeInterval.minute =  minutes%60
    timeInterval.second = 0
    return Calendar.current.date(byAdding: timeInterval, to: Date())!
  }
  //MARK: HELPERS

  func checkActifitUserID(){
    var actifitUserID = UserDefaults.standard.string(forKey: "actifitUserID") ?? ""
    if actifitUserID == ""{
      let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
      let uuid = NSUUID().uuidString
      actifitUserID = "\(uuid)\(appVersion)"
      UserDefaults.standard.set(actifitUserID, forKey: "actifitUserID")
    }
  }

  @objc func appMovedToBackground() {
    self.timer?.invalidate()
    self.timerAfterFifteen?.invalidate()
  }

  @objc func appMovedToForeground() {
    let calender = Calendar.autoupdatingCurrent
    if !(calender.isDateInToday(startDate)) {
      let yesterdayStartDate = AppDelegate.startDateFor(date: self.startDate)
      if let after24HoursAfteYyesterdayStartDate = Calendar.current.date(
        byAdding: .hour,
        value: 24,
        to: yesterdayStartDate) {
        var yesterdayStartDate = Date().yesterday.setTime(hour: 00, min: 00, sec: 00)!
        let currentDate = yesterdayStartDate
        let timezoneOffset =  TimeZone.current.secondsFromGMT()
        let epochDate = currentDate.timeIntervalSince1970
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        yesterdayStartDate = Date(timeIntervalSince1970: timezoneEpochOffset)
        var toDate = Date().setTime(hour: 00, min: 00, sec: 00)!
        let currentDate1 = toDate
        let timezoneOffset1 =  TimeZone.current.secondsFromGMT()
        let epochDate1 = currentDate1.timeIntervalSince1970
        let timezoneEpochOffset1 = (epochDate1 + Double(timezoneOffset1))
        toDate = Date(timeIntervalSince1970: timezoneEpochOffset1)
        self.pedometer.queryPedometerData(from: yesterdayStartDate, to: toDate) {
          [weak self] pedometerData, error in
          guard let pedometerData = pedometerData, error == nil else { return }
          DispatchQueue.main.async {
            print("yesterday total steps : \(pedometerData.numberOfSteps)")
            self?.saveCurrentStepsCounts(steps: pedometerData.numberOfSteps.intValue, midnightStartDate: yesterdayStartDate)
          }
        }
      }
      DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        self.checkAuthorizationStatusAndStartTracking()
      }
    } else {
      self.checkAuthorizationStatusAndStartTracking()
    }
  }

  @objc func queryAndUpdateDatafromMidnight(isFromThirdParty: Bool = false) {
    let calender = Calendar.autoupdatingCurrent
    if !(calender.isDateInToday(startDate)) {
      self.showStepsCount(count: 0)
      self.checkAuthorizationStatusAndStartTracking()
    } else {
      let allActivities = Activity.all()
      if allActivities.count == 0{
        self.addDataForPreviousDate()
      }
      self.pedometer.queryPedometerData(from: AppDelegate.todayStartDate(), to: Date()) {
        [weak self] pedometerData, error in
        guard let self = self else {return}
        guard let pedometerData = pedometerData, error == nil else { return }
        DispatchQueue.main.async {

          let totalSteps = pedometerData.numberOfSteps.intValue
          switch self.viewModel.trackingMode {
          case .fitbit:
              // Fitbit: display the last synced Fitbit count (synced on demand via the cloud button).
              self.viewModel.updateDateSync()
              self.initialStepCount = self.viewModel.lastFitbitSteps
              self.showStepsCount(count: self.viewModel.lastFitbitSteps)
          case .health:
              // Apple Health: display the last synced Health count (synced on demand via the cloud button).
              self.initialStepCount = self.viewModel.lastHealthSteps
              self.showStepsCount(count: self.viewModel.lastHealthSteps)
          case .device:
              // Device (CoreMotion): live, auto-synced. CMPedometer gives real distance
              // (but no calories, so those stay a step estimate).
              self.liveDistanceMeters = pedometerData.distance?.doubleValue ?? -1
              self.liveCalories = -1
              UserDefaults.standard.lastSynchronizedSteps = totalSteps
              self.showStepsCount(count: totalSteps)
              if self.initialStepCount != totalSteps {
                self.initialStepCount = totalSteps
                self.saveCurrentStepsCounts(steps: totalSteps, midnightStartDate: AppDelegate.todayStartDate())
                NotificationCenter.default.post(name: Notification.Name.init(StepsUpdatedNotification), object: nil, userInfo: ["steps" : totalSteps])
              }
          }
        }
      }
    }
  }

  @objc func addDataForPreviousDate() {
    var yesterdayStartDate = Date().yesterday.setTime(hour: 00, min: 00, sec: 00)!
    let currentDate = yesterdayStartDate
    let timezoneOffset =  TimeZone.current.secondsFromGMT()
    let epochDate = currentDate.timeIntervalSince1970
    let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
    yesterdayStartDate = Date(timeIntervalSince1970: timezoneEpochOffset)
    var toDate = Date().setTime(hour: 00, min: 00, sec: 00)!
    let currentDate1 = toDate
    let timezoneOffset1 =  TimeZone.current.secondsFromGMT()
    let epochDate1 = currentDate1.timeIntervalSince1970
    let timezoneEpochOffset1 = (epochDate1 + Double(timezoneOffset1))
    toDate = Date(timeIntervalSince1970: timezoneEpochOffset1)
    let yest = AppDelegate.todayStartDate().yesterday
    self.pedometer.queryPedometerData(from: yest, to: AppDelegate.todayStartDate()) {
      [weak self] pedometerData, error in
      guard let pedometerData = pedometerData, error == nil else { return }
      let allActivities = Activity.all()
      DispatchQueue.main.sync {
        let totalSteps = pedometerData.numberOfSteps.intValue
        let activtyInfo = [ActivityKeys.id : allActivities.count, ActivityKeys.date : yesterdayStartDate, ActivityKeys.steps : totalSteps] as [String : Any] //11223344
        let activity = Activity()
        activity.upadteWith(info: activtyInfo)
      }
    }
  }

  // Mark: Remove this to viewModel
  @objc func queryAndUpdateDatafromMidnightFifteenMinute() {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
    let calender = Calendar.autoupdatingCurrent
    if !(calender.isDateInToday(startDate)) {
    } else {
      serialQueue.async {
        let date12 = Date().dateString()
        for index in 0..<self.timeSlot.count - 1 {
          let startdate  = self.timeSlot[index]
          let endDate  = self.timeSlot[index + 1]
          let sDate = date12 +  " \(startdate)"
          let eDate = date12 +  " \(endDate)"
          let date1  =  dateFormatter.date(from: sDate)
          let date2 =  dateFormatter.date(from: eDate)
          if let date1New = date1 {
            if let date2New = date2 {
              self.pedometer.queryPedometerData(from: date1New, to: date2New) {
                [weak self] pedometerData, error in
                guard let pedometerData = pedometerData, error == nil else { return }
                if pedometerData.numberOfSteps.intValue != 0 {
                  DispatchQueue.main.sync {
                    let totalSteps = pedometerData.numberOfSteps.intValue
                    let today = Date().dateString()
                    self?.saveAfterFifteenMinute(steps: totalSteps, midnightStartDate: today, timeInterval:  endDate, id: index)
                  }
                } else {
                  return
                }
              }
            }
          }
        }
      }
    }
  }
}

extension ActivityTrackingVC {
  //on start event handler
  private func checkAuthorizationStatusAndStartTracking() {
    //resetting the start date when wiew appears
    self.startDate = Date()
    checkAuthorizationStatus()
    DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: {
      self.startUpdating()
    })
  }

  //on stop event handler
  private func onStop() {
    stopUpdating()
  }
  //stop updating user activity
  private func stopUpdating() {
    activityManager.stopActivityUpdates()
    pedometer.stopUpdates()
    pedometer.stopEventUpdates()
  }
  //check for activity authorization Status

  private func checkCameraAuthorizationStatus() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized: // The user has previously granted access to the camera.
      DispatchQueue.main.async {
        self.takePicture()
      }

    case .notDetermined: // The user has not yet been asked for camera access.
      AVCaptureDevice.requestAccess(for: .video) { granted in
        if granted {
          DispatchQueue.main.async {
            self.takePicture()
          }
        }
      }

    case .denied: // The user has previously denied access.
      self.showAlertWith(title: "Alert", message: "Please enable the camera usage under settings")
      return
    case .restricted: // The user can't grant access due to restrictions.
      self.showAlertWith(title: "Alert", message: "Please enable the camera usage under settings")
      return
    }
  }

  private func checkAuthorizationStatus() {
    switch CMMotionActivityManager.authorizationStatus() {
    case CMAuthorizationStatus.denied:
      onStop()
      stepsCountLabel.text = "Not available"
    default:break
    }
  }

  //track activity types if Motion activity is available on user device
  private func startUpdating() {
    if CMMotionActivityManager.isActivityAvailable() {
      startTrackingActivityType()
    } else {
      print("Not available")
    }

    if CMPedometer.isStepCountingAvailable() {
      self.startQueryingActivityEveryTwoSecond()
    } else {
      stepsCountLabel.text = "Not available"
    }
  }

  //save/update user current steps from today midnight
  private func saveCurrentStepsCounts(steps : Int, midnightStartDate : Date) {
      viewModel.saveCurrentStepsCounts(steps: steps, midnightStartDate: midnightStartDate)
  }

  //save/update user current steps from today midnight
  private func saveAfterFifteenMinute(steps : Int, midnightStartDate : String, timeInterval:String, id:Int) {
    if !ActivityFifteenMinutesInterval.all().filter({$0.id == id && $0.steps == steps}).isEmpty {
      return
    }
    do {
      let realm = try Realm()
      let allActivities = ActivityFifteenMinutesInterval()
      allActivities.date = midnightStartDate
      allActivities.interval = timeInterval
      allActivities.steps = steps
      allActivities.id = id
      allActivities.idInString = String(id)
      allActivities.stepsInString = String(steps)
      do {
        try realm.write {
          realm.add(allActivities, update: .modified) //true  //1122
        }
      }
      let allsavedRecordsOfHistory = AllRecordsOfActivitiesNew.all()
      let arrayOfActivities = viewModel.historyFifteenMinute // ActivityFifteenMinutesInterval.all()
      let allRecordsOfActivitiesNew = AllRecordsOfActivitiesNew()
      allRecordsOfActivitiesNew.date = midnightStartDate
      let encoder = JSONEncoder()
      let encodedData: Data? = try? encoder.encode(arrayOfActivities)
      allRecordsOfActivitiesNew.activitiesListData = encodedData
      if let activityInHistory = allsavedRecordsOfHistory.first(where: {$0.date == midnightStartDate}){
        try! realm.write {
          activityInHistory.activitiesListData = allRecordsOfActivitiesNew.activitiesListData
        }

      } else {
        let activityToSave = ["id":allsavedRecordsOfHistory.count+1,"date": midnightStartDate, "activitiesListData":allRecordsOfActivitiesNew.activitiesListData] as [String : Any]
        allRecordsOfActivitiesNew.saveWith(info: activityToSave)
      }

      if id == timeSlot.count - 2{
        self.everyDayChart()
      }
    } catch let error as NSError {
      print(error.localizedDescription)
    }
  }

  func everyDayChart()  {
    self.entries.removeAll()
    self.labels.removeAll()
    var i:Int = viewModel.history.count - 1
    // var _:Int = historyFifteenMinute.count
    for tempData in viewModel.history {
      let tempLabel = tempData.date.dateString()
      if !labels.contains(tempLabel){
        labels.append(tempLabel)
        entries.append(BarChartDataEntry(x: Double(i), y: Double(tempData.steps)))
        i -= 1
      }
    }
    labels.reverse()
    entries.reverse()
    print(labels)
    print(entries)
    let xAxis = datebarChart.xAxis
    xAxis.labelPosition = .top
    xAxis.labelFont = .systemFont(ofSize: 8)
    xAxis.granularity = 1
    xAxis.labelCount = 7
    xAxis.valueFormatter = DayAxisValueFormatter(chart: datebarChart, labels: labels) as AxisValueFormatter
    let leftAxisFormatter = NumberFormatter()
    leftAxisFormatter.minimumFractionDigits = 0
    leftAxisFormatter.maximumFractionDigits = 1
    leftAxisFormatter.negativeSuffix = ""
    leftAxisFormatter.positiveSuffix = ""
    let line = ChartLimitLine(limit: 5000, label: "Min Reward - 5K Activity")
    line.lineColor = .primaryRedColor()
    line.valueTextColor = .black
    line.valueFont = .systemFont(ofSize: 10)
    line.lineWidth = 1
    let line2 = ChartLimitLine(limit: 10000, label: "Min Reward - 10K Activity")
    line2.lineColor = .primaryGreenColor()
    line2.valueTextColor = .black
    line2.valueFont = .systemFont(ofSize: 10)
    line2.lineWidth = 1
    let leftAxis = datebarChart.leftAxis
    leftAxis.labelFont = .systemFont(ofSize: 8)
    leftAxis.labelCount = 8
    leftAxis.valueFormatter = DefaultAxisValueFormatter(formatter: leftAxisFormatter)
    leftAxis.labelPosition = .outsideChart
    leftAxis.spaceTop = 0.15
    leftAxis.axisMinimum = 0
    leftAxis.addLimitLine(line)
    leftAxis.addLimitLine(line2)
    let rightAxis = datebarChart.rightAxis
    rightAxis.enabled = true
    rightAxis.labelFont = .systemFont(ofSize: 8)
    rightAxis.labelCount = 8
    rightAxis.valueFormatter = leftAxis.valueFormatter
    rightAxis.spaceTop = 0.15
    rightAxis.axisMinimum = 0
    datebarChart.delegate = self
    let set1 = BarChartDataSet(entries: entries, label: "This month")
    let data = BarChartData(dataSet: set1)
    data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 8)!)
    data.barWidth = 0.5
    datebarChart.data = data
  }

  private func startTrackingActivityType() {
    activityManager.startActivityUpdates(to: OperationQueue.main) { [weak self]
      (activity: CMMotionActivity?) in
      guard let self = self, let activity = activity else { return }
      DispatchQueue.main.async {
        if activity.walking {
          print("Walking")
          self.startQueryingActivityEveryTwoSecond()
        } else if activity.stationary {
          print("Stationary")
        } else if activity.running {
          print("Running")
          self.startQueryingActivityEveryTwoSecond()
        } else if activity.automotive {
          print("Automotive")
        }
      }
    }
  }

  //ask pedometer to start updating the user data on regular basis
  private func startQueryingActivityEveryTwoSecond() {
    if viewModel.isThirdPartySensor {
      self.initialStepCount = UserDefaults.standard.lastSynchronizedSteps
      self.pieChart(stepsCount: viewModel.lastFitbitSteps)
    }

      self.queryAndUpdateDatafromMidnight(isFromThirdParty: viewModel.isThirdPartySensor)
      self.queryAndUpdateDatafromMidnightFifteenMinute()
  }

  //show the user activity data on UI
  private func showStepsCount(count : Int) {
    self.pieChart(stepsCount: count)
    // Keep the revamped hero (big number + activity rings) in sync for EVERY
    // source — device sensors, Apple Health and Fitbit all funnel through here.
    refreshRevampSteps(count)
      if viewModel.isFitSystemSelected {
      self.stepsCountLabel.text = "Fitbit Tracking Mode On"
      return
    }

    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    self.stepsCountLabel.text = "Total Activity Today: " + (formatter.string(from: NSNumber(value: Int(count))) ?? "")
   // self.historyFifteenMinute = viewModel.historyFifteenMinute  // ActivityFifteenMinutesInterval.all()
   // self.history = Activity.allWithoutCountZero()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
      self.barEntry()
    })
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5, execute: {
      self.everyDayChart()
    })
  }

  func checkAndPostNotification(count:Int) {
    viewModel.checkAndPostNotification(count: count)
  }

  // funtion to open the camera for taking picture
  func takePicture(){
    let imagePicker =  UIImagePickerController()
    imagePicker.delegate = self
    imagePicker.sourceType = .camera
    present(imagePicker, animated: true, completion: nil)
  }
  // MARK: Delegates
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    picker.dismiss(animated: true, completion: nil)
    let image = info[UIImagePickerControllerOriginalImage] as? UIImage
    album.save(image: image!)
  }

  func barEntry() {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = NSLocale.current
    dateFormatter.dateFormat = "HH:mm"
    var entriesFifteenMinuteIntervel = [BarChartDataEntry]()
    let timeSlot: [String] = {
      var labels = [String](repeating: String(), count: 96)
      for indHr in 0..<24 {
        for indMin in 0..<4 {
          let slotLabel = String(format: "%02d:%02d", indHr, indMin * 15)
          labels[indHr * 4 + indMin] = slotLabel
        }
      }
      return labels
    }()
    self.timeSlot = timeSlot
    let backgroundQueue = DispatchQueue(label: "com.yourapp.backgroundQueue")
    backgroundQueue.async {
      var k = timeSlot.count - 1

      for slotLabel in timeSlot {
        let contents = self.viewModel.historyFifteenMinute.filter { $0.date == Date().getTodaysDateYearAndMonthAndDay() && $0.interval == slotLabel }

        if !contents.isEmpty && contents[0].steps > 0 {
          let time2 = slotLabel.replacingOccurrences(of: ":", with: ".")
          entriesFifteenMinuteIntervel.append(BarChartDataEntry(x: Double(time2)! * 4.0, y: Double(contents[0].steps)))
        }
        k -= 1
      }

      DispatchQueue.main.async { [self] in
        let xAxis = dailybarChart.xAxis
        xAxis.labelPosition = .top
        xAxis.labelFont = .systemFont(ofSize: 8)
        xAxis.granularityEnabled = true
        xAxis.granularity = 1.0
        // 96 quarter-hour slots overlapped when every label was drawn; show a
        // sparse, angled subset so the times stay readable (Charts thins them).
        xAxis.setLabelCount(8, force: false)
        xAxis.labelRotationAngle = -45
        xAxis.valueFormatter = IndexAxisValueFormatter(values: timeSlot)
        let set1 = BarChartDataSet(entries: entriesFifteenMinuteIntervel, label: "Today Activity Details")
        let data = BarChartData(dataSet: set1)
        data.setValueFont(UIFont(name: "HelveticaNeue-Light", size: 8)!)
        data.barWidth = 0.1
        dailybarChart.data = data
      }
    }
    dailybarChart.setScaleMinima(1.5, scaleY: 0.0)
  }
}

extension ActivityTrackingVC: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UIScrollViewDelegate {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return bannerImages.count
  }

  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BannerImageCell", for: indexPath) as? BannerImageCell
    cell?.bannerObject = bannerImages[indexPath.row]
    cell?.onGradientTap =  { [weak self] url in
      guard let self = self else { return }
      self.present(SFSafariViewController(url: URL(string: url ?? "")!), animated: true)
    }
    return cell!
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    if scrollView === revampScrollView {
      // Android Extended-FAB behaviour: collapse the Post & Earn pill to an
      // icon-only circle once the dashboard scrolls past the hero card.
      updatePostFab(collapsed: scrollView.contentOffset.y > 40)
      return
    }
    if(scrollView != gadgetScrollView) {
      let pageWidth = collectionVIew.frame.width
      let currentPage = Int((scrollView.contentOffset.x + pageWidth / 1.5) / pageWidth)
      pageControl.currentPage = currentPage
    }
  }
}

extension ActivityTrackingVC: AuthenticationProtocol {
  func authorizationDidFinish(_ success: Bool) {
    guard let authToken = authenticationController?.authenticationToken else {
        viewModel.switchSensor(isThirdParty: false)
      return
    }
    FitbitAPI.sharedInstance.authorize(with: authToken)
    let syncDate = self.activityDateToSave
    let _ = StepStat.fetchTodaysStepStat(forDate: syncDate) { [weak self] stepStat, error in
      guard let self = self else { return }
      let steps = stepStat?.steps ?? 0
      self.initialStepCount = Int(steps)
      self.showStepsCount(count:  self.initialStepCount)
      viewModel.switchSensor(isThirdParty: true)
      self.viewModel.switchToFitbitSensor(steps: Int(stepStat?.steps ?? 0))
      // Also pull Fitbit's real distance + calories for the multi-metric rings (Android PR #83).
      self.fetchFitbitMetrics(forDate: syncDate)
    }
  }
}

// MARK: - Dashboard revamp (Android redesign) — first pass: header + hero activity card
// Adds an opaque programmatic overlay on top of the existing storyboard dashboard and
// re-points the tracking outlets (pie chart, step label, avatar, rank, date) to the new
// views, so CoreMotion step tracking keeps working while the layout is redesigned.
extension ActivityTrackingVC {

    private var revampRed: UIColor { UIColor(named: "primaryRed") ?? UIColor(red: 1.0, green: 0.067, blue: 0.176, alpha: 1) }

    func setupRevampedDashboard() {
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.backgroundColor = UIColor(white: 0.96, alpha: 1)
        scroll.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 120, right: 0)
        scroll.showsVerticalScrollIndicator = false
        scroll.delegate = self
        revampScrollView = scroll
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.spacing = 14
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 12, left: 16, bottom: 24, right: 16)
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        content.addArrangedSubview(buildRevampHeader())
        content.addArrangedSubview(buildRevampHeroCard())
        content.addArrangedSubview(buildRevampNewsCarousel())
        content.addArrangedSubview(buildRevampNudgeCard())
        content.addArrangedSubview(buildRevampCommunityCard())
        content.addArrangedSubview(buildRevampRouteCard())
        content.addArrangedSubview(buildRevampEarningsCard())
        content.addArrangedSubview(buildRevampActionButtons())
        content.addArrangedSubview(buildRevampChartCard())
        content.addArrangedSubview(buildRevampHeatmapCard())

        addRevampPostFab()

        NotificationCenter.default.addObserver(self, selector: #selector(revampStepsUpdated(_:)), name: Notification.Name(StepsUpdatedNotification), object: nil)
        let user = User.current()?.steemit_username.byTrimming(string: "@") ?? ""
        auraView?.setCompanion(CompanionUtil.resolveCompanion(username: user, isSelf: true))
        pieChart(stepsCount: initialStepCount)   // updates the hidden dummy pie harmlessly
        // Funnel the initial paint through refreshRevampSteps (not updateAura directly) so the
        // counter text and 📏/🔥 metrics line get set too — updateAura only draws the rings now.
        refreshRevampSteps(initialStepCount)

        viewModel.votingStatusPublisher.receive(on: DispatchQueue.main).sink { [weak self] model in
            self?.revampVotingLabel?.text = model.status?.isVoting == false ? (model.rewardStart ?? "") : "Rewards cycle in progress…"
        }.store(in: &cancellables)
        // (Estimate is now fetched via refreshRevampSteps above, and refreshed as steps change.)
        fetchTweets()
        NotificationCenter.default.addObserver(self, selector: #selector(refreshRouteCard), name: RouteRecordingManager.recordingStopped, object: nil)
    }

    // MARK: Route Tracking card

    private func buildRevampRouteCard() -> UIView {
        let card = revampCard()
        card.backgroundColor = UIColor(red: 0.99, green: 0.94, blue: 0.95, alpha: 1)
        let green = UIColor(red: 0, green: 0.6, blue: 0.2, alpha: 1)

        let icon = UILabel(); icon.text = "🗺️"; icon.font = .systemFont(ofSize: 16); icon.setContentHuggingPriority(.required, for: .horizontal)
        let title = UILabel(); title.text = "Route Tracking"; title.font = .systemFont(ofSize: 16, weight: .bold); title.textColor = UIColor(white: 0.13, alpha: 1)
        let recordBtn = UIButton(type: .system)
        recordBtn.setTitle("Record", for: .normal)
        recordBtn.setTitleColor(revampRed, for: .normal)
        recordBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        recordBtn.layer.borderColor = revampRed.cgColor
        recordBtn.layer.borderWidth = 1.5
        recordBtn.layer.cornerRadius = 8
        recordBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        recordBtn.setContentHuggingPriority(.required, for: .horizontal)
        recordBtn.addTarget(self, action: #selector(routeRecordTapped), for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [icon, title, recordBtn]); header.axis = .horizontal; header.spacing = 8; header.alignment = .center

        let summary = UILabel()
        summary.font = .systemFont(ofSize: 14)
        summary.textColor = green
        summary.numberOfLines = 0
        revampRouteSummaryLabel = summary
        let viewBtn = UIButton(type: .system)
        viewBtn.setTitle("View ›", for: .normal)
        viewBtn.setTitleColor(revampRed, for: .normal)
        viewBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        viewBtn.setContentHuggingPriority(.required, for: .horizontal)
        viewBtn.addTarget(self, action: #selector(routeViewTapped), for: .touchUpInside)
        let summaryRow = UIStackView(arrangedSubviews: [summary, viewBtn]); summaryRow.axis = .horizontal; summaryRow.spacing = 8; summaryRow.alignment = .center

        let startBtn = UIButton(type: .system)
        startBtn.setTitle("▶  Start Recording", for: .normal)
        startBtn.setTitleColor(.white, for: .normal)
        startBtn.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        startBtn.backgroundColor = revampRed
        startBtn.layer.cornerRadius = 24
        startBtn.heightAnchor.constraint(equalToConstant: 50).isActive = true
        startBtn.addTarget(self, action: #selector(routeRecordTapped), for: .touchUpInside)

        let vstack = UIStackView(arrangedSubviews: [header, summaryRow, startBtn])
        vstack.axis = .vertical; vstack.spacing = 12
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        pinToEdges(vstack, card)
        refreshRouteCard()
        return card
    }

    @objc func refreshRouteCard() {
        if let route = Route.mostRecent() {
            revampRouteSummaryLabel?.text = "\(route.formattedDistance)  •  \(route.formattedDuration)  •  \(route.activityType)"
        } else {
            revampRouteSummaryLabel?.text = "No route recorded yet"
        }
    }

    @objc private func routeRecordTapped() {
        if RouteRecordingManager.isRunning {
            present(RouteMapViewController.create(mode: .live, activityType: RouteRecordingManager.shared.activityType), animated: true)
            return
        }
        let status = RouteRecordingManager.shared.authorizationStatus
        if status == .denied || status == .restricted {
            showToast(message: "Location permission is required to record routes.")
            return
        }
        RouteRecordingManager.shared.requestAuthorization { [weak self] in
            self?.presentActivityPicker()
        }
    }

    @objc private func routeViewTapped() {
        guard let route = Route.mostRecent() else { showToast(message: "No route to view yet"); return }
        present(RouteMapViewController.create(mode: .view, date: route.date), animated: true)
    }

    private func presentActivityPicker() {
        let types = ["Walking", "Running", "Cycling", "Hiking", "Jogging", "Skating", "Skiing", "Geocaching", "Photowalking", "Plogging", "Sailing", "Scootering", "Kayaking"]
        let sheet = UIAlertController(title: "Activity Type", message: nil, preferredStyle: .actionSheet)
        for t in types {
            sheet.addAction(UIAlertAction(title: t, style: .default) { [weak self] _ in self?.startRouteRecording(t) })
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController { pop.sourceView = view; pop.sourceRect = view.bounds }
        present(sheet, animated: true)
    }

    private func startRouteRecording(_ type: String) {
        RouteRecordingManager.shared.start(activityType: type)
        present(RouteMapViewController.create(mode: .live, activityType: type), animated: true)
    }

    // MARK: Community strip

    private func fetchTweets() {
        API().getLatestXPost(completion: { [weak self] info, _ in
            guard let s = info as? String,
                  let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any],
                  let tweets = json["tweets"] as? [[String: Any]] else { return }
            let banners: [BannerImageModel] = tweets.prefix(2).compactMap { t in
                let text = t["tweetText"] as? String ?? ""
                let url = t["tweetUrl"] as? String ?? ""
                guard !text.isEmpty, !url.isEmpty else { return nil }
                return BannerImageModel(id: "tweet", featuredImageUrl: t["tweetImageUrl"] as? String, newsTitle: text, linkUrl: url, date: t["tweetTimestamp"] as? String)
            }
            guard !banners.isEmpty else { return }
            DispatchQueue.main.async {
                self?.revampTweetBanners = banners
                let nonTweet = (self?.bannerImages ?? []).filter { $0.id != "tweet" }
                self?.bannerImages = banners + nonTweet
                self?.pageControl?.numberOfPages = self?.bannerImages.count ?? 0
                self?.collectionVIew?.reloadData()
            }
        }, failure: { _ in })
    }

    private func buildRevampEarningsCard() -> UIView {
        let card = revampCard()
        card.backgroundColor = UIColor(red: 0.99, green: 0.94, blue: 0.95, alpha: 1)
        let green = UIColor(red: 0, green: 0.6, blue: 0.2, alpha: 1)

        let title = UILabel()
        title.text = "💰  Earnings & Gadgets"
        title.font = .systemFont(ofSize: 16, weight: .bold)
        title.textColor = UIColor(white: 0.13, alpha: 1)
        let divider = UIView(); divider.backgroundColor = UIColor(white: 0.88, alpha: 1)
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let clock = UILabel(); clock.text = "⏳"; clock.font = .systemFont(ofSize: 15)
        clock.setContentHuggingPriority(.required, for: .horizontal)
        let countdown = UILabel(); countdown.font = .systemFont(ofSize: 15); countdown.textColor = UIColor(white: 0.25, alpha: 1); countdown.numberOfLines = 0
        revampVotingLabel = countdown
        let countdownRow = UIStackView(arrangedSubviews: [clock, countdown]); countdownRow.axis = .horizontal; countdownRow.spacing = 8; countdownRow.alignment = .center

        let estTitle = UILabel(); estTitle.text = "Estimated Reward"; estTitle.font = .systemFont(ofSize: 14, weight: .semibold); estTitle.textColor = green
        let est = UILabel(); est.text = "—"; est.font = .systemFont(ofSize: 24, weight: .bold); est.textColor = revampRed; est.numberOfLines = 0
        revampEstRewardLabel = est

        let tokens = UILabel(); tokens.text = "HIVE · BLURT · SPORTS"; tokens.font = .systemFont(ofSize: 13, weight: .semibold); tokens.textColor = green

        let market = UIButton(type: .system)
        market.setTitle("🛒 Market  ›", for: .normal)
        market.setTitleColor(revampRed, for: .normal)
        market.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        market.contentHorizontalAlignment = .left
        market.addTarget(self, action: #selector(revampEarningsMarketTapped), for: .touchUpInside)

        let vstack = UIStackView(arrangedSubviews: [title, divider, countdownRow, estTitle, est, tokens, market])
        vstack.axis = .vertical; vstack.spacing = 8
        vstack.setCustomSpacing(12, after: divider)
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        pinToEdges(vstack, card)
        return card
    }

    @objc private func revampEarningsMarketTapped() {
        let nav = UINavigationController(rootViewController: MarketViewController.create())
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true)
    }

    private func fetchEstimatedReward(steps: Int) {
        guard let username = User.current()?.steemit_username.byTrimming(string: "@").lowercased() else { return }
        API().getEstimatedReward(username: username, steps: steps, completion: { [weak self] info, _ in
            guard let s = info as? String,
                  let json = (try? JSONSerialization.jsonObject(with: s.utf8Data())) as? [String: Any] else { return }
            let est = (json["estimated_afit"] as? Double) ?? Double("\(json["estimated_afit"] ?? "0")") ?? 0
            let already = (json["already_rewarded"] as? Bool) ?? false
            DispatchQueue.main.async {
                self?.revampEstRewardLabel?.text = already ? String(format: "%.1f AFIT (last reward)", est) : String(format: "~%.1f AFIT (estimated)", est)
            }
        }, failure: { _ in })
    }

    private func buildRevampHeader() -> UIView {
        let avatar = UIImageView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 50).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 50).isActive = true
        avatar.layer.cornerRadius = 25
        avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.backgroundColor = UIColor(white: 0.9, alpha: 1)
        avatar.isUserInteractionEnabled = true
        avatar.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(openProfileFromRevamp)))
        avatar.image = userImage?.image
        userImage = avatar   // re-point

        let name = User.current()?.steemit_username.byTrimming(string: "@") ?? ""
        let nameLabel = UILabel()
        nameLabel.text = "@\(name)"
        nameLabel.font = .systemFont(ofSize: 20, weight: .bold)
        nameLabel.textColor = revampRed

        let trophy = UILabel()
        trophy.text = "🏆"
        trophy.font = .systemFont(ofSize: 15)
        let rankLabel = UILabel()
        rankLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        rankLabel.textColor = revampRed
        rankLabel.text = rank?.text
        rank = rankLabel   // re-point so rank binding updates it
        let rankRow = UIStackView(arrangedSubviews: [trophy, rankLabel])
        rankRow.axis = .horizontal
        rankRow.spacing = 5
        rankRow.alignment = .center

        let nameStack = UIStackView(arrangedSubviews: [nameLabel, rankRow])
        nameStack.axis = .vertical
        nameStack.spacing = 3
        nameStack.alignment = .leading
        nameStack.setContentHuggingPriority(.defaultLow, for: .horizontal)

        let bell = revampIconButton(system: "bell.fill", action: #selector(notificationsTapped(_:)))
        let walletBtn = revampIconButton(system: "creditcard.fill", action: #selector(walletTapped(_:)))
        let settingsBtn = revampIconButton(system: "gearshape.fill", action: #selector(settingstapped(_:)))

        let header = UIStackView(arrangedSubviews: [avatar, nameStack, bell, walletBtn, settingsBtn])
        header.axis = .horizontal
        header.spacing = 12
        header.alignment = .center
        return header
    }

    private func buildRevampHeroCard() -> UIView {
        let card = revampCard()
        card.backgroundColor = UIColor(red: 0.99, green: 0.91, blue: 0.92, alpha: 1) // rose tint
        card.layer.shadowOpacity = 0.06

        let dateLabel = UILabel()
        dateLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        dateLabel.textColor = revampRed
        dateLabel.textAlignment = .center
        dateLabel.text = todayDate?.text
        todayDate = dateLabel   // re-point

        // Hidden 1pt dummy pie keeps the existing tracking's pieChart() harmless.
        let dummyPie = PieChartView()
        dummyPie.isHidden = true
        dummyPie.translatesAutoresizingMaskIntoConstraints = false
        piechartView = dummyPie

        let aura = AuraView()
        aura.translatesAutoresizingMaskIntoConstraints = false
        // Clean disc behind the counter, matching the card colour (Android AuraView parity).
        aura.centerDiscColor = card.backgroundColor
        auraView = aura

        // The disc gives the counter a clean surface; the counter colour is milestone-driven at
        // runtime in refreshRevampSteps (brand red below the goal, green once hit) — matching
        // Android's tv_step_count_hc. Secondary grey for the goal + metrics lines.
        let textSecondary = UIColor(white: 0.46, alpha: 1)  // ~#757575

        let bigStep = UILabel()
        bigStep.text = "0"
        bigStep.font = .systemFont(ofSize: 26, weight: .bold)
        bigStep.textColor = revampRed
        bigStep.textAlignment = .center
        revampBigStepLabel = bigStep

        let goalLabel = UILabel()
        goalLabel.font = .systemFont(ofSize: 12)
        goalLabel.textColor = textSecondary
        goalLabel.textAlignment = .center
        goalLabel.text = "/ 10,000 steps"
        revampGoalLabel = goalLabel

        // Third line surfaces distance + calories (populated in updateRevampGoal); was "% to goal".
        // Bold for legibility (Android parity).
        let pctLabel = UILabel()
        pctLabel.font = .systemFont(ofSize: 11, weight: .bold)
        pctLabel.textColor = textSecondary
        pctLabel.textAlignment = .center
        pctLabel.text = ""
        revampPctLabel = pctLabel

        let centerText = UIStackView(arrangedSubviews: [bigStep, goalLabel, pctLabel])
        centerText.axis = .vertical
        centerText.spacing = 0
        centerText.alignment = .center
        centerText.translatesAutoresizingMaskIntoConstraints = false

        let auraContainer = UIView()
        auraContainer.translatesAutoresizingMaskIntoConstraints = false
        auraContainer.heightAnchor.constraint(equalToConstant: 236).isActive = true
        auraContainer.addSubview(dummyPie)
        auraContainer.addSubview(aura)
        auraContainer.addSubview(centerText)
        NSLayoutConstraint.activate([
            aura.topAnchor.constraint(equalTo: auraContainer.topAnchor),
            aura.bottomAnchor.constraint(equalTo: auraContainer.bottomAnchor),
            aura.centerXAnchor.constraint(equalTo: auraContainer.centerXAnchor),
            aura.widthAnchor.constraint(equalTo: aura.heightAnchor),
            centerText.centerXAnchor.constraint(equalTo: aura.centerXAnchor),
            centerText.centerYAnchor.constraint(equalTo: aura.centerYAnchor, constant: 18),
            dummyPie.topAnchor.constraint(equalTo: auraContainer.topAnchor),
            dummyPie.leadingAnchor.constraint(equalTo: auraContainer.leadingAnchor)
        ])

        // Corner icons around the ring.
        // Top-left: dynamic source logo (Apple Health / Fitbit) — hidden in device mode; tap shows last sync.
        let sensorTL = UIButton(type: .custom)
        sensorTL.translatesAutoresizingMaskIntoConstraints = false
        sensorTL.imageView?.contentMode = .scaleAspectFit
        sensorTL.contentHorizontalAlignment = .fill
        sensorTL.contentVerticalAlignment = .fill
        sensorTL.heightAnchor.constraint(equalToConstant: 32).isActive = true
        sensorTL.widthAnchor.constraint(equalToConstant: 32).isActive = true
        sensorTL.addTarget(self, action: #selector(revampSourceLogoTapped), for: .touchUpInside)
        revampSourceLogoBtn = sensorTL
        // Top-right: cloud sync — hidden in device mode.
        let cloudTR = revampIconButton(system: "icloud.and.arrow.down.fill", action: #selector(cloudBtnTapped(_:)))
        revampCloudBtn = cloudTR
        let shareBL = revampIconButton(system: "square.and.arrow.up", action: #selector(revampShareTapped))
        // Bottom-right: cycle device -> Apple Health -> Fitbit -> device.
        let swapBR = revampIconButton(system: "arrow.left.arrow.right", action: #selector(revampCycleTrackingMode))
        [sensorTL, cloudTR, shareBL, swapBR].forEach { auraContainer.addSubview($0) }
        NSLayoutConstraint.activate([
            sensorTL.leadingAnchor.constraint(equalTo: auraContainer.leadingAnchor),
            sensorTL.topAnchor.constraint(equalTo: auraContainer.topAnchor, constant: 8),
            cloudTR.trailingAnchor.constraint(equalTo: auraContainer.trailingAnchor),
            cloudTR.topAnchor.constraint(equalTo: auraContainer.topAnchor, constant: 8),
            shareBL.leadingAnchor.constraint(equalTo: auraContainer.leadingAnchor),
            shareBL.bottomAnchor.constraint(equalTo: auraContainer.bottomAnchor, constant: -8),
            swapBR.trailingAnchor.constraint(equalTo: auraContainer.trailingAnchor),
            swapBR.bottomAnchor.constraint(equalTo: auraContainer.bottomAnchor, constant: -8)
        ])
        applyTrackingModeUI()

        let consistency = buildConsistencyRow()

        let vstack = UIStackView(arrangedSubviews: [dateLabel, auraContainer, consistency])
        vstack.axis = .vertical
        vstack.spacing = 12
        vstack.alignment = .fill
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        NSLayoutConstraint.activate([
            vstack.topAnchor.constraint(equalTo: card.topAnchor),
            vstack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            vstack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            vstack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    private func buildConsistencyRow() -> UIView {
        let divider = UIView()
        divider.backgroundColor = UIColor(white: 0.85, alpha: 1)
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let fire = UILabel(); fire.text = "🔥"; fire.font = .systemFont(ofSize: 16)
        fire.setContentHuggingPriority(.required, for: .horizontal)
        let title = UILabel(); title.text = "Consistency"; title.font = .systemFont(ofSize: 16, weight: .bold); title.textColor = UIColor(white: 0.13, alpha: 1)
        let count = UILabel(); count.font = .systemFont(ofSize: 14, weight: .semibold); count.textColor = revampRed; count.textAlignment = .right; count.text = "No streak yet"
        streakCountLabel = count
        let header = UIStackView(arrangedSubviews: [fire, title, count])
        header.axis = .horizontal; header.spacing = 6; header.alignment = .center

        streakDayCircles.removeAll(); streakDayLabels.removeAll()
        var cols: [UIView] = []
        for _ in 0..<7 {
            let circle = UIView()
            circle.translatesAutoresizingMaskIntoConstraints = false
            circle.widthAnchor.constraint(equalToConstant: 26).isActive = true
            circle.heightAnchor.constraint(equalToConstant: 26).isActive = true
            circle.layer.cornerRadius = 13
            circle.layer.borderWidth = 1.5
            circle.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
            let check = UILabel(); check.text = "✓"; check.textColor = .white; check.font = .systemFont(ofSize: 13, weight: .bold); check.textAlignment = .center; check.isHidden = true
            check.translatesAutoresizingMaskIntoConstraints = false
            circle.addSubview(check)
            NSLayoutConstraint.activate([check.centerXAnchor.constraint(equalTo: circle.centerXAnchor), check.centerYAnchor.constraint(equalTo: circle.centerYAnchor)])
            let day = UILabel(); day.font = .systemFont(ofSize: 10); day.textColor = .gray; day.textAlignment = .center; day.text = "-"
            let col = UIStackView(arrangedSubviews: [circle, day])
            col.axis = .vertical; col.spacing = 3; col.alignment = .center
            cols.append(col)
            streakDayCircles.append(circle)
            streakDayLabels.append(day)
        }
        let daysRow = UIStackView(arrangedSubviews: cols)
        daysRow.axis = .horizontal; daysRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [divider, header, daysRow])
        stack.axis = .vertical; stack.spacing = 10
        return stack
    }

    private func buildRevampNewsCarousel() -> UIView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.translatesAutoresizingMaskIntoConstraints = false
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .clear
        cv.register(UINib(nibName: "BannerImageCell", bundle: nil), forCellWithReuseIdentifier: "BannerImageCell")
        cv.dataSource = self
        cv.delegate = self
        cv.layer.cornerRadius = 14
        cv.clipsToBounds = true
        cv.heightAnchor.constraint(equalToConstant: 150).isActive = true
        collectionVIew = cv   // re-point

        let pc = UIPageControl()
        pc.translatesAutoresizingMaskIntoConstraints = false
        pc.currentPageIndicatorTintColor = revampRed
        pc.pageIndicatorTintColor = UIColor(white: 0.75, alpha: 1)
        pc.numberOfPages = bannerImages.count
        pc.hidesForSinglePage = true
        pc.currentPage = 0
        pageControl = pc   // re-point

        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(cv)
        container.addSubview(pc)
        NSLayoutConstraint.activate([
            cv.topAnchor.constraint(equalTo: container.topAnchor),
            cv.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            cv.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            cv.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            pc.centerXAnchor.constraint(equalTo: cv.centerXAnchor),
            pc.bottomAnchor.constraint(equalTo: cv.bottomAnchor, constant: -6)
        ])
        cv.reloadData()
        return container
    }

    private func pinToEdges(_ inner: UIView, _ outer: UIView) {
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: outer.topAnchor),
            inner.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: outer.trailingAnchor),
            inner.bottomAnchor.constraint(equalTo: outer.bottomAnchor)
        ])
    }

    private func revampColor(_ v: Int) -> UIColor {
        UIColor(red: CGFloat((v >> 16) & 0xFF) / 255.0, green: CGFloat((v >> 8) & 0xFF) / 255.0, blue: CGFloat(v & 0xFF) / 255.0, alpha: 1)
    }

    // MARK: 4 red action buttons (existing handlers)

    private func revampRedActionButton(system: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: system), for: .normal)
        b.tintColor = .white
        b.backgroundColor = revampRed
        b.layer.cornerRadius = 12
        b.imageView?.contentMode = .scaleAspectFit
        b.heightAnchor.constraint(equalToConstant: 54).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    private func buildRevampActionButtons() -> UIView {
        let gift = revampRedActionButton(system: "gift.fill", action: #selector(giftButtonTapped(_:)))
        revampGiftBtn = gift   // keep a reference so the prize bounce animates the visible button
        let refer = revampRedActionButton(system: "person.badge.plus.fill", action: #selector(referralsBtnTapped(_:)))
        let buy = revampRedActionButton(system: "chart.line.uptrend.xyaxis", action: #selector(exchangeBtnTapped(_:)))
        let waves = revampRedActionButton(system: "bubble.left.and.bubble.right.fill", action: #selector(wavesBtnTapped(_:)))
        let row = UIStackView(arrangedSubviews: [gift, refer, buy, waves])
        row.axis = .horizontal
        row.distribution = .fillEqually
        row.spacing = 12
        return row
    }

    // MARK: Activity history chart (re-point existing BarChartViews)

    private func buildRevampChartCard() -> UIView {
        let card = revampCard()
        let title = UILabel()
        title.text = "Activity History"
        title.font = .systemFont(ofSize: 16, weight: .bold)
        title.textColor = UIColor(white: 0.13, alpha: 1)

        let toggle = UIButton(type: .system)
        toggle.setTitle("Hourly", for: .normal)
        toggle.setTitleColor(.white, for: .normal)
        toggle.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        toggle.backgroundColor = revampRed
        toggle.layer.cornerRadius = 14
        toggle.contentEdgeInsets = UIEdgeInsets(top: 6, left: 16, bottom: 6, right: 16)
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        toggle.addTarget(self, action: #selector(swipeGraphsTapped(_:)), for: .touchUpInside)
        swipeGraphsButton = toggle

        let headerRow = UIStackView(arrangedSubviews: [title, toggle])
        headerRow.axis = .horizontal
        headerRow.alignment = .center

        let daily = BarChartView()   // hourly data
        daily.translatesAutoresizingMaskIntoConstraints = false
        daily.isHidden = true
        dailybarChart = daily
        let date = BarChartView()    // daily data
        date.translatesAutoresizingMaskIntoConstraints = false
        datebarChart = date

        let chartContainer = UIView()
        chartContainer.translatesAutoresizingMaskIntoConstraints = false
        chartContainer.heightAnchor.constraint(equalToConstant: 200).isActive = true
        [daily, date].forEach { chartContainer.addSubview($0); pinToEdges($0, chartContainer) }

        let vstack = UIStackView(arrangedSubviews: [headerRow, chartContainer])
        vstack.axis = .vertical
        vstack.spacing = 10
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        pinToEdges(vstack, card)
        everyDayChart()   // populate the (visible) daily chart from history
        return card
    }

    // MARK: Month heatmap (net-new — Android tier parity)

    private func buildRevampHeatmapCard() -> UIView {
        let card = revampCard()
        card.backgroundColor = UIColor(red: 0.99, green: 0.94, blue: 0.95, alpha: 1)
        heatmapCells.removeAll()

        let cal = Calendar.current
        let now = Date()
        let df = DateFormatter(); df.dateFormat = "MMMM yyyy"
        let title = UILabel()
        title.text = "📅  " + df.string(from: now)
        title.font = .systemFont(ofSize: 16, weight: .bold)
        title.textColor = UIColor(white: 0.13, alpha: 1)

        let dayHeader = UIStackView(arrangedSubviews: ["M", "T", "W", "T", "F", "S", "S"].map { s -> UILabel in
            let l = UILabel(); l.text = s; l.font = .systemFont(ofSize: 11); l.textColor = .gray; l.textAlignment = .center; return l
        })
        dayHeader.axis = .horizontal; dayHeader.distribution = .fillEqually

        let comps = cal.dateComponents([.year, .month, .day], from: now)
        let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
        let firstOfMonth = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: 1)) ?? now
        let firstDOW = cal.component(.weekday, from: firstOfMonth) // 1=Sun..7=Sat
        let leadingBlanks = firstDOW == 1 ? 6 : firstDOW - 2

        let grid = UIStackView(); grid.axis = .vertical; grid.spacing = 4
        let totalSlots = leadingBlanks + daysInMonth
        let rows = Int(ceil(Double(totalSlots) / 7.0))
        var slot = 0
        for _ in 0..<rows {
            let r = UIStackView(); r.axis = .horizontal; r.distribution = .fillEqually; r.spacing = 4
            for _ in 0..<7 {
                let cell = UIView()
                cell.heightAnchor.constraint(equalToConstant: 22).isActive = true
                cell.layer.cornerRadius = 11
                cell.backgroundColor = .clear
                if slot >= leadingBlanks && slot < leadingBlanks + daysInMonth {
                    heatmapCells.append((slot - leadingBlanks + 1, cell))
                }
                r.addArrangedSubview(cell)
                slot += 1
            }
            grid.addArrangedSubview(r)
        }

        let vstack = UIStackView(arrangedSubviews: [title, dayHeader, grid, buildHeatmapLegend()])
        vstack.axis = .vertical; vstack.spacing = 8
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.layoutMargins = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        pinToEdges(vstack, card)
        updateHeatmap()
        return card
    }

    private func buildHeatmapLegend() -> UIView {
        func item(_ hex: Int, _ text: String) -> UIView {
            let dot = UIView(); dot.backgroundColor = revampColor(hex)
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.widthAnchor.constraint(equalToConstant: 12).isActive = true
            dot.heightAnchor.constraint(equalToConstant: 12).isActive = true
            dot.layer.cornerRadius = 6
            let l = UILabel(); l.text = text; l.font = .systemFont(ofSize: 11); l.textColor = .gray
            let s = UIStackView(arrangedSubviews: [dot, l]); s.axis = .horizontal; s.spacing = 4; s.alignment = .center
            return s
        }
        let row = UIStackView(arrangedSubviews: [item(0xD0D0D0, "0"), item(0xFFCDD2, "< 5K"), item(0xEF9A9A, "5–7K"), item(0xFF112D, "7K+")])
        row.axis = .horizontal; row.distribution = .equalSpacing
        return row
    }

    func updateHeatmap() {
        guard !heatmapCells.isEmpty else { return }
        let cal = Calendar.current
        let now = Date()
        let comps = cal.dateComponents([.year, .month, .day], from: now)
        let todayDay = comps.day ?? 1
        for (day, cell) in heatmapCells {
            let date = cal.date(from: DateComponents(year: comps.year, month: comps.month, day: day)) ?? now
            let steps = stepsForDate(date)
            let color: UIColor
            if day > todayDay { color = revampColor(0xEEEEEE) }
            else if steps <= 0 { color = revampColor(0xD0D0D0) }
            else if steps < 5000 { color = revampColor(0xFFCDD2) }
            else if steps < 7000 { color = revampColor(0xEF9A9A) }
            else { color = revampColor(0xFF112D) }
            cell.backgroundColor = color
        }
    }

    // MARK: Post & Earn floating FAB (Android Extended FAB)
    // Floats above the dashboard (over the scroll view, above the tab bar) as an
    // expanded "Post & Earn" pill and collapses to an icon-only circle on scroll.

    private func addRevampPostFab() {
        let fab = UIButton(type: .system)
        fab.setTitle("  Post & Earn", for: .normal)
        fab.setImage(UIImage(systemName: "square.and.pencil"), for: .normal)
        fab.tintColor = .white
        fab.setTitleColor(.white, for: .normal)
        fab.titleLabel?.font = .systemFont(ofSize: 17, weight: .bold)
        fab.backgroundColor = revampRed
        fab.layer.cornerRadius = 28
        fab.layer.shadowColor = UIColor.black.cgColor
        fab.layer.shadowOpacity = 0.25
        fab.layer.shadowRadius = 8
        fab.layer.shadowOffset = CGSize(width: 0, height: 4)
        fab.translatesAutoresizingMaskIntoConstraints = false
        fab.addTarget(self, action: #selector(postAndEarnTapped(_:)), for: .touchUpInside)
        view.addSubview(fab)

        let width = fab.widthAnchor.constraint(equalToConstant: 190)
        NSLayoutConstraint.activate([
            fab.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fab.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -14),
            fab.heightAnchor.constraint(equalToConstant: 56),
            width
        ])
        revampPostFab = fab
        revampPostFabWidth = width
    }

    private func updatePostFab(collapsed: Bool) {
        guard collapsed != revampPostFabCollapsed, let fab = revampPostFab else { return }
        revampPostFabCollapsed = collapsed
        fab.setTitle(collapsed ? "" : "  Post & Earn", for: .normal)
        revampPostFabWidth?.constant = collapsed ? 56 : 190
        UIView.animate(withDuration: 0.22, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: Community strip (ranked Actifit feed)

    private func buildRevampCommunityCard() -> UIView {
        let card = revampCard()
        card.backgroundColor = UIColor(red: 0.99, green: 0.94, blue: 0.95, alpha: 1)

        let icon = UILabel(); icon.text = "👥"; icon.font = .systemFont(ofSize: 16)
        icon.setContentHuggingPriority(.required, for: .horizontal)
        let title = UILabel(); title.text = "Community"; title.font = .systemFont(ofSize: 16, weight: .bold); title.textColor = UIColor(white: 0.13, alpha: 1)
        let seeAll = UIButton(type: .system); seeAll.setTitle("See All ›", for: .normal); seeAll.setTitleColor(revampRed, for: .normal); seeAll.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        seeAll.setContentHuggingPriority(.required, for: .horizontal)
        seeAll.addTarget(self, action: #selector(revampCommunitySeeAll), for: .touchUpInside)
        let header = UIStackView(arrangedSubviews: [icon, title, seeAll]); header.axis = .horizontal; header.spacing = 8; header.alignment = .center

        let scroll = UIScrollView(); scroll.showsHorizontalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.heightAnchor.constraint(equalToConstant: 96).isActive = true
        let hstack = UIStackView(); hstack.axis = .horizontal; hstack.spacing = 14; hstack.alignment = .top
        hstack.translatesAutoresizingMaskIntoConstraints = false
        revampCommunityStack = hstack
        scroll.addSubview(hstack)
        NSLayoutConstraint.activate([
            hstack.topAnchor.constraint(equalTo: scroll.topAnchor),
            hstack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor),
            hstack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor),
            hstack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor),
            hstack.heightAnchor.constraint(equalTo: scroll.heightAnchor)
        ])

        let vstack = UIStackView(arrangedSubviews: [header, scroll])
        vstack.axis = .vertical; vstack.spacing = 12
        vstack.isLayoutMarginsRelativeArrangement = true
        vstack.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 14, right: 16)
        vstack.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(vstack)
        pinToEdges(vstack, card)
        fetchCommunity()
        return card
    }

    @objc private func revampCommunitySeeAll() {
        tabBarController?.selectedIndex = 2   // Social tab
    }

    private func fetchCommunity() {
        Task { [weak self] in
            let result = await HTTPClient().getSocialPosts()
            guard case .success(let model) = result else { return }
            await MainActor.run { self?.populateCommunity(model.result) }
        }
    }

    private func populateCommunity(_ posts: [SocialPost]) {
        guard let hstack = revampCommunityStack else { return }
        hstack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for post in posts.prefix(12) {
            hstack.addArrangedSubview(communityMember(author: post.author, steps: post.jsonMetadata.stepCount.first ?? "0"))
        }
    }

    private func communityMember(author: String, steps: String) -> UIView {
        let avatar = UIImageView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.widthAnchor.constraint(equalToConstant: 52).isActive = true
        avatar.heightAnchor.constraint(equalToConstant: 52).isActive = true
        avatar.layer.cornerRadius = 26; avatar.clipsToBounds = true
        avatar.contentMode = .scaleAspectFill
        avatar.backgroundColor = UIColor(white: 0.9, alpha: 1)
        if let url = URL(string: "https://images.hive.blog/u/\(author)/avatar/small") {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data, let img = UIImage(data: data) { DispatchQueue.main.async { avatar.image = img } }
            }.resume()
        }
        let name = UILabel(); name.text = "@\(author)"; name.font = .systemFont(ofSize: 10); name.textColor = .gray; name.textAlignment = .center
        name.lineBreakMode = .byTruncatingTail
        let stepsL = UILabel(); stepsL.text = steps; stepsL.font = .systemFont(ofSize: 12, weight: .bold); stepsL.textColor = revampRed; stepsL.textAlignment = .center
        let col = UIStackView(arrangedSubviews: [avatar, name, stepsL]); col.axis = .vertical; col.spacing = 2; col.alignment = .center
        col.widthAnchor.constraint(equalToConstant: 64).isActive = true
        return col
    }

    private func buildRevampNudgeCard() -> UIView {
        let card = revampCard()
        card.backgroundColor = UIColor(red: 0.99, green: 0.94, blue: 0.95, alpha: 1)
        revampNudgeCard = card

        let accent = UIView()
        accent.backgroundColor = UIColor(red: 1, green: 0.6, blue: 0, alpha: 1) // amber "in progress"
        accent.translatesAutoresizingMaskIntoConstraints = false
        accent.heightAnchor.constraint(equalToConstant: 4).isActive = true
        card.addSubview(accent)
        NSLayoutConstraint.activate([
            accent.topAnchor.constraint(equalTo: card.topAnchor),
            accent.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            accent.trailingAnchor.constraint(equalTo: card.trailingAnchor)
        ])

        let hint = UILabel()
        hint.font = .systemFont(ofSize: 15, weight: .medium)
        hint.textColor = UIColor(white: 0.2, alpha: 1)
        hint.numberOfLines = 0
        revampRewardHintLabel = hint

        let dismiss = UIButton(type: .system)
        dismiss.setImage(UIImage(systemName: "xmark"), for: .normal)
        dismiss.tintColor = revampRed
        dismiss.setContentHuggingPriority(.required, for: .horizontal)
        dismiss.widthAnchor.constraint(equalToConstant: 24).isActive = true
        dismiss.addTarget(self, action: #selector(revampDismissNudge), for: .touchUpInside)

        let row = UIStackView(arrangedSubviews: [hint, dismiss])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .center
        row.isLayoutMarginsRelativeArrangement = true
        row.layoutMargins = UIEdgeInsets(top: 16, left: 16, bottom: 14, right: 14)
        row.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(row)
        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: accent.bottomAnchor),
            row.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            row.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            row.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
        return card
    }

    @objc private func revampDismissNudge() {
        UIView.animate(withDuration: 0.25) { self.revampNudgeCard?.isHidden = true }
    }

    private func updateRewardHint(steps: Int) {
        let text: String
        if steps < 5000 {
            text = "Keep going! You're \(5000 - steps) steps from your 5K reward."
        } else if steps < 10000 {
            text = "Great! You're \(10000 - steps) steps from your 10K reward."
        } else {
            text = "🎉 You've smashed your 10K goal today!"
        }
        revampRewardHintLabel?.text = text
    }

    private func revampCard() -> UIView {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .white
        v.layer.cornerRadius = 16
        v.layer.shadowColor = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.08
        v.layer.shadowRadius = 5
        v.layer.shadowOffset = CGSize(width: 0, height: 2)
        return v
    }

    private func revampIconButton(system: String, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: system), for: .normal)
        b.tintColor = revampRed
        b.translatesAutoresizingMaskIntoConstraints = false
        b.widthAnchor.constraint(equalToConstant: 30).isActive = true
        b.heightAnchor.constraint(equalToConstant: 30).isActive = true
        b.setContentHuggingPriority(.required, for: .horizontal)
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    @objc func revampStepsUpdated(_ note: Notification) {
        let steps = (note.userInfo?["steps"] as? Int) ?? initialStepCount
        refreshRevampSteps(steps)
    }

    /// Single, deduped entry point for pushing a step count into the revamp hero.
    /// Called from every step source (the CoreMotion notification and the
    /// HealthKit/Fitbit display funnel `showStepsCount`); skips no-op repeats so
    /// the activity rings don't re-animate on identical values.
    func refreshRevampSteps(_ steps: Int) {
        // Cheap text refresh always runs (so real distance/calories surface even when the
        // step count itself hasn't changed); the expensive ring re-animation stays guarded.
        revampBigStepLabel?.text = "\(steps)"
        // Milestone colour (Android parity): brand red until the 10k goal, green once reached.
        revampBigStepLabel?.textColor = steps >= 10000 ? UIColor(red: 0, green: 0.5, blue: 0, alpha: 1) : revampRed
        updateRevampGoal(steps: steps)
        // Keep the server AFIT estimate fresh as steps accumulate (Android re-fetches on updates);
        // throttled by step delta so we don't hammer the endpoint on every 2s pedometer tick.
        if lastEstRewardSteps < 0 || abs(steps - lastEstRewardSteps) >= 250 {
            lastEstRewardSteps = steps
            fetchEstimatedReward(steps: steps)
        }
        guard steps != lastRevampSteps else { return }
        lastRevampSteps = steps
        updateAura(steps: steps)
    }

    /// Effective distance (metres) + calories for display: the active source's real values
    /// when available, otherwise a step-derived estimate. The booleans say which is which.
    /// Fitbit's real values live in the view model (fetched on sync); Device/Health set `live*`.
    private func effectiveMetrics(steps: Int) -> (dist: Double, cal: Double, distReal: Bool, calReal: Bool) {
        let dMeters = (viewModel.trackingMode == .fitbit) ? viewModel.lastFitbitDistanceMeters : liveDistanceMeters
        let cVal = (viewModel.trackingMode == .fitbit) ? viewModel.lastFitbitCalories : liveCalories
        let distReal = dMeters >= 0
        let calReal = cVal >= 0
        return (distReal ? dMeters : Double(steps) * 0.762,
                calReal ? cVal : Double(steps) * 0.04,
                distReal, calReal)
    }

    /// Pulls Fitbit's own distance + calories (real values) after a sync and refreshes the rings
    /// once, if we're currently showing Fitbit.
    private func fetchFitbitMetrics(forDate date: Date) {
        let isMetric = Route.isMetric
        let group = DispatchGroup()

        // Distance: pin the unit via Accept-Language to the app's own metric/US setting, so the
        // fetched unit and the displayed unit can't disagree, then convert to metres.
        group.enter()
        _ = StepStat.fetchTodaysActivitySeries(
            resource: "activities/tracker/distance",
            responseKey: "activities-tracker-distance",
            acceptLanguage: isMetric ? nil : "en_US",
            forDate: date) { [weak self] value in
            if let value, value >= 0 {
                self?.viewModel.lastFitbitDistanceMeters = value * (isMetric ? 1000.0 : 1609.344)
            } else {
                self?.viewModel.lastFitbitDistanceMeters = -1
            }
            group.leave()
        }

        // Calories: activity-only kcal — comparable to Health's active energy and the step
        // estimate. (tracker/calories returns BMR+activity total, which would peg the ring full
        // and diverge ~5–6× from Health mode.)
        group.enter()
        _ = StepStat.fetchTodaysActivitySeries(
            resource: "activities/activityCalories",
            responseKey: "activities-activityCalories",
            forDate: date) { [weak self] value in
            if let value, value >= 0 {
                self?.viewModel.lastFitbitCalories = value
            } else {
                self?.viewModel.lastFitbitCalories = -1
            }
            group.leave()
        }

        // Single refresh once both land — avoids a double ring animation and the brief
        // estimate→real flash from refreshing per-metric.
        group.notify(queue: .main) { [weak self] in
            self?.refreshFitbitRingsIfActive()
        }
    }

    private func refreshFitbitRingsIfActive() {
        guard viewModel.trackingMode == .fitbit else { return }
        lastRevampSteps = -1   // force the rings to re-animate with the new real values
        refreshRevampSteps(viewModel.lastFitbitSteps)
    }

    func updateRevampGoal(steps: Int) {
        // Distance + calories under the count (Android PR 82 parity). Real source data shows
        // as-is; step-derived estimates carry an "≈". Distance honours the user's measurement
        // system (km / mi) via the shared Route formatter.
        let m = effectiveMetrics(steps: steps)
        let distStr = (m.distReal ? "" : "≈") + Route.distanceString(m.dist)
        let calStr = (m.calReal ? "" : "≈") + "\(Int(m.cal.rounded())) kcal"
        // Leading LTR mark keeps the emoji/number order stable in RTL locales (Android textDirection=ltr).
        revampPctLabel?.text = "\u{200E}📏 \(distStr)   🔥 \(calStr)"
    }

    // MARK: Aura + streak (Android CompanionUtil / streak parity)

    func updateAura(steps: Int) {
        let streak = computeStreak()
        let level = CompanionUtil.levelFromStreak(streak)
        let hour = Calendar.current.component(.hour, from: Date())
        let wilting = CompanionUtil.isWilting(streak: streak, todaySteps: steps, hourOfDay: hour)
        let m = effectiveMetrics(steps: steps)
        auraView?.setActivityRings(steps: CGFloat(steps) / 10000.0,
                                   distance: CGFloat(m.dist / 1000.0) / 8.0,
                                   calories: CGFloat(m.cal) / 500.0,
                                   level: level, wilting: wilting)
        updateStreakStrip(streak: streak)
        updateRewardHint(steps: steps)
        updateHeatmap()
    }

    private func yyyymmdd(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd"
        return f.string(from: date)
    }

    /// Per-day steps: today = live count; past days = local Realm history. -1 if none (matches Android).
    private func stepsForDate(_ date: Date) -> Int {
        let key = yyyymmdd(date)
        if key == yyyymmdd(Date()) { return initialStepCount }
        for activity in viewModel.history where yyyymmdd(activity.date) == key {
            return Int(activity.steps)
        }
        return -1
    }

    /// Consecutive days ending at today with >= 5000 steps (today grace-skipped if not yet met).
    private func computeStreak() -> Int {
        let todaySteps = stepsForDate(Date())
        let startDaysBack = todaySteps >= CompanionUtil.ACTIVE_THRESHOLD ? 0 : 1
        var streak = 0
        var daysBack = startDaysBack
        while daysBack <= 30 {
            guard let day = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date()) else { break }
            if stepsForDate(day) >= CompanionUtil.ACTIVE_THRESHOLD { streak += 1 } else { break }
            daysBack += 1
        }
        return streak
    }

    private func updateStreakStrip(streak: Int) {
        streakCountLabel?.text = streak == 0 ? "No streak yet" : "\(streak) day streak"
        let abbr = ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"]
        let green = UIColor(red: 0x4C / 255.0, green: 0xAF / 255.0, blue: 0x50 / 255.0, alpha: 1)
        let cal = Calendar.current
        for i in 0..<min(7, streakDayCircles.count) {
            guard let day = cal.date(byAdding: .day, value: -(6 - i), to: Date()) else { continue }
            let active = stepsForDate(day) >= CompanionUtil.ACTIVE_THRESHOLD
            let circle = streakDayCircles[i]
            let check = circle.subviews.compactMap { $0 as? UILabel }.first
            if active {
                circle.backgroundColor = green
                circle.layer.borderColor = green.cgColor
                check?.isHidden = false
            } else {
                circle.backgroundColor = .clear
                circle.layer.borderColor = UIColor(white: 0.8, alpha: 1).cgColor
                check?.isHidden = true
            }
            let wd = cal.component(.weekday, from: day) // 1=Sun..7=Sat
            streakDayLabels[i].text = abbr[wd - 1]
        }
    }

    // MARK: - Tracking mode (device / Apple Health / Fitbit)

    /// Bottom-right swap button: cycle device -> Apple Health -> Fitbit -> device.
    @objc func revampCycleTrackingMode() {
        let mode = viewModel.cycleTrackingMode()
        // Clear the previous source's distance/calories so we don't show stale real data
        // before the new source reports (each source repopulates these on its next update).
        liveDistanceMeters = -1
        liveCalories = -1
        applyTrackingModeUI()
        switch mode {
        case .device:
            queryAndUpdateDatafromMidnight()
        case .health:
            if viewModel.lastHealthSteps > 0 { showStepsCount(count: viewModel.lastHealthSteps) }
            syncHealthSteps()
        case .fitbit:
            showStepsCount(count: viewModel.lastFitbitSteps)
        }
        showToast(message: "Tracking source: \(modeName(mode))")
    }

    /// Reflects the active mode: cloud + source logo show only for Health/Fitbit.
    func applyTrackingModeUI() {
        let mode = viewModel.trackingMode
        revampCloudBtn?.isHidden = (mode == .device)
        switch mode {
        case .device:
            revampSourceLogoBtn?.isHidden = true
        case .health:
            revampSourceLogoBtn?.isHidden = false
            revampSourceLogoBtn?.setImage(UIImage(named: "apple_health_logo")?.withRenderingMode(.alwaysOriginal), for: .normal)
        case .fitbit:
            revampSourceLogoBtn?.isHidden = false
            revampSourceLogoBtn?.setImage(UIImage(named: "fitbit_logo")?.withRenderingMode(.alwaysOriginal), for: .normal)
        }
    }

    /// Top-left source logo tap: show when the active source last synced.
    @objc func revampSourceLogoTapped() {
        switch viewModel.trackingMode {
        case .fitbit:
            let d = viewModel.lastSyncFitbitDate ?? ""
            showToast(message: d.isEmpty ? "Fitbit — not synced yet" : "Last Fitbit sync: \(d)")
        case .health:
            let d = viewModel.lastSyncHealthDate ?? ""
            showToast(message: d.isEmpty ? "Apple Health — not synced yet" : "Last Health sync: \(d)")
        case .device:
            break
        }
    }

    private func modeName(_ m: TrackingMode) -> String {
        switch m {
        case .device: return "Device"
        case .health: return "Apple Health"
        case .fitbit: return "Fitbit"
        }
    }

    @objc func revampShareTapped() {
        let text = "I've done \(initialStepCount) steps today on Actifit! 🏃"
        let vc = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = view
        present(vc, animated: true)
    }

    @objc func openProfileFromRevamp() {
        openNativeProfile()
    }
}



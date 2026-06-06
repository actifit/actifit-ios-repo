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
  var activityDateToSave = Date()
  private var activityUpdateTimer: Timer?
  private var isQueryingActivity = false

  let serialQueue = DispatchQueue(label: "com.actifit.serialQueue")
  override func viewDidLoad() {
    super.viewDidLoad()
    setUI()
    setAccessibilityIdentifiers()
    checkForUpdates()

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
    showSyncOptionsAlert {
      self.authenticationController = AuthenticationController(delegate: self)
      self.authenticationController?.login(fromParentViewController: self)
    } watchHandler: {
      self.viewModel.switchSensor(isThirdParty: false)
      UserDefaults.standard.lastSynchronizedSteps = self.initialStepCount
      self.queryAndUpdateDatafromMidnight(isFromThirdParty: true)
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
    if let username = viewModel.userName {
        let url = URL(string: "https://actifit.io/" + username)
        UIApplication.shared.open(url!)
    }
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
        self.giftButton.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
      }, completion: nil)
    }
  }


  func stopPrizeButtonScaling() {
    giftButton.layer.removeAllAnimations()
    giftButton.transform = CGAffineTransform.identity
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
      openPopup(title: NSLocalizedString("virtual_gadgets", comment: ""), description: NSLocalizedString("virtual_gadgets_details", comment: ""), cancelTitle: NSLocalizedString("close_upper", comment: ""), actionTitle: NSLocalizedString("market", comment: ""), size: .medium)
      // This method is called when a tap/select event occurs
      // You can perform actions related to the tap/select here
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
      self?.bannerImages = bannerItems
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
      navigationController?.pushViewController(WalletVC.instantiateWithStoryboard(appStoryboard: .SB_Main), animated: true)
    } else {
      showToast(message: "Please login first")
    }
  }

  @IBAction func marketPlaceBtnTapped(_ sender: Any) {
    openPopup(title: NSLocalizedString("virtual_gadgets", comment: ""), description: NSLocalizedString("virtual_gadgets_details", comment: ""), cancelTitle: NSLocalizedString("close_upper", comment: ""), actionTitle: NSLocalizedString("market", comment: ""), size: .medium)
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
    xAxis.labelCount = 96
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
          if isFromThirdParty {
              self.viewModel.updateDateSync()
              self.showStepsCount(count: self.viewModel.lastFitbitSteps)
          } else {
              UserDefaults.standard.lastSynchronizedSteps = totalSteps
              self.showStepsCount(count: totalSteps)
          }
          if self.initialStepCount != totalSteps {
            self.initialStepCount =  totalSteps
            self.saveCurrentStepsCounts(steps: totalSteps, midnightStartDate: AppDelegate.todayStartDate())
            NotificationCenter.default.post(name: Notification.Name.init(StepsUpdatedNotification), object: nil, userInfo: ["steps" : totalSteps])
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
        xAxis.labelCount = 96
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
    let _ = StepStat.fetchTodaysStepStat(forDate: self.activityDateToSave) { [weak self] stepStat, error in
      guard let self = self else { return }
      let steps = stepStat?.steps ?? 0
      self.initialStepCount = Int(steps)
      self.showStepsCount(count:  self.initialStepCount)
      viewModel.switchSensor(isThirdParty: true)
      self.viewModel.switchToFitbitSensor(steps: Int(stepStat?.steps ?? 0))

    }
  }
}



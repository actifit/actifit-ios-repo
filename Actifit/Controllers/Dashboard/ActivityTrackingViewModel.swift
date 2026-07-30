//
//  ActivityTrackingViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 21/07/2023.
//

import Foundation
import Combine
import UIKit
import GoogleMobileAds
import RealmSwift
import Charts

/// Step-tracking source, cycled by the dashboard's swap button.
enum TrackingMode: Int {
    case device = 0   // CoreMotion (default, auto)
    case health = 1   // Apple Watch / Apple Health (manual sync)
    case fitbit = 2   // Fitbit (manual sync)
}

class ActivityTrackingViewModel {
  var stepsArray = [Double]()
  var appDelegate = UIApplication.shared.delegate as? AFAppDelegate
  let networkManager =  HTTPClient()
  private let cancellables = Set<AnyCancellable>()
  private let loaderSubject = PassthroughSubject<Bool, Never>()
  var blurtObject: Blurt?
  var afitTokenObject: AfitTokenModel?
  var dailyTips: [DailyTipsModel] = []
  var activeGadgetUserData: [ActiveGadgeByUser] = []
  var products: [Product] = []
  var gadgetsList: [GadgetImageObject] = []
  var statusModel: VotingStatusModel?
  var surveysArray: [SurveyModel] = []

  private let pollSurveySubject = PassthroughSubject<SurveyModel, Never>()
  var pollSurveryPublisher: AnyPublisher<SurveyModel, Never> {
    return pollSurveySubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  var loaderVisibilityPublisher: AnyPublisher<Bool, Never> {
    return loaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let percentageSubscriber = PassthroughSubject<String, Never> ()
  var percentagePublisher: AnyPublisher<String, Never> {
    return percentageSubscriber.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let bannerImagesSubject = PassthroughSubject<[BannerImageModel], Never> ()
  var bannerImagesPublisher: AnyPublisher<[BannerImageModel], Never> {
    return bannerImagesSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let votingStatus = PassthroughSubject<VotingStatusModel, Never>()
  var votingStatusPublisher: AnyPublisher<VotingStatusModel, Never> {
    return votingStatus.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let afitTokenSubject = PassthroughSubject<AfitTokenModel, Never>()
  var afitTokenPublisher: AnyPublisher<AfitTokenModel,Never> {
    return afitTokenSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let blurtSubject = PassthroughSubject<Bool, Never>()
  var blurtPublisher: AnyPublisher<Bool, Never> {
    return blurtSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  private let dailyTipSubscriber = PassthroughSubject<[DailyTipsModel], Never>()
  var dailyTipPublisher: AnyPublisher<[DailyTipsModel], Never> {
    return dailyTipSubscriber.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }
  private let gadgetSubscriber = PassthroughSubject<[GadgetImageObject], Never>()
  var gadgetPublisher: AnyPublisher<[GadgetImageObject], Never> {
    return gadgetSubscriber.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let chatBlinkingTriggerSubject = PassthroughSubject<Bool, Never> ()
  var chatBlinkingtriggerPublisher: AnyPublisher<Bool, Never> {
    return chatBlinkingTriggerSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let rcPercentageSubject = PassthroughSubject<String, Never> ()
  var rcPercentagePublisher: AnyPublisher<String, Never> {
    return rcPercentageSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }

  private let userProfileImageSubject = PassthroughSubject<UIImage?, Never> ()
  var userProfileImagePublisher: AnyPublisher<UIImage?, Never> {
    return userProfileImageSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
  }


  init() {
    if  UserDefaults.standard.getLatestAdDate != Date().currentDay() {
            initializePrizesValues()
    }
    // Show the loader immediately, not after a 1s delay. A *delayed* send(true) can fire
    // AFTER the chain's send(false) calls on a fast/cached load, re-showing the HUD over
    // already-loaded content until the safety timeout below. (Same fix as WavesPopupViewModel.)
    self.loaderSubject.send(true)

        Task {
            await getNewsBannerAPI()
            await getVotingStatusAPI()
            await getAfitTokens()
            await getAccountData()
            await getActiveGadgetsByUser()
            await getNotificationCountAPI()
            await getPRPercentage()
            fetchUserImage()
            if UserDefaults.standard.showTips {
                await self.getDailyTips()
            } else {
                await callSurveyAPI()
            }
            // Ensure the loader is down once the chain finishes (belt-and-suspenders).
            self.loaderSubject.send(false)
        }

        // Safety net: the data chain above awaits several requests with no per-request
        // timeout, so a single hanging call would otherwise trap the user behind the
        // "Loading" HUD forever. Never keep it up longer than this bound.
        DispatchQueue.main.asyncAfter(deadline: .now() + 15) {
            self.loaderSubject.send(false)
        }
    }

  var historyFifteenMinute: [ActivityFifteenMinutesInterval] {
        return ActivityFifteenMinutesInterval.all()
    }
  var history: [Activity] {
      print( Activity.allWithoutCountZero())
      return Activity.allWithoutCountZero()
  }

  var shouldShowUserHeaderView: Bool {
      return isLoggedIn
  }


  func checkAndPostNotification(count: Int) {
    let todayNewDate = Date().dateString(withFormat: "yyyy-MM-dd")
    let userDefaults = UserDefaults.standard

    if let todaySavedDate = userDefaults.value(forKey: "DateForToday") as? String, todayNewDate == todaySavedDate {
      if !userDefaults.bool(forKey: "5KActivityReached") && count >= 5000 {
        userDefaults.set(true, forKey: "5KActivityReached")
        appDelegate?.scheduleNotification(steps: 5)
      } else if !userDefaults.bool(forKey: "10KActivityReached") && count >= 10000 {
        userDefaults.set(true, forKey: "10KActivityReached")
        appDelegate?.scheduleNotification(steps: 10)
      }
    } else {
      resetDailyActivityData(todayNewDate)
    }
  }

  private func resetDailyActivityData(_ todayNewDate: String) {
    let userDefaults = UserDefaults.standard
    userDefaults.set(todayNewDate, forKey: "DateForToday")
    userDefaults.set(false, forKey: "5KActivityReached")
    userDefaults.set(false, forKey: "10KActivityReached")
  }

  var canSeeAd: Bool {
    return isLoggedIn && ((UserDefaults.standard.getLatestAdDate != Date().currentDay()) || UserDefaults.standard.getLatestPrizeAmount == "")
  }


    var shouldScalePrizeButton: Bool {
        return UserDefaults.standard.getLatestAdDate != Date().currentDay() && isLoggedIn
    }

    var isFitSystemSelected: Bool {
        return UserDefaults.standard.bool(forKey: "isFitSystemSelected") == true
    }

    func initializePrizesValues() {
        UserDefaults.standard.latestPrizeType = ""
        UserDefaults.standard.getLatestPrizeAmount = ""
        UserDefaults.standard.freeReward = ""
        UserDefaults.standard.fiveKReward = ""
        UserDefaults.standard.sevenKReward = ""
        UserDefaults.standard.tenKReward = ""
    }

    func saveCurrentStepsCounts(steps : Int, midnightStartDate : Date) {
      let allActivities = Activity.all()
      if let activity = allActivities.first(where: {$0.date == midnightStartDate}){
        // activity.update(date: AppDelegate.todayStartDate(), steps:steps)
        let activtyInfo = [ActivityKeys.id : activity.id, ActivityKeys.date : activity.date, ActivityKeys.steps : steps] as [String : Any]
        activity.upadteWith(info: activtyInfo)
      } else {
        //allActivities.count + 1 //1122
        let activtyInfo = [ActivityKeys.id : allActivities.count + 1, ActivityKeys.date : midnightStartDate, ActivityKeys.steps : steps] as [String : Any]
        let activity = Activity()
        activity.upadteWith(info: activtyInfo)

      }
    }


  func switchToFitbitSensor(steps: Int) {
    UserDefaults.standard.isThirdPartySensor = true
    updateDateSync()
    UserDefaults.standard.lastSynchronizedSteps =  Int(steps)
  }

  func updateDateSync() {
    UserDefaults.standard.lastDateStepSynchronization = Date().dateTimeString()
  }

  var isThirdPartySensor: Bool {
    if let isThirdPartySensor = UserDefaults.standard.isThirdPartySensor {
        return isThirdPartySensor
    }
    return false
  }

  var lastFitbitSteps: Int {
    return UserDefaults.standard.lastSynchronizedSteps
  }

  /// Real Fitbit distance (metres) / calories (kcal) from the last sync; -1 = not synced yet,
  /// so the dashboard falls back to a step-derived estimate.
  var lastFitbitDistanceMeters: Double {
    get { (UserDefaults.standard.object(forKey: "lastFitbitDistanceMeters") as? Double) ?? -1 }
    set { UserDefaults.standard.set(newValue, forKey: "lastFitbitDistanceMeters") }
  }
  var lastFitbitCalories: Double {
    get { (UserDefaults.standard.object(forKey: "lastFitbitCalories") as? Double) ?? -1 }
    set { UserDefaults.standard.set(newValue, forKey: "lastFitbitCalories") }
  }

  func switchSensor(isThirdParty: Bool) {
    UserDefaults.standard.isThirdPartySensor = isThirdParty
  }

  // MARK: - Tracking mode (3-way cycle: device -> Apple Health/Watch -> Fitbit)

  private static let trackingModeKey = "actifitTrackingMode"

  var trackingMode: TrackingMode {
    get {
      // Migrate from the legacy boolean the first time.
      if UserDefaults.standard.object(forKey: Self.trackingModeKey) == nil {
        return (UserDefaults.standard.isThirdPartySensor == true) ? .fitbit : .device
      }
      return TrackingMode(rawValue: UserDefaults.standard.integer(forKey: Self.trackingModeKey)) ?? .device
    }
    set {
      UserDefaults.standard.set(newValue.rawValue, forKey: Self.trackingModeKey)
      // Keep the legacy flag consistent — only Fitbit is a "third-party" sensor.
      UserDefaults.standard.isThirdPartySensor = (newValue == .fitbit)
    }
  }

  @discardableResult
  func cycleTrackingMode() -> TrackingMode {
    let next = TrackingMode(rawValue: (trackingMode.rawValue + 1) % 3) ?? .device
    trackingMode = next
    return next
  }

  var lastHealthSteps: Int {
    get { UserDefaults.standard.integer(forKey: "lastHealthSteps") }
    set { UserDefaults.standard.set(newValue, forKey: "lastHealthSteps") }
  }

  var lastSyncHealthDate: String? {
    get { UserDefaults.standard.string(forKey: "lastHealthSyncDate") }
    set { UserDefaults.standard.set(newValue, forKey: "lastHealthSyncDate") }
  }

  func updateHealthSyncDate() {
    UserDefaults.standard.set(Date().dateTimeString(), forKey: "lastHealthSyncDate")
  }

  func clearFitBitSteps() {
    let todaysDate = Date().dateTimeString()
    if let lastSyncDate = UserDefaults.standard.lastDateStepSynchronization, let difference =  
        Date().dateDifferenceByNumberOfDates(startDate: lastSyncDate, endDate: todaysDate, dateFormat: "yyyy-MM-dd HH:mm") {
      if difference != 0 {
        UserDefaults.standard.lastDateStepSynchronization = nil
        UserDefaults.standard.lastSynchronizedSteps = 0
        lastFitbitDistanceMeters = -1
        lastFitbitCalories = -1
      }
    }

  }

  private func callSurveyAPI() async {
     await self.getSurveyPolls()
  }

  private func checkNotificationDate(notification: ReadChatNotification?, statIndex: Int, newNotificationCount: Int) {
    guard  UserDefaults.standard.lastChatDateDisplay != "" else {
      chatBlinkingTriggerSubject.send(true)
      return
    }
    _ = UserDefaults.standard.lastChatDateDisplay

    if let dateDifferences =  Date().dateDifferenceByNumberOfDates(startDate: Date().getTodaysDateYearAndMonthAndDay(), endDate: UserDefaults.standard.lastChatDateDisplay) {
      if dateDifferences > 6 {
        print(dateDifferences)
        chatBlinkingTriggerSubject.send(true)
        return

      }
    }

    _ = Date.convertServerDateString(notification?.date ?? "") ?? ""
    if let dateDifferenceWithServer = Date().dateDifferenceByNumberOfDates(startDate: Date().getTodaysDateYearAndMonthAndDay(), endDate: UserDefaults.standard.lastChatDateDisplay) {
      if dateDifferenceWithServer == statIndex {
        if UserDefaults.standard.lastNotificationCount == newNotificationCount {
          return
        } else {
          chatBlinkingTriggerSubject.send(true)
          UserDefaults.standard.lastNotificationCount = newNotificationCount
        }
      } else if statIndex < dateDifferenceWithServer {
        chatBlinkingTriggerSubject.send(true)
        UserDefaults.standard.lastNotificationCount = newNotificationCount
      } else {
        return
      }
    }
  }
  //DONE
  func getLastChatNotificationRead(statIndex: Int, newNotificationCount: Int) async {
    guard let userName = User.current()?.steemit_username  else { return }
    API().getLastNotificationRead(userName: userName) { info, statusCode in
      if let response = info as? String {
        let data = response.utf8Data()
        do {
          if var jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any], jsonArray != nil {
            jsonArray?.removeFirst()
            if let jsonData = try? JSONSerialization.data(withJSONObject: jsonArray, options: []),
               let decodedArray = try? JSONDecoder().decode([[ReadChatNotification]].self, from: jsonData) {
              if decodedArray.isEmpty {
                self.chatBlinkingTriggerSubject.send(true)
              } else {
                print(decodedArray)
                self.checkNotificationDate(notification: decodedArray.flatMap{$0}.first, statIndex: statIndex, newNotificationCount: newNotificationCount)
              }
            }
          }
        }
      }
    } failure: { error in
      self.loaderSubject.send(false)
      print(error.localizedDescription)
    }
  }

  private func getNotificationCountAPI() async {
    API().getNotificationStats { info, statusCode in
      if let response = info as? String {
        let data = response.utf8Data()
        do {
          if var jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
            jsonArray?.removeFirst()
            if var list = jsonArray?.first as? [Any] {
              if list.count > 1 {
                list.removeLast()
              }
              if let jsonData = try? JSONSerialization.data(withJSONObject: list.first, options: []),

                  let decodedArray = try? JSONDecoder().decode([ChatNotificationCount].self, from: jsonData) {
                let reversedNotifications = Array(decodedArray.reversed())
                var notificationCount = 0
                for i in 0..<reversedNotifications.count {
                  if reversedNotifications[i].hiveCommunity != nil && (reversedNotifications[i].hiveCommunity ?? 0) > 0 {
                    // UserDefaults.standard.lastNotificationCount = reversedNotifications[i].hiveCommunity!
                    Task {
                      await self.getLastChatNotificationRead(statIndex: i, newNotificationCount: reversedNotifications[i].hiveCommunity!)
                    }
                    return
                  }
                }
              }
            }
          }
        }
      }
    } failure: { error in
      self.loaderSubject.send(false)
      print(error.localizedDescription)
    }
  }


  func getSurveyPolls() async {
    guard  User.current() != nil else {return }
    let surveys = await networkManager.getSurveys()
    self.loaderSubject.send(false)
    switch surveys {
    case .success(let success):
      self.surveysArray = success
      self.surveysArray.reverse()
      await self.checkValidSurveys(surveys: self.surveysArray)
    case .failure(let failure):
      print(failure.localizedDescription)
    }
  }


  //DONE
  func checkValidSurveys(surveys: [SurveyModel]) async {
    guard let userName = User.current()?.steemit_username else {
      return
    }

    for survey in surveys where survey.isValidSurvey() {
      do {
        let surveyStatus = try await networkManager.getSurveyStatus(username: userName, surveyId: survey.id ?? "")
        loaderSubject.send(false)
        switch surveyStatus {
        case .success(let success):
          if success.voted == false {
            self.pollSurveySubject.send(survey)
          }
        case .failure(let failure):
          print(failure.localizedDescription)
        }
      }
    }
  }


  //
  //    func processSurvey(_ survey: SurveyModel, completion: @escaping (Bool) -> Void) async {
  //      let surveyStatus = try await networkManager.getSurveyStatus(username: userName, surveyId: survey.id ?? "")
  ////      defer {
  ////        dispatchGroup.leave()
  ////        currentIndex += 1 // Move to the next survey regardless of the result
  ////        Task {
  ////          await processNextSurvey()
  ////        }// Process the next survey
  ////      }
  //      switch surveyStatus {
  //      case .success(let success):
  //        if success.voted == false {
  //          self.pollSurveySubject.send(survey)
  //        }
  //      case .failure(let failure):
  //        dispatchGroup.leave()
  //        self.loaderSubject.send(false)
  //      }
  //      API().checkSurveyStatus(userName: userName, surveyId: survey.id ?? "") { info, statusCode in
  //        defer {
  //          dispatchGroup.leave()
  //          currentIndex += 1 // Move to the next survey regardless of the result
  //          processNextSurvey() // Process the next survey
  //        }
  //        if let response = info as? String {
  //          let data = response.utf8Data()
  //          let decoder = JSONDecoder()
  //          do {
  //            let voteStatus = try decoder.decode(SurveyStatusModel.self, from: data)
  //            if voteStatus.voted == false {
  //              self.pollSurveySubject.send(survey)
  //              completion(false)
  //
  //            }
  //          } catch {
  //            // Handle decoding errors
  //          }
  //        } else {
  //          // Handle API response errors
  //        }
  //
  //      } failure: { error in
  //        dispatchGroup.leave()
  //        self.loaderSubject.send(false)
  //        print(error.localizedDescription)
  //      }
  // }

  //    func processNextSurvey() {
  //      if currentIndex < surveys.count {
  //        let survey = surveys[currentIndex]
  //        if survey.isValidSurvey() {
  //          dispatchGroup.enter()
  //          try await processSurvey(survey) { shouldContinue in
  //            if shouldContinue {
  //              // Move to the next survey if the current one is not valid
  //              processNextSurvey() // Process the next survey
  //            }
  //          }
  //        } else {
  //          currentIndex += 1 // Move to the next survey if the current one is not valid
  //          processNextSurvey() // Process the next survey
  //        }
  //      }
  //    }

  // Start processing the first survey
  //  processNextSurvey()

  //    dispatchGroup.notify(queue: .main) {
  //      print("DONE")
  //    }
  //}

  //DONE
  func getNewsBannerAPI() async {
    let banners = try await networkManager.getBanners()
    self.loaderSubject.send(false)
    switch banners {
    case .success(let success):
      self.bannerImagesSubject.send(success)
    case .failure(let failure):
      print(failure.localizedDescription)
    }
  }

  func setGiftButtonUnicodeImage() -> String {
    let unicodeValue = 127873
    let unicodeScalar = Unicode.Scalar(unicodeValue)!
    return String(unicodeScalar)
  }
  //DONE
  private func getVotingStatusAPI() async {

    let votingStatus = try await networkManager.getVotingStatus()
    self.loaderSubject.send(false)
    switch votingStatus {
    case .success(let success):
      self.statusModel = success
      self.votingStatus.send(success)
    case .failure(let failure):
      print(failure.localizedDescription)
      //TODO: handle error messages
    }
  }

  //DONE
  private func getPRPercentage() async {
    if isLoggedIn {
      let rcpPercentage = await networkManager.getRCPPercentage()
      self.loaderSubject.send(false)
      switch rcpPercentage {
      case .success(let percentageModel):
        self.rcPercentageSubject.send(percentageModel.currentRCPercent ?? "")
        let percentageModel = percentageModel
      case .failure(let failure):
        self.loaderSubject.send(false)
      }
    }
  }

  private func fetchUserImage() {
      var  strImageUrl  = ""
      if let strUserName = userName , strUserName != "" {
        let finalUserName = strUserName.replacingOccurrences(of: "@", with: "")
        strImageUrl = "https://images.hive.blog/u/" + finalUserName + "/avatar"
        guard let imageFinalURL = URL(string: strImageUrl) else { return }
        URLSession.shared.dataTask( with: imageFinalURL, completionHandler: {
          (data, response, error) -> Void in
          DispatchQueue.main.async {
            if let data = data {
              self.userProfileImageSubject.send(UIImage(data: data))
            }
            else{
              self.userProfileImageSubject.send(nil)
            }
          }
        }).resume()
      }
  }

  //DONE
  private func getAccountData() async {
    guard let username = User.current()?.steemit_username else { return }
    let accountData = await networkManager.getAccountData(username:username)
    self.loaderSubject.send(false)
    switch accountData {
    case .success(let blurtResponse):
      self.blurtObject = blurtResponse.blurt
      self.blurtSubject.send((blurtResponse.blurt.id != nil && (blurtResponse.blurt.balanceWithoutNaming ?? 0) > 5) ? false : true)
    case .failure(let failure):
      self.blurtSubject.send(true)
      print(failure)
    }
  }

  //DONE
  private func getAfitTokens() async {
    guard let username = User.current()?.steemit_username else { return }
    let afitBalance = await networkManager.getAfitBalance(username: username)
    self.loaderSubject.send(false)
    switch afitBalance {
    case .success(let success):
      self.afitTokenObject = success
      self.afitTokenSubject.send(success)
    case .failure(let failure):
      print(failure.localizedDescription)

    }
  }

  func formatNumberForAfitBalance(_ number: Double) -> String {
      let numberFormatter = NumberFormatter()
      numberFormatter.numberStyle = .decimal
      numberFormatter.maximumFractionDigits = 3 // Set the maximum fraction digits as needed

      if let formattedNumber = numberFormatter.string(from: NSNumber(value: number)) {
          return formattedNumber
      } else {
          return String(number) // Fallback to the original number if formatting fails
      }
  }


  //DONE
  private func getDailyTips() async {
    let dailyTips = try await networkManager.getDailyTips()
    self.loaderSubject.send(false)
    switch dailyTips {
    case .success(let success):
      self.dailyTips = success
      self.pickTip()
    case .failure(let failure):
      print(failure.localizedDescription)
    }
  }

  private func pickTip() {
    dailyTipSubscriber.send(dailyTips)
  }

  //DONE
  private func getProducts() async {
    let products = try await networkManager.getProducts()
    switch products {
    case .success(let success):
      self.products = success
      DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
        self.getGatgetsURLS()
      })

    case .failure(let failure):
      self.loaderSubject.send(false)
    }
  }

  private func getGatgetsURLS() {
    activeGadgetUserData.forEach { element in
      if let product =  products.filter({$0.id == element.gadget}).first {
        gadgetsList.append(GadgetImageObject(imageURL: "https://actifit.io/img/gadgets/\(product.image ?? "")", gadgetsLevel: element.gadgetLevel ?? 0))
      }
    }
    if !gadgetsList.isEmpty {
      Task {
        await loadImage()
      }
    } else {
      gadgetSubscriber.send(gadgetsList)
    }
  }


  func loadImage() async {
    for element in gadgetsList {
      do {
        let (data, _) = try await URLSession.shared.data(from: URL(string: element.imageURL)!)
        if let image = UIImage(data: data) {
          element.setImage(receivedImage: image)
        }
      } catch {
        self.loaderSubject.send(false)
        print("Error fetching image: \(error)")
      }
    }
    gadgetSubscriber.send(gadgetsList)
  }

  var isLoggedIn: Bool {
    return User.current() != nil
  }

  var userName: String? {
    return User.current()?.steemit_username
  }

  var user: User? {
    if let user = User.current() {
      return user
    }
    return nil
  }

  var canPost: Bool {
    if isLoggedIn {
      var canPost = false
      let calender = Calendar.autoupdatingCurrent
      return !(calender.isDateInToday(user!.last_post_date))
    } else {
      return false
    }
  }

  var lastSyncFitbitDate: String? {
    return UserDefaults.standard.lastDateStepSynchronization
  }

//  private func checkIfCanPost() -> Bool {
//    var canPost = false
//    if viewModel.isLoggedIn {
//      let calender = Calendar.autoupdatingCurrent
//      canPost = !(calender.isDateInToday(viewModel.user!.last_post_date))
//    }
//    return canPost
//  }
  //DONE
  private func getActiveGadgetsByUser() async {
    guard let username = User.current()?.steemit_username else { return }
    let activeGadgets = await networkManager.getActiveGadgetsForUser(username: username)
    self.loaderSubject.send(false)
    switch activeGadgets {
    case .success(let success):
      self.activeGadgetUserData = success.own
      Task {
        await self.getProducts()
      }
    case .failure(let failure):
      print(failure.localizedDescription)
    }
  }

  func getUserProfilePicture() {
    
  }
}


class GadgetImageObject {
  let imageURL: String
  let gadgetsLevel: Int
  var image: UIImage?
  init(imageURL: String, gadgetsLevel: Int) {
    self.imageURL = imageURL
    self.gadgetsLevel = gadgetsLevel
  }

  func setImage(receivedImage: UIImage) {
    image = receivedImage
  }
}

struct TimeSlot {
  var hour: Int
  var minute: Int
}

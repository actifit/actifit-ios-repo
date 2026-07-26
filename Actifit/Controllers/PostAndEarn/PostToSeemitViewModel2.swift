//
//  PostToSeemitViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 15/07/2024.
//

import Foundation
import UIKit
import SwiftUI
import CryptoKit
import HealthKit
enum PostState {
    case none
    case success
    case failure
}

class PostToSeemitViewModel2: ObservableObject {
    var viewModel: PostToSeemitViewModel = PostToSeemitViewModel()
    var activityTypes = ["Aerobics", "BasketBall","Badminton", "Boxing", "Bootcamp","Calisthenics", "Chasing Pokemons", "Cricket", "Crossfit", "Cycling", "Daily Activity", "Dancing", "Elliptical", "Fitness Gaming", "Football", "Gardening", "Geocaching", "Golf", "Gym", "Hiking", "Hockey", "Home Improvement", "House Chores", "Jogging", "Kayaking", "Kettlebell Training", "Kid Play", "Martial Arts", "Moving Around Office", "Photowalking","Pickle Ball", "Plogging" ,"Rollerblading", "Rope Skipping", "Running", "Sailing", "Scootering", "Shopping", "Shoveling", "Skating", "Skiing", "Snowshoeing", "Stair Climbing", "Stair Mill", "Street Workout", "Stretching", "Swimming", "Table Tennis", "Tennis", "Treadmill", "Volleyball", "Walking", "Weight Lifting", "Yard Work", "Yoga"].sorted()
    /// The common activities shown up-front as chips; the rest sit behind "Show more" (Android parity).
    let topActivities = ["Walking", "Running", "Cycling", "Gym", "Dancing", "Yoga", "Swimming", "Hiking", "Daily Activity", "Weight Lifting"]
    var randomHints = ["Describe your day's activity using original content in as little as a few sentences. The more the merrier!","What did you do today?", "Got some cool content to share?", "The more original content you write, the better the potential rewards!", "Did you cross some milestones today? tell the world about it!", "How's your fitness journey going? share it with other actifitters", "You got cool pics from your walk/jog/workout/...? Let's go"]
    var activityDate = ""
    var activityDateToSave = Date()
    var detailedActivityStepsDataString = ""
    var encyptedFitBit = ""
    var healthStore = HKHealthStore()
    var postPayout = ""
    @Published var postTitle: String = ""
    @Published var reportTags: String = ""
    @Published var isToday: Bool = true
    @Published var isFitBit: Bool = false
    @Published var isHealthStore: Bool = false
    @Published var stepCount: String = "0"
    @Published var showActivityTypes = false
    @Published var selectedActivities: [String] = ["Activity Type"]
    @Published var height: String = ""
    @Published var weight: String = ""
    @Published var bodyFat: String = ""
    @Published var waist: String = ""
    @Published var thights: String = ""
    @Published var chest: String = ""
    @Published var markDownCharacterCount: Int = 0
    @Published var markDownContent: String = ""
    @Published var showLoader = false
    @Published var showMarkDownInfoAlert = false
    var activityPostModel: PostActivityModel? = nil
    @Published var showCharityAlert: Bool = false
    @Published var showMinStepsAlert: Bool = false
    @Published var showMinCharsAlert: Bool = false
    @Published var showNoActivitiesAlert: Bool = false
    @Published var showNotReachedMinimumAlert: Bool = false
    @Published var showSuccessPosting: Bool = false
    @Published var selectedVideo: Video? = nil
    @Published var postState: PostState = .none
    var selectedActivitiesString: String {
        selectedActivities.joined(separator: ", ")
    }

    var isFitbitSensor: Bool {
        return UserDefaults.standard.isThirdPartySensor ?? false
    }

    init() {
        self.activityDate = AppDelegate.todayStartDate().dateString()
        if isFitbitSensor {
            let fitbitSteps = UserDefaults.standard.lastSynchronizedSteps
            isFitBit = true
            stepCount = String(fitbitSteps)
        }
        self.btnTodayTapped()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.getHealthKitPermission()//Todo: remove this
        })
    }
    var stepCountInDigit: Int {
        return Int(stepCount) ?? 0
    }

    var fitbitUserId: String? = nil
    var measurmentKeys: [String: String] = [:]
    func updatePostContent(content: String) {
        UserDefaults.standard.postContent = content
        markDownContent = content
    }

    lazy var settings = {
        return Settings.current()
    }()

    var sanitizedMarkDownContent: String {
        markDownContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : markDownContent
    }

    func getInitialMarkdownContent() {
        markDownContent =  UserDefaults.standard.postContent ?? ""
    }

    func todayDateStringWithFormat(format : String) -> String {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = format
        dateFormatter.timeZone = NSTimeZone.local
        return dateFormatter.string(from: Date())
    }

    func uploadImage(image: UIImage) async {
        DispatchQueue.main.async {
            self.showLoader = true
        }

        let deviceUUID: String = await (UIDevice.current.identifierForVendor?.uuidString)!
//        _ = deviceUUID + String(Date().ticks)

        do {
            let imageURL = try await ImageUploadManager().uploadImage(image)

            DispatchQueue.main.async {
                self.showLoader = false

                if let data = UserDefaults.standard.postContent {
                    let newContent = data + "\n" + (imageURL + " " + "\n")
                    UserDefaults.standard.postContent = newContent
                    self.markDownContent = newContent
                } else {
                    self.markDownContent = imageURL
                    UserDefaults.standard.postContent = imageURL
                }
            }
        } catch {
            print(error.localizedDescription)
            DispatchQueue.main.async {
                self.showLoader = false
            }
            print(error.localizedDescription)
        }
    }

    var isActivityTypeEmpty: Bool {
        return selectedActivities.contains("Activity Type")
    }

    var isContentValid: Bool {
        return (postContent?.count ?? 0) < 100
    }

    var isReportTagsEmpty: Bool {
        return reportTags.isEmpty
    }

    var isStepsValid: Bool {
        return stepCountInDigit > 500
    }

    var username: String {
        return User.current()?.steemit_username ?? ""
    }

    func authorizationDidFinish(authToken: String, fitbitId: String? = nil) {
        self.fitbitUserId = fitbitId
        FitbitAPI.sharedInstance.authorize(with: authToken)
        let _ = StepStat.fetchTodaysStepStat(forDate: self.activityDateToSave) { [weak self] stepStat, error in
            let steps = stepStat?.steps ?? 0
            print(steps)
            self?.isFitBit = true
            self?.isHealthStore = false
            self?.stepCount = String(steps)
        }
        var fetchMeasurments = false
        if let settings = self.settings {
            fetchMeasurments = settings.fitBitMeasurement
        }

        if fetchMeasurments {
            let _ = StepStat.fetchUser() { [weak self] userStat, error in
                self?.measurmentKeys.updateValue("\(userStat!["height"] as! NSNumber)", forKey: PostKeys.height)
                self?.measurmentKeys.updateValue("\(userStat!["weight"] as! NSNumber)", forKey: PostKeys.weight)
            }
        }
    }

    func btnTodayTapped() {
        isToday = true
        if !isFitbitSensor {
            stepCount = "\(0)"

            // Get today's start date
            let todayStartDate = AppDelegate.todayStartDate()

            // Filter and find the activity for today
            if let activity = Activity.allWithoutCountZero().first(where: { resetTime(date: $0.date) == resetTime(date: todayStartDate) }) {
                stepCount = "\(activity.steps)"
                isFitBit = false
                self.activityDateToSave = todayStartDate
                self.makeTodayAllEnteriesAsDetailedActivityString()
            } else {
                self.getHealthKitPermission()
            }
        }
    }

    func makeTodayAllEnteriesAsDetailedActivityString() {
        self.detailedActivityStepsDataString = ""
        let todayDateString = Date().getTodaysDateYearAndMonthAndDay()
        let dataList = ActivityFifteenMinutesInterval.all().filter({$0.steps != 0 && $0.date == todayDateString})

        self.detailedActivityStepsDataString = dataList.map { activity in
            let timeSlot = activity.interval.replacingOccurrences(of: ":", with: "")
            let stepsInTimeSlot = String(activity.steps)
            return timeSlot + stepsInTimeSlot
        }.joined(separator: "|")
    }

    func btnYesterdayTapped() {
        isToday = false
        if !isFitBit {
            retrieveStepCount { steps in
                DispatchQueue.main.async {
                    self.stepCount = "\(Int(steps))"
                }
            }
        } else {
            self.activityDate = AppDelegate.todayStartDate().yesterday.dateString()
            self.activityDateToSave = AppDelegate.todayStartDate().yesterday
        }
    }

    func resetTime(date: Date) -> Date{
        let currentDate = date.setTime(hour: 00, min: 00, sec: 00)!

        return currentDate
    }

    func saveVideosLocally(video: Video) {
        guard let userName = User.current()?.steemit_username else { return }
        let videoData = viewModel.generate3speakJson(videoObject: video, username: userName)
        UserDefaults.standard.set3SepakVideo(dictionary: videoData)
    }

    func retrieveStepCount(completion: @escaping (_ stepRetrieved: Double) -> Void) {
        var startFrom = Date()
        var endUpto = Date()

        if isToday{
            startFrom = Calendar.current.startOfDay(for: Date())
            endUpto = Date()
        } else {
            startFrom = self.resetTime(date: AppDelegate.todayStartDate().addingTimeInterval(-60*60*24))
            endUpto = Calendar.current.startOfDay(for: Date())
        }
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(withStart: startFrom, end: endUpto, options: .strictStartDate)
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        healthStore.execute(query)
    }


    func getHealthKitPermission() {
        if !isFitbitSensor {
            //TODO: use healthkit Manager
            guard HKHealthStore.isHealthDataAvailable() else {
                print("Health kit is unavailable")
                return
            }
            let stepsCount = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
            self.healthStore.requestAuthorization(toShare: [], read: [stepsCount]) { (success, error) in
                if success {
                    self.retrieveStepCount { (steps) in
                        DispatchQueue.main.async{
                            self.isHealthStore = true
                            self.stepCount = String(Int(steps))
                            self.isFitBit = false
                        }
                    }
                }
                else {
                    if error != nil {
                        print(error ?? "")
                    }
                    print("Permission denied.")
                }
            }
        }
    }

    func checkIf3SpeakVideoIsStillValid() -> [String: Any]? {
        let localVideo = UserDefaults.standard.get3SpeakVideodictionary()
        if let retrievedData = localVideo {
            if let video = retrievedData["video"] as? String,
               let videoData = parseFromStringToJson(jsonString: video),
               let videoData2 = videoData["video"] as? [String: Any],
               let info = videoData2["info"] as? [String: Any],
               let sourceMap = info["sourceMap"] as? [[String: Any]] {
                if let thumbnailDict = sourceMap.first(where: { $0["type"] as? String == "thumbnail" }) {
                    if let thumbnailURL = thumbnailDict["url"] as? String {
                        print("Thumbnail URL: \(thumbnailURL)")
                        if let content = UserDefaults.standard.postContent {
                            if content != "" {
                                if content.contains(thumbnailURL.replacingOccurrences(of: "ipfs://", with: "")) {
                                    return localVideo
                                    // return the local video to the json object to send to the api
                                } else {
                                    UserDefaults.standard.clear()
                                }
                            }
                        }
                    }
                }
            }
        }
        return nil
    }

    func parseFromStringToJson(jsonString: String) -> [String: Any]? {
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        do {
            return try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
        } catch {
            print("Failed to convert JSON string to dictionary: \(error)")
            return nil
        }
    }

    func handle3speakVideo() {
        guard let video = selectedVideo else { return }
        self.saveVideosLocally(video: video)
        guard let videoURL = video.thumbnail else { return }
        let urlString  = "https://ipfs-3speak.b-cdn.net/ipfs/\(videoURL.replacingOccurrences(of: "ipfs://", with: ""))"
        let finalURL =  "[![](\(urlString))](https://3speak.tv/watch?v=\(User.current()?.steemit_username ?? "")/\(video.permlink ?? ""))"
        var content = postContent ?? ""
        content = content + "\n" + finalURL + "\n"
        UserDefaults.standard.postContent = content
        markDownContent = content
    }


    func SHA512Conversion(fitbitId:String) {
        guard let data = fitbitId.data(using: .utf8) else { return }
        let digest = SHA512.hash(data: data)
        print(digest.data) // 64 bytes
        print(digest.hexStr) //
        encyptedFitBit = digest.hexStr
    }

    func postToSteemitBtnAction() {
        var charityDisplayName = ""
        var charityName = ""

        var activityJson = [String : Any]()

        if let settings = self.settings {
            if settings.is100SPSelected {
                postPayout = "full_SP_Pay"
            } else if settings.isLiquidHBDSelected {
                postPayout = "liquid_Pay"
            } else if settings.isDeclinePayoutSelected {
                postPayout = "decline_Pay"
            } else if settings.isSbdSPPaySystemSelected {
                postPayout = "50_50_SBD_SP_Pay"
            } else {
                postPayout = "full_SP_Pay"
            }
            //send charity_name if is donating to charity and charity name is not empty
            if settings.isDonatingCharity {
                charityDisplayName = settings.charityDisplayName
                charityName = settings.charityName
            }
            if !(charityName.isEmpty) {
                activityJson[PostKeys.charity] = charityName
            }
            //updating from saved settings
        }


        self.proceeedPostingWith(json: activityJson)
    }

    func triggerCharityAlert() {
        if let settings = settings {
            if settings.isDonatingCharity && !(settings.charityName.isEmpty) {
                showCharityAlert = true
            } else {
                postToSteemitBtnAction()
            }

        } else {
            postToSteemitBtnAction()
        }
    }


    func proceeedPostingWith(json : [String : Any]) {
        // Hard 500-step minimum removed by request; the 5,000 "post anyway?"
        // confirmation on the submit button is the only step-count gate now.
        if selectedActivities.isEmpty || selectedActivities.contains("Activity Type") {
            showNoActivitiesAlert = true
            return
        }

        var activityJson = json
        if isFitBit {
            activityJson[PostKeys.dataTrackingSource] = "Fitbit Tracking"
        }
        else if isHealthStore{
            activityJson[PostKeys.dataTrackingSource] = "healthapp"
        }
        else if Activity.allWithoutCountZero().first(where: {resetTime(date: $0.date) == resetTime(date: AppDelegate.todayStartDate())}) != nil{//else if let activity =
            activityJson[PostKeys.dataTrackingSource] = "Device Tracking"
            activityJson[PostKeys.fitbitUserId] = ""
        }

        let contentText = markDownContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if contentText.count < PostContentMinCharsCount {
            showMinCharsAlert = true
            return
        }

        let userName = User.current()?.steemit_username.byTrimming(string: "@").lowercased()
        let privatePostingKey = User.current()?.private_posting_key
        activityJson[PostKeys.author] = userName
        activityJson[PostKeys.posting_key] = privatePostingKey
        activityJson[PostKeys.title] =  postTitle
        activityJson[PostKeys.content] = markDownContent
        activityJson[PostKeys.tags] = reportTags
        activityJson[PostKeys.step_count] = Int(stepCount)
        activityJson[PostKeys.activity_type] = selectedActivitiesString
        activityJson[PostKeys.height] = height
        activityJson[PostKeys.weight] = weight
        activityJson[PostKeys.chest] =  chest
        activityJson[PostKeys.waist] =  waist
        activityJson[PostKeys.thighs] =  thights
        activityJson[PostKeys.bodyfat] = bodyFat
        activityJson[PostKeys.activityDate] = self.activityDate.replacingOccurrences(of: "-", with: "")
        activityJson[PostKeys.detailedActivity] = self.detailedActivityStepsDataString
        if fitbitUserId != nil {
            SHA512Conversion(fitbitId: fitbitUserId!)
            activityJson[PostKeys.fitbitUserId] = encyptedFitBit
        }
        else{
            activityJson[PostKeys.fitbitUserId] = ""
        }

        activityJson[PostKeys.reportSTEEMPayMode] = postPayout
        if let actifitUserId = UserDefaults.standard.string(forKey: "actifitUserID") {
            activityJson[PostKeys.actifitUserID] = actifitUserId
        } else {
            activityJson[PostKeys.actifitUserID] = ""
        }
        var measurementSystem = MeasurementSystem.metric.rawValue
        if let settings = self.settings {
            measurementSystem = settings.measurementSystem
        }
        activityJson[PostKeys.weightUnit] = measurementSystem == MeasurementSystem.metric.rawValue ? MeasurementUnit.metric.kg : MeasurementUnit.us.lb
        activityJson[PostKeys.heightUnit] = measurementSystem == MeasurementSystem.metric.rawValue ? MeasurementUnit.metric.cm : MeasurementUnit.us.inch
        activityJson[PostKeys.chestUnit] = measurementSystem == MeasurementSystem.metric.rawValue ? MeasurementUnit.metric.cm : MeasurementUnit.us.inch
        activityJson[PostKeys.waistUnit] = measurementSystem == MeasurementSystem.metric.rawValue ? MeasurementUnit.metric.cm : MeasurementUnit.us.inch
        activityJson[PostKeys.thighsUnit] = measurementSystem == MeasurementSystem.metric.rawValue ? MeasurementUnit.metric.cm : MeasurementUnit.us.inch
        activityJson[PostKeys.timeZone] = NSCalendar.current.timeZone.abbreviation()
        activityJson[PostKeys.appType] = AppType
        activityJson[PostKeys.appVersion] = UIApplication.appVersion
        if markDownContent != "" {
            if let video = selectedVideo {
                if markDownContent.contains(video.thumbnail!.replacingOccurrences(of: "ipfs://", with: "")) {
                    activityJson.merge(viewModel.generate3speakJson(videoObject: video, username: User.current()?.steemit_username ?? "")) { (current, _) in current }
                } else {
                    selectedVideo = nil
                }
            } else {
                if let videoData = checkIf3SpeakVideoIsStillValid() {
                    activityJson.merge(videoData) { (current, _) in current }
                }
            }
        }
        let finalJsonObject = activityJson
        Task {
            await self.postActvityWith(json: finalJsonObject)
        }
    }

    @MainActor
    func postActvityWith(json : [String : Any]) async {
        showLoader = true
        let postActivity = await HTTPClient().postActivity(body: json)
        showLoader = false
        switch postActivity {
        case .success(let activityModel):
            self.activityPostModel = activityModel
            self.selectedVideo = nil
            self.postState = .success
            UserDefaults.standard.postContent = ""
            if let currentUser =  User.current() {
                
                currentUser.updateUser(steemit_username: currentUser.steemit_username, private_posting_key: currentUser.private_posting_key, last_post_date: self.activityDateToSave)
            }
        case .failure(let failure):
            self.postState = .failure
        }
    }

    var postContent: String? {
        return UserDefaults.standard.postContent
    }


    func grab3SpeakDefaultBenefic() -> [[String: Any]] {
        let firstBenefic: [String: Any] =
        ["account": "spk.beneficiary", "weight": 1000]
        return [firstBenefic]
    }

    func generate3speakJson(videoObject: Video, username: String) -> [String: Any]{
        var data: [String: Any] = [:]
        var sourceArray: [Any] = []
        let thumbnailDict: [String: Any] =
        ["type": "thumbnail",
         "url": videoObject.thumbnail ?? ""]

        sourceArray.append(thumbnailDict)
        let videoDict: [String: Any] = [
            "type": "video",
            "url": videoObject.videoV2 ?? "",
            "format" : "m3u8",
        ]
        sourceArray.append(videoDict)

        let tags = ["actifit", "3speak"]

        let contentDict: [String: Any] = [
            "description": "",
            "tags" : tags
        ]

        let info: [String: Any] = [
            "platform": "3speak",
            "title" : videoObject.title ?? "",
            "author": username,
            "permlink": videoObject.permlink ?? "",
            "duration": videoObject.duration ?? 0.0,
            "filesize": videoObject.size ?? 0.0,
            "file": videoObject.filename ?? "",
            "lang": "en",
            "firstUpload": false,
            "video_v2": videoObject.videoV2 ?? "",
            "sourceMap": sourceArray
        ]

        let videoJsonObject: [String: Any] = [//video in android
            "info": info,
            "content": contentDict
        ]

        let videoMetadata: [String: Any] = [
            "video": videoJsonObject,

        ]
        data.updateValue(parseFromJsonToString(json: videoMetadata) ?? "", forKey: "video")
        data.updateValue(videoObject.permlink ?? "", forKey: "spkPermlink")

        var spkBenefics: [[String: Any]] = grab3SpeakDefaultBenefic()
        let beneficiariesArray: [Beneficiary] = videoObject.extractBeneficiaries() ?? []
        beneficiariesArray.forEach { beneficiary in
            spkBenefics.append(["account": beneficiary.account, "weight": beneficiary.weight])
        }

        data.updateValue(spkBenefics, forKey: "spkBenefic")
        return data
    }

    func parseFromJsonToString(json: [String: Any]) -> String? {
        let jsonData: Data?
        do {
            jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
        } catch {
            print("Error encoding video metadata:", error)
            jsonData = nil
        }
        // Convert the data to a string using UTF-8 encoding
        let jsonString = String(data: jsonData!, encoding: .utf8)
        if let jsonString = jsonString {
            print("Video metadata JSON string:", jsonString)
        } else {
            print("Failed to convert encoded data to string")
        }
        return jsonString
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}


extension Digest {
    var bytes: [UInt8] { Array(makeIterator()) }
    var data: Data { Data(bytes) }

    var hexStr: String {
        bytes.map { String(format: "%02X", $0) }.joined()
    }
}

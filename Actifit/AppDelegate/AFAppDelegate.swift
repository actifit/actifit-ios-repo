//
//  AFAppDelegate.swift
//  Actifit
//
//  Created by Hitender kumar on 03/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit
import RealmSwift
import IQKeyboardManagerSwift
//import Fabric
import Firebase
//import Crashlytics
import UserNotifications
import DropDown
import Localizr_swift
import GoogleMobileAds
import AVFoundation
@UIApplicationMain
class AFAppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    let notificationCenter = UNUserNotificationCenter.current()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        //Enabling IBKeyboardManager to handle keyboard for textfields and textviews
        //Fabric.with([Crashlytics.self])
        setGoogleAdMobs()
        if UserDefaults.standard.string(forKey: "SelectedLanguage") == nil {
            Localizr.update(locale: "en")
        }
        //Localizr.update(locale: "en")
        FirebaseApp.configure()
        IQKeyboardManager.shared.enable = true
        DropDown.startListeningToKeyboard()
        registerForPushNotifications()
        UIApplication.shared.applicationIconBadgeNumber = 0
        
        let config = Realm.Configuration(
            schemaVersion: 10,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 9) {
                    migration.enumerateObjects(ofType: Settings.className()) { oldObject, newObject in
                        newObject!["isDeviceSensorSystemSelected"] = true
                        newObject!["isSbdSPPaySystemSelected"] = true
                        newObject!["isReminderSelected"] = false
                        newObject!["fitBitMeasurement"] = false
                        newObject!["appVersion"] = UIApplication.appVersion!
                        newObject!["notificationSelected"] = true
                        newObject!["hiveChain"] = ""
                        newObject!["steemChain"] = ""
                        newObject!["blurtChain"] = ""
                        
                    }
                }
            })
        Realm.Configuration.defaultConfiguration = config
        //lazy var realm:Realm = {
        //    return try! Realm()
        // }()
        
        do {
            let realm =  try Realm.init(configuration: config)
            print(realm)
        } catch {
            print("error")
        }
        
        
        notificationCenter.delegate = self
        
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        
        notificationCenter.requestAuthorization(options: options) {
            (didAllow, error) in
            if !didAllow {
                print("User has declined notifications")
            }
        }

        // Branded animated splash (Android parity), then hand off to login / dashboard.
        let splash = AnimatedSplashViewController()
        splash.onFinish = { [weak self] in self?.swapToMainRoot() }
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = splash
        window?.makeKeyAndVisible()
        TokenManager.shared.refreshToken()
      configureAudioSession()
       // UITabBar.appearance().barTintColor = .gray
        UITabBar.appearance().tintColor = .primaryRedColor()
        UITabBar.appearance().unselectedItemTintColor = .gray
        return true
    }

  func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, mode: AVAudioSessionModeDefault, options: .mixWithOthers)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print(error)
    }
  }

    private func setGoogleAdMobs() {
        if let bundlePath = Bundle.main.path(forResource: "Info", ofType: "plist") {
            let myDict = NSDictionary(contentsOfFile: bundlePath)
            if let googleAdsKey = myDict?.object(forKey: "google_ads_key") as? String {
                GADMobileAds.sharedInstance().start(completionHandler: nil)
                GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [ googleAdsKey ]
            } else {
                print("Value not found for key 'YourKey'")
            }
        } else {
            print("Info.plist not found")
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        let notification = Notification(
            name: Notification.Name(rawValue: "ACTIFIT"),
            object:nil,
            userInfo:[UIApplicationLaunchOptionsKey.url:url])
        NotificationCenter.default.post(notification)
        return true
    }
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: Realm Method helpers
    
    func defaultRealm() -> Realm? {
            var config = Realm.Configuration.defaultConfiguration
            config.schemaVersion =  10 //CurrentRealmSchemaVersion
            config.migrationBlock = { (migration, oldSchemaVersion) in

                migration.enumerateObjects(ofType: Settings.className()) { oldObject, newObject in
                    newObject!["isDeviceSensorSystemSelected"] = true
                    newObject!["isSbdSPPaySystemSelected"] = true
                    newObject!["isReminderSelected"] = false
                    newObject!["fitBitMeasurement"] = false
                    newObject!["appVersion"] = UIApplication.appVersion!
                    newObject!["notificationSelected"] = true
                    newObject!["hiveChain"] = ""
                    newObject!["steemChain"] = ""
                    newObject!["blurtChain"] = ""

                }

            }
            do {
                Realm.Configuration.defaultConfiguration = config
                // lazy var realm:Realm = {
                //     return try! Realm()
                // }()
                let realm =  try Realm.init(configuration: config)
                return realm
            } catch let error {
                print(error.localizedDescription)
            }


            return nil

    }
    
    //HELPERS
    
    //returns current day date from midnight
    func todayStartDate() -> Date {
        //For Start Date
        var calendar = NSCalendar.current
        calendar.timeZone = NSTimeZone.local
        let dateAtMidnight = calendar.startOfDay(for: Date())
        return dateAtMidnight
    }
    
    func yesterdayStartDate() -> Date {
        let currentDate = Date()
        let timezoneOffset =  TimeZone.current.secondsFromGMT()
        let epochDate = currentDate.timeIntervalSince1970
        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        let timeZoneOffsetDate = Date(timeIntervalSince1970: timezoneEpochOffset)
        return timeZoneOffsetDate
    }
    
    
    
    
    func startDateFor(date : Date) -> Date {
        //For Start Date
        var calendar = NSCalendar.current
        calendar.timeZone = NSTimeZone.local
        let dateAtMidnight = calendar.startOfDay(for: date)
        return dateAtMidnight
        
        //        let currentDate = date //Date()
        //        let timezoneOffset =  TimeZone.current.secondsFromGMT()
        //        let epochDate = currentDate.timeIntervalSince1970
        //        let timezoneEpochOffset = (epochDate + Double(timezoneOffset))
        //        let timeZoneOffsetDate = Date(timeIntervalSince1970: timezoneEpochOffset)
        //        return timeZoneOffsetDate
        
    }
    
    func todayLocalDate() -> Date {
        let date = Date()
        let dateFormatter = DateFormatter()
        //To prevent displaying either date or time, set the desired style to NoStyle.
        dateFormatter.timeStyle = DateFormatter.Style.medium //Set time style
        dateFormatter.dateStyle = DateFormatter.Style.medium //Set date style
        dateFormatter.timeZone = TimeZone.current
        let localDateStr = dateFormatter.string(from: date)
        return dateFormatter.date(from: localDateStr) ?? Date()
    }
    
    func stringFromDate(date : Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy" //Your New Date format as per requirement change it own
        let newDate = dateFormatter.string(from: date) //pass Date here
        return newDate
    }
    
}

extension AFAppDelegate:MessagingDelegate{
    
    func registerForPushNotifications() {
        UNUserNotificationCenter.current() // 1
            .requestAuthorization(options: [.alert, .sound, .badge]) { // 2
                granted, error in
                print("Permission granted: \(granted)") // 3
                guard granted else { return }
                self.getNotificationSettings()
            }
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if let userName = User.current()?.steemit_username {
            let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
            let token = tokenParts.joined()
            Messaging.messaging().apnsToken = deviceToken
            let str =  Messaging.messaging().fcmToken
            print("Device Token: \(token)")
            UserDefaults.standard.setValue(str, forKey: "DeviceToken")
            Messaging.messaging().subscribe(toTopic: "actidefnots") { error in
            }
            API().registerNotification(info: ["user": userName, "token" : str, "app": "iOS"]) { info, statusCode in
            } failure: { error in
            }
        }
        
    }
    
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error) {
            print("Failed to register: \(error)")
        }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            print("Notification settings: \(settings)")
            guard settings.authorizationStatus == .authorized else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
}




extension AFAppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if UserDefaults.standard.bool(forKey: "notifications") == false{
            completionHandler([])
        }
        else{
            completionHandler([.alert, .sound])
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.identifier == "Local Notification" {
            print("Handling notifications with the Local Notification Identifier")
        }
        
        completionHandler()
    }
    
    func scheduleNotification(steps: Int) {
        
        let content = UNMutableNotificationContent() // Содержимое уведомления
        let categoryIdentifire = "Delete Notification Type"
        
        content.title = "Actifit"
        if steps == 5{
            content.body = "Congrats On Reaching \(steps)K Milestone. Keep Going!"
        }else{
            content.body = "Congrats On Reaching \(steps)K Milestone. Well Done!"
        }
        
        content.sound = UNNotificationSound.default()
        content.badge = 1
        content.categoryIdentifier = categoryIdentifire
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let identifier = "Local Notification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { (error) in
            if let error = error {
                print("Error \(error.localizedDescription)")
            }
        }

    }
}

// MARK: - Branded splash routing

extension AFAppDelegate {
    /// The real first screen once the splash finishes: dashboard if logged in, else login.
    func makeMainRootViewController() -> UIViewController {
        if User.current()?.steemit_username == nil {
            let loginSB = UIStoryboard(name: "Login", bundle: nil)
            return loginSB.instantiateViewController(withIdentifier: "LoginViewController")
        } else {
            let storyboard = UIStoryboard(name: "Tabbar", bundle: nil)
            let tabbar = storyboard.instantiateViewController(withIdentifier: "TabbarController")
            return UINavigationController(rootViewController: tabbar)
        }
    }

    func swapToMainRoot() {
        guard let window = window else { return }
        let root = makeMainRootViewController()
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
            window.rootViewController = root
        }, completion: nil)
    }
}

// MARK: - Animated splash (Android parity: red screen, logo pop, wordmark)

final class AnimatedSplashViewController: UIViewController {

    var onFinish: (() -> Void)?
    private let logo = UIImageView(image: UIImage(named: "circular_logo") ?? UIImage(named: "logo"))
    private let wordmark = UILabel()
    private var didFinish = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 1.0, green: 17/255, blue: 45/255, alpha: 1) // #FF112D

        // Start with the logo already visible so it continues seamlessly from the
        // static LaunchScreen (which also shows a centered logo on the same red).
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logo)

        wordmark.attributedText = NSAttributedString(string: "ACTIFIT", attributes: [
            .font: UIFont.systemFont(ofSize: 26, weight: .bold),
            .foregroundColor: UIColor.white,
            .kern: 4.0
        ])
        wordmark.alpha = 0
        wordmark.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(wordmark)

        NSLayoutConstraint.activate([
            logo.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logo.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),
            logo.widthAnchor.constraint(equalToConstant: 120),
            logo.heightAnchor.constraint(equalToConstant: 120),
            wordmark.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            wordmark.topAnchor.constraint(equalTo: logo.bottomAnchor, constant: 22)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playAnimation()
    }

    private func playAnimation() {
        // Gentle logo "breathe" (echoes Android's animated icon) — seamless from launch.
        UIView.animate(withDuration: 0.45, delay: 0.15, options: [.autoreverse, .curveEaseInOut], animations: {
            self.logo.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
        }, completion: { _ in
            self.logo.transform = .identity
        })
        // Wordmark fades up
        UIView.animate(withDuration: 0.4, delay: 0.2, options: [.curveEaseOut], animations: {
            self.wordmark.alpha = 1
        })
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.finish()
        }
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        onFinish?()
    }
}

//
//  UserDefaults+Extension.swift
//  Actifit
//
//  Created by Ali Jaber on 05/07/2023.
//

import Foundation
//
//  UserDefaultHelper.swift
//  My Secrete Box
//
//  Created by Ali Jaber on 03/05/2023.
//

import Foundation

enum UserDefaultKeys: String {
  case tipsIds
  case showTips
  case lastGiftPrizeDate
  case lastPrizeAmount
  case lastPrizeType
  case lastChatDisplayDate
  case lastNotificationCount
  case freeReward
  case fiveKReward
  case sevenKReward
  case tenKReward
  case activeKey
  case fundsPassword
  case postcontent
  case xcstkn
  case username = "currentUserName"
  case ppkey = "currentUserPrivateKey"
  case authToken
  case mainSensorIsMobile
  case lastDateStepSynchronization
  case lastSynchronizedSteps
}

enum MainSensorType: String {
  case fitbit
  case Mobile
}

extension UserDefaults {

  var lastSynchronizedSteps : Int {
    get {
      return integer(forKey: UserDefaultKeys.lastSynchronizedSteps.rawValue)
    } set {
      set(newValue, forKey: UserDefaultKeys.lastSynchronizedSteps.rawValue)
    }
  }

  var isThirdPartySensor: Bool? {
    get {
      return bool(forKey: UserDefaultKeys.mainSensorIsMobile.rawValue)
    } set {
      set(newValue, forKey: UserDefaultKeys.mainSensorIsMobile.rawValue)
    }
  }

  var lastDateStepSynchronization : String? {
    get {
      return string(forKey: UserDefaultKeys.lastDateStepSynchronization.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.lastDateStepSynchronization.rawValue)
    }
  }

  var username : String {
    get {
      return string(forKey: UserDefaultKeys.username.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.username.rawValue)
    }
  }

  var privatePostingKey : String {
    get {
      return string(forKey: UserDefaultKeys.ppkey.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.ppkey.rawValue)
    }
  }

  var authToken : String {
    get {
      return string(forKey: UserDefaultKeys.authToken.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.authToken.rawValue)
    }
  }


  var getTipIds: [String] {
    get {
      return array(forKey: UserDefaultKeys.tipsIds.rawValue) as? [String] ?? []
    }
    set {
      set(newValue, forKey: UserDefaultKeys.tipsIds.rawValue)
    }
  }

  var showTips: Bool {
    get {
      return bool(forKey: UserDefaultKeys.showTips.rawValue)
    } set {
      set(newValue, forKey: UserDefaultKeys.showTips.rawValue)
    }
  }

  var getLatestAdDate : String {
    get {
      return string(forKey: UserDefaultKeys.lastGiftPrizeDate.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.lastGiftPrizeDate.rawValue)
    }
  }



  var getLatestPrizeAmount : String {
    get {
      return string(forKey: UserDefaultKeys.lastPrizeAmount.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.lastPrizeAmount.rawValue)
    }
  }

  var latestPrizeType : String {
    get {
      return string(forKey: UserDefaultKeys.lastPrizeType.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.lastPrizeType.rawValue)
    }
  }

  var lastChatDateDisplay : String {
    get {
      return string(forKey: UserDefaultKeys.lastChatDisplayDate.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.lastChatDisplayDate.rawValue)
    }
  }

  var lastNotificationCount : Int {
    get {
      return integer(forKey: UserDefaultKeys.lastNotificationCount.rawValue)
    } set {
      set(newValue, forKey: UserDefaultKeys.lastNotificationCount.rawValue)
    }
  }
  var freeReward : String {
    get {
      return string(forKey: UserDefaultKeys.freeReward.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.freeReward.rawValue)
    }
  }

  var fiveKReward : String {
    get {
      return string(forKey: UserDefaultKeys.fiveKReward.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.fiveKReward.rawValue)
    }
  }

  var sevenKReward : String {
    get {

      return string(forKey: UserDefaultKeys.sevenKReward.rawValue) ?? ""
    } set {
      set(newValue, forKey: UserDefaultKeys.sevenKReward.rawValue)
    }
  }


  var tenKReward : String {
    get {

      return string(forKey: UserDefaultKeys.tenKReward.rawValue) ?? ""
    } set {

      set(newValue, forKey: UserDefaultKeys.tenKReward.rawValue)
    }
  }

  var activeKey : String {
    get {

      return string(forKey: UserDefaultKeys.activeKey.rawValue) ?? ""
    } set {

      set(newValue, forKey: UserDefaultKeys.activeKey.rawValue)
    }
  }

  var fundPassword : String {
    get {

      return string(forKey: UserDefaultKeys.fundsPassword.rawValue) ?? ""
    } set {

      set(newValue, forKey: UserDefaultKeys.fundsPassword.rawValue)
    }
  }

  var postContent : String? {
    get {

      return string(forKey: UserDefaultKeys.postcontent.rawValue)
    } set {

      set(newValue, forKey: UserDefaultKeys.postcontent.rawValue)
    }
  }

  var setXcstkn : String? {
    get {

      return string(forKey: UserDefaultKeys.xcstkn.rawValue)
    } set {

      set(newValue, forKey: UserDefaultKeys.xcstkn.rawValue)
    }
  }

}


//
//  Structs.swift
//  Actifit
//
//  Created by Hitender kumar on 11/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import Foundation

let PostContentMinCharsCount = 100
let PostMinActivityStepsCount = 500
let CurrentAppVersion = "0.3.4"
let AppType = "iOS"

//MARK: PopUp messages
struct Messages {
    static let app_name = "Actifit Fitness Tracker"
    static let sending_post = "Sending your post"
    static let success_post = "Your post has been successfully submitted"
    static let failed_post = "There was an error submitting your post"
    static let connection_timeout = "Connecting to the node took too long. Please try again."
    static let default_post_title = "My Actifit Report Card: "
    static let error_need_select_one_activity = "You need to select at least one Activity Type to proceed"
    static let fetching_leaderboard = "Updating the leaderboard..."
    static let leader_no_results = "There are no users on the leaderboard now"
    static let leader_error = "An error occurred trying to fetch leaderboard list. Please Try again later."
    static let username_missing = "Please provide a proper existing username"
    static let fetching_user_balance = "Grabbing user balance..."
    static let metric_system = "Metric System"
    static let us_system = "US System"
    static let back_exit_confirmation = "Click BACK button again if you want to exit"
    static let actifit_service_desc = "Actifit Service to keep track of user activity"
    static let activity_today_string = "Actifit Service to keep track of user activity"
    static let actifit_notif_channel = "Total Activity Today:"
    static let actifit_notif_description = "Channel used for sending out notifications of Actifit App"
    static let actifit_channel_ID = "Actifit_Notif_Channel_1"
    static let aggr_back_tracking_on = "ON"
    static let aggr_back_tracking_off = ""
    static let aggr_mode_note = "*Enable this setting if you are facing issues with app tracking your movement while screen is locked. The setting may possibly drain your battery faster."
    static let one_post_per_day_error = "You can only post once per day"
    static let min_word_count_error = "You need to describe your activity in at least "
    static let word_plural_label = "words"
    static let characters_plural_label = "characters"
    static let current_workout_going_charity = "Your current activity rewards will go to charity "
    static let loading_charities = "Loading Charities..."
    static let loading_userSettings = "Loading User Setting..."
    static let loading_notifications = "Loading Notifications..."
    static let loading = "Loading..."
    static let current_workout_settings_based = "based on your settings choice. Are you sure you want to proceed? "
    static let min_activity_steps_count_error = "You have not reached the minimum "
    static let validatingCredentials = "Validating Credentials..."
    static let steemit_url = "https://www.steemit.com/"
    
    static let loginMessage = "Login Successful"
    static let updatedSettings = "Settings Updated"
    
    //for textfields
    static let Required = "Required"
    static let IncorrectEmail = "Invalid email address"
    static let InvalidUsername = "Invalid username"
    static let PasswordTooShort = "Password is too short (minimum is 8 characters)"
    static let UsernameTooShort = "Username is too short (minimum is 8 characters)"
    static let PasswordCntn1Nmbr = "Password should contain at least one number"
    static let SmthngWntWrng = "Something went wrong"
    static let InternalServerError = "Whoa! We encountered an error!"
    static let InstructionsToResetEmail = "You will receive an email with instructions on how to reset your password in a few minutes"
    static let NoInternet = "The Internet connection appears to be offline"
    static let EmailNotFound = "Email not found"
    static let ReferralCodeApplied = "Referral code successfully applied"
    static let EnterReferralCode = "Enter referral code"
    static let UnauthorizedAccess = "Unauthorized access"
    static let ForgotPasswordInstructions = "Instructions to reset password has been send to this email address."
}

//MARK: AppCenter Secrets
struct AppCenter {
    static let SecretKey = Secrets.appCenterSecret
    static let redirectURI = "actifitcb%3A%2F%2Ffitbitcallback"//"redirectURI"
    static let clientID = "22D54N"
    static let defaultScope = "activity%20heartrate%20location%20profile%20weight"
}

//MARK: Activity Model Keys
struct ActivityKeys {
    static let id = "id"
    static let date = "date"
    static let steps = "steps"
}
//MARK: Activity Model Keys
struct fifteenActivityKeys {
   // static let id = "id"
    static let date = "date"
    static let steps = "steps"
    static let interval = "interval"
}

//MARK: User Model Keys
struct UserKeys {
    static let steemit_username = "steemit_username"
    static let private_posting_key = "private_posting_key"
    static let last_post_date = "last_post_date"
}

//MARK: SERVER POST KEYS

struct PostKeys {
    static let author = "author"
    static let posting_key = "posting_key"
    static let title = "title"
    static let content = "content"
    static let tags = "tags"
    static let step_count = "step_count"
    static let activity_type = "activity_type"
    static let height = "height"
    static let weight = "weight"
    static let chest = "chest"
    static let waist = "waist"
    static let thighs = "thighs"
    static let bodyfat = "bodyfat"
    static let weightUnit = "weightUnit"
    static let heightUnit = "heightUnit"
    static let chestUnit = "chestUnit"
    static let waistUnit = "waistUnit"
    static let thighsUnit = "thighsUnit"
    static let appType = "appType"
    static let appVersion = "appVersion"
    static let charity = "charity"
    static let fullafitpay = "full_afit_pay"
    static let reportSTEEMPayMode = "reportSTEEMPayMode"
    static let actifitUserID = "actifitUserID"
    static let fitbitUserId = "fitbitUserId"
    static let dataTrackingSource = "dataTrackingSource"
    static let activityDate = "activityDate"
    static let detailedActivity = "detailedActivity"
    static let timeZone = "timezone"

}

//MARK: Measurement units
struct MeasurementUnit  {
   
    struct metric {
        static let cm = "cm"
        static let kg = "kg"
    }
    
    struct us {
        static let lb = "lb"
        static let ft = "ft"
        static let inch = "in"
    }
}

//MARK: Request HTTP Methods
struct SettingsKeys  {
    static let measurementSystem = "measurementSystem"
    static let isDonatingCharity = "isDonatingCharity"
    static let charityName = "charityName"
    static let charityDisplayName = "charityDisplayName"
   
    static let datasource = "datasource"
    static let postpayout = "postpayout"
    static let reminder = "reminder"
    static let fitBitMeasurement = "fitBitMeasurement"
    static let AppVersion = "AppVersion"
    static let notifications = "Notifications"
    static let hiveChain = "Hive"
    static let steemChain = "Steem"
    static let blurtChain = "Blurt"
    static let isLiquidHBD = "liquidHBD"
    static let isDeclinePayment = "declinePayment"
    static let is100SP = "100SP"
}

//MARK: Request HTTP Methods
enum HttpMethods  {
    static let HttpMethod_GET = "GET"
    static let HttpMethod_POST = "POST"
    static let HttpMethod_DELETE = "DELETE"
    static let HttpMethod_PUT = "PUT"
    static let HttpMethod_UPDATE = "UPDATE"
}

//API URLS
enum ApiUrls {
    static let sendBalanceAndHive = "https://api.actifit.io/performTrxPost/"
    static let broadCastQueryAPI = "https://api.actifit.io/performTrx/"
    static let afitAmountSent = "https://api2.actifit.io/tipAccount/"
    static let notificationRead = "https://chat-api.peakd.com/api/readNotifications/"
    static let notificationStats = "https://chat-api.peakd.com/api/stats"
    static let castSurveyURL = "https://api.actifit.io/voteSurvey?"
    static let surveyStatusURL = "https://api.actifit.io/userVotedSurvey?"
    static let surveysURL = "https://api.actifit.io/surveys"
    static let videoTutorial = "https://api.actifit.io/tutorialVidUrl"
    static let registerPushNotification =  "https://api.actifit.io/registerUserNotification"
    static let getMarketExchange = "https://api.actifit.io/afitMarkets"
    static let getReferrals = "https://api.actifit.io/referrals/"
    static let getUserData = "https://api.actifit.io/getAccountData/"
    static let walletBalance = "https://api.actifit.io/user/"
    static let transactions = "https://api.actifit.io/transactions/"
    static let charities = "https://api.actifit.io/charities/"
    static let getRank = "https://api.actifit.io/getRank/"
    static let getUserSetting = "https://api.actifit.io/userSettings"
    static let updateUserSetting = "https://api.actifit.io/updateSettings"
    static let notificationType = "https://api2.actifit.io/notificationTypes"
    static let hiveBlogURL = "https://api.syncad.com/"
    // Phase 1 — Wallet parity (Android port)
    static let pendingRewards = "https://api.actifit.io/pendingRewards"
    static let claimRewards = "https://api.actifit.io/claimRewards"
    static let hiveRPCNode = "https://hiveapi.actifit.io"
    // Phase 2 — Gadget marketplace parity (Android port)
    static let products = "https://api.actifit.io/products"
    static let nonConsumedGadgets = "https://api.actifit.io/nonConsumedGadgetsByUser/"
    static let consumedGadgets = "https://api.actifit.io/consumedGadgetsByUser/"
    static let exchangeAfitPrice = "https://api.actifit.io/exchangeAFITPrice"
    static let buyGadgetConfirm = "https://api.actifit.io/buyGadget/"
    static let buyGadgetHiveConfirm = "https://api.actifit.io/buyGadgetHive/"
    static let activateGadgetConfirm = "https://api.actifit.io/activateGadget/"
    static let deactivateGadgetConfirm = "https://api.actifit.io/deactivateGadget/"
    static let actifitMarketAccount = "actifit.market"
    static let gadgetImageBase = "https://actifit.io/img/gadgets/"
}

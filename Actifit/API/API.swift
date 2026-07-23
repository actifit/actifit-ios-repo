//
//  API.swift
//  Actifit
//
//  Created by Hitender kumar on 15/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import Foundation

typealias APICompletionHandler = ((_ info : Any?,_ statusCode: Int? ) -> ())?
typealias APIFailureHandler = ((_ error : NSError) -> ())?

public class API : NSObject{

  //MARK: Initializers

  override init() {
  }

  class var sharedInstance : API {
    return API()
  }

  func submitVideo3Speak(params: [String: Any], completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = "https://studio.3speak.tv/mobile/api/upload_info?app=actifit"
    var request = URLRequest.init(url: URL(string: url)!)
    request.addBasicHeaderFieldsForUpdateSettings()
    request.appendBodyWith(json: params)
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure, handleCookies: true)
  }

  func loginThroughVideo3Speak( username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = "https://studio.3speak.tv/mobile/login?username=\(username)"
    var request = URLRequest.init(url: URL(string: url)!)
    request.addBasicHeaderFields()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }


  func verifyActifit3SpeakVideoMemo(username: String,body: [String: Any], completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = "https://api.actifit.io/memoDecode/?user=\(username)&bchain=HIVE"
    var request = URLRequest.init(url: URL(string: url)!)
    request.addBasicHeaderFieldsForUpdateSettings()
    request.appendBodyWith(json: body)
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure)
  }

  func grab3SpeakCookie(username: String, token: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = "https://studio.3speak.tv/mobile/login?username=\(username)&access_token=\(token)"
    let request = URLRequest.init(url: URL(string: url)!)
   // request.addBasicHeaderFieldsForUpdateSettings()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure, handleCookies: true)

  }

  func fetchUserVideosFrom3Speak(completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = "https://studio.3speak.tv/mobile/api/my-videos"
    var request = URLRequest.init(url: URL(string: url)!)
    request.addBasicHeaderFieldsForUpdateSettings()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure, handleCookies: true)
  }

  func deleteVideo(videoPermlLink: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = "https://studio.3speak.tv/mobile/api/video/\(videoPermlLink)/delete"
    var request = URLRequest.init(url: URL(string: url)!)
    request.addBasicHeaderFieldsForUpdateSettings()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure, handleCookies: true)
  }


  func sendHiveOrHBDAPI(from: String, to: String, amount: String, memo: String?,completion: APICompletionHandler, failure: APIFailureHandler, blockChain: String, activeKey: String) {
    //"op_name": "transfer"
    let params = ["from": from, "to": to, "amount": amount, "memo": memo]
    let array: [Any] = ["transfer", params]
    // let params2: [String:Any] = ["0": "transfer","1": params]


    do {
      let jsonData = try JSONSerialization.data(withJSONObject: [array], options: .prettyPrinted)
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("Encoded JSON string: \(jsonString)")
        let cleanedJsonString = jsonString.replacingOccurrences(of: "\n", with: "")
        let finalParams: [String: Any] = ["operation": cleanedJsonString,"active": activeKey]
        let apiURL = ApiUrls.sendBalanceAndHive + "?user=\(from)&bchain=HIVE"
        let url = URL(string:apiURL)
        var request = URLRequest.init(url: url!)
        request.appendBodyWith(json: finalParams)
        request.addBasicHeaderFieldsForUpdateSettings()
        forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure)

      }
    }catch let error {
      print(error.localizedDescription)
    }
  }


  func sendAfitAmount(username: String, targetUser: String, amount: String, fundPass: String, note: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let paramString = "?user=\(username)&targetUser=\(targetUser)&amount=\(amount)&fundsPass=\(fundPass)&note=\(note)"
    if let url  = URL(string: ApiUrls.afitAmountSent + paramString) {
      var request = URLRequest.init(url: url)
      request.addBasicHeaderFieldsForUpdateSettings()
      forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
    }
  }

  func broadCasrtAfitAmountSent(username: String, targetUser: String, amount: String, note: String, completion: APICompletionHandler, failure: APIFailureHandler){
    let parameters: [String: Any] = [
      "required_auths": [],
      "required_posting_auths": [username],
      "id": "actifit",
      "json":"{\"action\":\"Tip\",\"amount\":\"\(amount)\",\"recipient\":\"\(targetUser)\",\"note\":\"\(note)\"}"
    ]
    let finalizedParams: [Any] = ["custom_json", parameters]
    var urlString = ApiUrls.broadCastQueryAPI + "?user=\(username)"
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: finalizedParams, options: .prettyPrinted)
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("Encoded JSON string: \(jsonString)")
        let cleanedJsonString = jsonString.replacingOccurrences(of: "\n", with: "")
        urlString = urlString + "&operation=[\(cleanedJsonString)]&bchain=HIVE"
        if let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
          let url  = URL(string: encodedString)
          var request = URLRequest.init(url: url!)
          request.addBasicHeaderFieldsForUpdateSettings()
          forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
        }
      }
    }catch let error {
      print(error.localizedDescription)
    }

  }


  // MARK: - Phase 1: Wallet parity (Android port)

  /// Shared active-key broadcast wrapper (mirrors Android `Utils.queryAPIPost` → performTrxPost).
  /// `operation` is a single op array `[opName, params]`; it is wrapped as `[[opName, params]]`.
  private func broadcastActiveOperation(user: String, operation: [Any], activeKey: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: [operation], options: [])
      guard let jsonString = String(data: jsonData, encoding: .utf8) else {
        failure?(NSError(domain: "Actifit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to encode operation"]))
        return
      }
      let cleanedJsonString = jsonString.replacingOccurrences(of: "\n", with: "")
      let finalParams: [String: Any] = ["operation": cleanedJsonString, "active": activeKey]
      let apiURL = ApiUrls.sendBalanceAndHive + "?user=\(user)&bchain=HIVE"
      guard let url = URL(string: apiURL) else { return }
      var request = URLRequest.init(url: url)
      request.appendBodyWith(json: finalParams)
      request.addBasicHeaderFieldsForUpdateSettings()
      forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure)
    } catch let error {
      print(error.localizedDescription)
      failure?(error as NSError)
    }
  }

  /// Send an arbitrary Hive-Engine token (transfer / stake / unstake) via custom_json (active key).
  /// `action` is one of "transfer", "stake", "unstake".
  func hiveEngineTokenOperation(user: String, symbol: String, to: String, quantity: String, memo: String, action: String, activeKey: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let json = "{\"contractName\": \"tokens\" , \"contractAction\": \"\(action)\" , \"contractPayload\": {\"symbol\": \"\(symbol)\", \"to\": \"\(to)\",\"quantity\": \"\(quantity)\",\"memo\": \"\(memo)\"}}"
    let customParams: [String: Any] = [
      "required_auths": [user],
      "required_posting_auths": [],
      "id": "ssc-mainnet-hive",
      "json": json
    ]
    broadcastActiveOperation(user: user, operation: ["custom_json", customParams], activeKey: activeKey, completion: completion, failure: failure)
  }

  /// Power up HIVE → HP (transfer_to_vesting, active key). `amount` is a HIVE amount (3dp string).
  func powerUpHive(user: String, to: String, amount: String, activeKey: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let params: [String: Any] = ["from": user, "to": to, "amount": "\(amount) HIVE"]
    broadcastActiveOperation(user: user, operation: ["transfer_to_vesting", params], activeKey: activeKey, completion: completion, failure: failure)
  }

  /// Power down HP → HIVE (withdraw_vesting, active key). `vests` is a VESTS amount (6dp string).
  func powerDownHive(user: String, vests: String, activeKey: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let params: [String: Any] = ["account": user, "vesting_shares": "\(vests) VESTS"]
    broadcastActiveOperation(user: user, operation: ["withdraw_vesting", params], activeKey: activeKey, completion: completion, failure: failure)
  }

  /// Read pending author/curation rewards for display before claiming.
  func getPendingRewards(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    guard let url = URL(string: ApiUrls.pendingRewards + "?user=\(username)") else { return }
    var request = URLRequest.init(url: url)
    request.addBasicHeaderFieldsForUpdateSettings()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  /// Claim pending rewards. Backend broadcasts with server-held authority; requires JWT (x-acti-token).
  func claimRewards(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    guard let url = URL(string: ApiUrls.claimRewards + "?user=\(username)") else { return }
    var request = URLRequest.init(url: url)
    request.addBroadCastHeaderWhenAfitSent()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  /// Hive transaction history via condenser_api.get_account_history.
  /// `start` = -1 for the most recent page, or (minSeq - 1) for older pages.
  func getHiveAccountHistory(username: String, start: Int, limit: Int = 1000, completion: APICompletionHandler, failure: APIFailureHandler) {
    guard let url = URL(string: ApiUrls.hiveRPCNode) else { return }
    let body: [String: Any] = [
      "jsonrpc": "2.0",
      "method": "condenser_api.get_account_history",
      "params": [username, start, limit],
      "id": 1
    ]
    var request = URLRequest.init(url: url)
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.appendBodyWith(json: body)
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure)
  }

  // MARK: - Phase 2: Gadget marketplace (Android port)

  private func simpleGet(urlString: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    guard let url = URL(string: urlString) else { return }
    var request = URLRequest.init(url: url)
    request.addBasicHeaderFieldsForUpdateSettings()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getMarketProducts(completion: APICompletionHandler, failure: APIFailureHandler) {
    simpleGet(urlString: ApiUrls.products, completion: completion, failure: failure)
  }

  func getNonConsumedGadgets(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    simpleGet(urlString: ApiUrls.nonConsumedGadgets + username, completion: completion, failure: failure)
  }

  func getConsumedGadgets(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    simpleGet(urlString: ApiUrls.consumedGadgets + username, completion: completion, failure: failure)
  }

  func getExchangeAfitPrice(completion: APICompletionHandler, failure: APIFailureHandler) {
    simpleGet(urlString: ApiUrls.exchangeAfitPrice, completion: completion, failure: failure)
  }

  /// Broadcasts an actifit gadget custom_json op (posting auth) via performTrx.
  /// `transaction` is one of "buy-gadget", "activate-gadget", "deactivate-gadget".
  func broadcastGadgetOperation(username: String, transaction: String, gadgetId: String, benefic: String?, completion: APICompletionHandler, failure: APIFailureHandler) {
    var jsonInner = "{\"transaction\": \"\(transaction)\" , \"gadget\": \"\(gadgetId)\""
    if let benefic = benefic, !benefic.isEmpty {
      jsonInner += " , \"benefic\": \"\(benefic)\""
    }
    jsonInner += "}"
    let parameters: [String: Any] = [
      "required_auths": [],
      "required_posting_auths": [username],
      "id": "actifit",
      "json": jsonInner
    ]
    let finalizedParams: [Any] = ["custom_json", parameters]
    var urlString = ApiUrls.broadCastQueryAPI + "?user=\(username)"
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: finalizedParams, options: [])
      guard let jsonString = String(data: jsonData, encoding: .utf8) else {
        failure?(NSError(domain: "Actifit", code: -1)); return
      }
      let cleaned = jsonString.replacingOccurrences(of: "\n", with: "")
      urlString += "&operation=[\(cleaned)]&bchain=HIVE"
      guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
            let url = URL(string: encoded) else { return }
      var request = URLRequest.init(url: url)
      request.addBroadCastHeaderWhenAfitSent()
      forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
    } catch let error {
      failure?(error as NSError)
    }
  }

  /// Buys a gadget with HIVE — transfer to actifit.market with memo (active key) via performTrxPost.
  func buyGadgetWithHive(username: String, gadgetId: String, priceHive: String, activeKey: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let params: [String: Any] = ["from": username, "to": ApiUrls.actifitMarketAccount, "amount": "\(priceHive) HIVE", "memo": "buy-gadget:\(gadgetId)"]
    let operation: [Any] = ["transfer", params]
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: [operation], options: [])
      guard let jsonString = String(data: jsonData, encoding: .utf8) else {
        failure?(NSError(domain: "Actifit", code: -1)); return
      }
      let cleaned = jsonString.replacingOccurrences(of: "\n", with: "")
      let finalParams: [String: Any] = ["operation": cleaned, "active": activeKey]
      guard let url = URL(string: ApiUrls.sendBalanceAndHive + "?user=\(username)&bchain=HIVE") else { return }
      var request = URLRequest.init(url: url)
      request.appendBodyWith(json: finalParams)
      request.addBroadCastHeaderWhenAfitSent()
      forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure)
    } catch let error {
      failure?(error as NSError)
    }
  }

  /// Confirmation GET after a gadget broadcast: {confirmBase}{user}/{id}/{refBlockNum}/{txId}/HIVE[/{benefic}]
  func confirmGadgetTransaction(confirmBase: String, username: String, gadgetId: String, refBlockNum: Int, txId: String, benefic: String?, completion: APICompletionHandler, failure: APIFailureHandler) {
    var urlString = confirmBase + "\(username)/\(gadgetId)/\(refBlockNum)/\(txId)/HIVE"
    if let benefic = benefic, !benefic.isEmpty {
      urlString += "/\(benefic)"
    }
    guard let encoded = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
          let url = URL(string: encoded) else { return }
    var request = URLRequest.init(url: url)
    request.addBroadCastHeaderWhenAfitSent()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func createWave(body: [String: Any], username: String, comment: String, completion: APICompletionHandler, failure: APIFailureHandler) {
   // let params: [String:Any] = ["id":1,"jsonrpc":"2.0","method": "comment", "params": body]
    let array: [Any] = [comment, body]
    var urlString = ApiUrls.broadCastQueryAPI + "?user=\(username)"
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: array, options: .prettyPrinted)
      if let jsonString = String(data: jsonData, encoding: .utf8) {
        print("Encoded JSON string: \(jsonString)")
        let cleanedJsonString = jsonString.replacingOccurrences(of: "\n", with: "")
        urlString = urlString + "&operation=[\(cleanedJsonString)]&bchain=HIVE"
        if let encodedString = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
          let url  = URL(string: encodedString)
          var request = URLRequest.init(url: url!)
          request.addBasicHeaderFieldsForUpdateSettings()
          forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
        }
      }
    }catch let error {
      print(error.localizedDescription)
    }

  }


  func getWavesContent(completion: APICompletionHandler, failure: APIFailureHandler) {
    let body: [String: Any] = [
      "sort": "posts",
      "account":"ecency.waves",
      "start_author":"",
      "start_permlink": "",
      "limit": 10,
      "observer": "",
    ]
    let params: [String:Any] = ["id":1,"jsonrpc":"2.0","method": "bridge.get_account_posts", "params": body]
    let url = URL(string: ApiUrls.hiveBlogURL)
    var request = URLRequest(url: url!)
    request.addBasicHeaderFields()
    request.appendBodyWith(json: params)
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure)
    //TODO: get the API
  }

  func loadComments(author: String, permlink: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let body: [String: Any] = [
      "author": author,
      "permlink": permlink
    ]

    let params: [String:Any] = ["id":1,"jsonrpc":"2.0","method": "condenser_api.get_content_replies","params": body]
    let url = URL(string: ApiUrls.hiveBlogURL)
    var request = URLRequest(url: url!)
    request.addBasicHeaderFields()
    request.appendBodyWith(json: params)
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure)
  }



  func getLastNotificationRead(userName: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: ApiUrls.notificationRead + userName)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFieldsForUpdateSettings()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getNotificationStats(completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: ApiUrls.notificationStats)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFieldsForUpdateSettings()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }


  func castSurveyVoice(userName: String, surveyId: String, option: String,completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: ApiUrls.castSurveyURL + "user=\(userName)&id=\(surveyId)&option=\(option)")
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFieldsForUpdateSettings()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func checkSurveyStatus(userName: String, surveyId: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: ApiUrls.surveyStatusURL + "user=\(userName)&id=\(surveyId)")
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getSurveys(completion: APICompletionHandler, failure: APIFailureHandler){
    let url = URL(string: ApiUrls.surveysURL)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getVideoTutorial(completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: ApiUrls.videoTutorial)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func registerNotification(info: [String:Any],completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: ApiUrls.registerPushNotification)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    request.appendBodyWith(json: info)
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_POST, completion: completion, failure: failure)
  }

  func getMarketExchangesAPI(completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: ApiUrls.getMarketExchange)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getReferrals(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: ApiUrls.getReferrals + username)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

//  func getProducts(completion: APICompletionHandler, failure: APIFailureHandler) {
//    let url = URL(string: ApiUrls.getProducts)
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//  }

//  func getActiveGadgetsByUser(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
//    let url = URL(string: ApiUrls.getActiveGadgetsByUser+username)
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//  }



//  func getDailyTips(completion: APICompletionHandler, failure: APIFailureHandler) {
//    let url = URL(string: ApiUrls.getDailyTips)
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//
//  }

//  func getAfitBalance(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
//    let url = URL(string: "\(ApiUrls.getAfitBalance)\(username)?fullbalance=1")
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//
//  }


  func getAccountData(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    let url = URL(string: "\(ApiUrls.getUserData)?user=\(username)")
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }


//  func getVotingStatus(completion: APICompletionHandler, failure: APIFailureHandler) {
//    let url = URL(string: ApiUrls.getVotingStatus)
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//  }
//
//  func getAllNotifications(completion: APICompletionHandler, failure: APIFailureHandler, username: String) {
//    let urlStr = "\(ApiUrls.getAllNotifications)\(username)"
//    let url =  URL(string: urlStr)
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//  }
//
//  func getNewsBanner(completion: APICompletionHandler, failure: APIFailureHandler) {
//    let urlStr = ApiUrls.getNewsBanner
//    let url =  URL(string: urlStr)
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//  }
//
//  func getLoginImage(completion: APICompletionHandler, failure : APIFailureHandler) {
//    let urlStr = "\(ApiUrls.loginImageURL)"
//    let url =  URL(string: urlStr)
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//  }

//  func getRCPercentage(completion: APICompletionHandler, failure : APIFailureHandler,username: String) {
//    let urlStr = "\(ApiUrls.getRCPercentageURL)\(username)"
//    let url =  URL(string: urlStr)
//    var request = URLRequest.init(url: url!)
//    request.addBasicHeaderFields()
//    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
//  }

  //MARK: API callers
  func getRank(username : String, completion : APICompletionHandler, failure : APIFailureHandler) {
    let urlStr = "\(ApiUrls.getRank)\(username)"
    let url = URL.init(string: urlStr)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }


  func getWalletBalanceWith(username : String, completion : APICompletionHandler, failure : APIFailureHandler) {
    let urlStr = ApiUrls.walletBalance + username
    let url = URL.init(string: urlStr)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getTransactions(username : String, completion : APICompletionHandler, failure : APIFailureHandler) {
    let urlStr = ApiUrls.transactions + username
    let url = URL.init(string: urlStr)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getCharities(completion : APICompletionHandler, failure : APIFailureHandler) {
    let urlStr = ApiUrls.charities
    let url = URL.init(string: urlStr)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getUserSettings(params: String, completion : APICompletionHandler, failure : APIFailureHandler) {
    let urlStr = "\(ApiUrls.getUserSetting)/" + "\(params)"
    let url = URL.init(string: urlStr)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func getNotifications(completion : APICompletionHandler, failure : APIFailureHandler) {
    let urlStr = ApiUrls.notificationType
    let url = URL.init(string: urlStr)
    var request = URLRequest.init(url: url!)
    request.addBasicHeaderFields()
    self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)
  }

  func updateUserSettings(username: String, settings: [String: Any], completion : APICompletionHandler, failure : APIFailureHandler) {


    do {
      let data1 =  try JSONSerialization.data(withJSONObject: settings, options: JSONSerialization.WritingOptions.prettyPrinted) // first of all convert json to the data
      let convertedString = String(data: data1, encoding: .utf8) // the data will be converted to the string
      print(convertedString!) // <-- here is ur string
      let urlEncodedJson = convertedString!.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)


      let urlStr = "\(ApiUrls.updateUserSetting)/?user=" + "\(username)&settings=" + "\(urlEncodedJson!)"
      let url = URL.init(string: urlStr)
      var request = URLRequest.init(url: url!)
      request.addBasicHeaderFieldsForUpdateSettings()
      self.forwardRequest(request: request, httpMethod: HttpMethods.HttpMethod_GET, completion: completion, failure: failure)

    } catch let myJSONError {
      print(myJSONError)
    }
  }

  //MARK: Dispatching Request to server

  func forwardRequest(request : URLRequest, httpMethod : String, completion : APICompletionHandler, failure : APIFailureHandler, handleCookies: Bool = false) {
    var statusCode: Int? = nil
    var sendRequest:URLRequest = request
    
    sendRequest.httpMethod = httpMethod as String

    sendRequest.httpShouldHandleCookies = handleCookies
    var session = URLSession.shared
    if handleCookies {
    let configs = URLSessionConfiguration.default
      configs.httpCookieStorage = HTTPCookieStorage.shared
      sendRequest.timeoutInterval = 15.0
      session = URLSession(configuration: configs)
    }


    let task = session.dataTask(with: sendRequest, completionHandler: { data, response, error in
      if let httpResponse = response as? HTTPURLResponse {
        statusCode = httpResponse.statusCode
        print(httpResponse.statusCode)
        // Use the statusCode as needed
      }
      if error == nil{
        if let data = data {
#if DEBUG
          print("Response json Data is \(data)")
#endif
          //use library to extract data from response json
          if let string = String.init(data: data, encoding: String.Encoding.utf8) {
            // do {

            completion!(string, statusCode)
            //} catch {
            //}
          } else {
            completion!(nil,statusCode)
          }
        } else {
          completion!(nil,statusCode)
        }
      } else{
        if let failure = failure {
          failure(error! as NSError )
        }
      }

    })
    task.resume()
  }
}

extension URLRequest {
  mutating func addBasicHeaderFields() {
    self.setValue("application/json", forHTTPHeaderField: "Content-Type")
    // self.setValue("application/json", forHTTPHeaderField: "Accept")
  }
  mutating func addBasicHeaderFieldsForUpdateSettings() {//TODO: remove this
    self.setValue("application/json", forHTTPHeaderField: "Content-Type")
    self.setValue("Bearer \(UserDefaults.standard.authToken)", forHTTPHeaderField: "Authorization")
  }

  mutating func addBroadCastHeaderWhenAfitSent() {
    self.setValue("application/json", forHTTPHeaderField: "Content-Type")
    self.setValue("Bearer \(UserDefaults.standard.authToken)", forHTTPHeaderField: "x-acti-token")
  }

  mutating func addThreeSpeakHeaders(token: String) {
    self.setValue("application/json", forHTTPHeaderField: "Content-Type")
    self.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
  }

  mutating func appendBodyWith(json : [String : Any]) {
    do {
      self.httpBody = try JSONSerialization.data(withJSONObject: json, options:[])
    } catch _{}
  }
}


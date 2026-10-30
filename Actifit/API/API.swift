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


  /// Decrypts 3Speak's login memo with the posting key on the device (the backend's /memoDecode
  /// was removed with server-side key handling). Answers in the shape the caller already reads.
  func verifyActifit3SpeakVideoMemo(username: String,body: [String: Any], completion: APICompletionHandler, failure: APIFailureHandler) {
    let memo = body["memo"] as? String ?? ""
    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let token = try HiveCrypto.decodeMemo(memo, wif: HiveBroadcaster.storedPostingKey)
        let json = "{\"xcstkn\":" + HiveJSON.string(token) + "}"
        DispatchQueue.main.async { completion?(json, 200) }
      } catch {
        DispatchQueue.main.async {
          failure?(NSError(domain: "Actifit", code: -1, userInfo: [NSLocalizedDescriptionKey: HiveText.noPostingKey]))
        }
      }
    }
  }

  func grab3SpeakCookie(username: String, token: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    // The token comes from a memo decoded on the device: encode it, and never crash on odd input.
    guard let url = URL(string: "https://studio.3speak.tv/mobile/login?username=\(HiveURL.component(username))&access_token=\(HiveURL.component(token))") else {
      failure?(NSError(domain: "Actifit", code: -1, userInfo: [NSLocalizedDescriptionKey: HiveText.generic]))
      return
    }
    let request = URLRequest.init(url: url)
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
    let op = HiveOp.transfer(from: from, to: to, amount: HiveAmount.normalize(amount), memo: memo ?? "")
    signAndBroadcast([op], role: .active, key: activeKey, completion: completion, failure: failure)
  }

  // MARK: - On-device signing

  /// Signs `ops` on the device and broadcasts them to Hive (the backend no longer signs: its
  /// /performTrx and /performTrxPost are gone). Success is reported in the shape callers already
  /// read, {"success":true,"trx":{"tx":{"id","ref_block_num"}}}; a failure carries a message fit
  /// to show. The key never leaves the phone.
  func signAndBroadcast(_ ops: [HiveOp], role: HiveBroadcaster.KeyRole, key: String? = nil, completion: APICompletionHandler, failure: APIFailureHandler) {
    HiveBroadcaster.broadcast(ops, role: role, explicitKey: key) { r in
      if r.ok {
        completion?("{\"success\":true,\"trx\":{\"tx\":{\"id\":" + HiveJSON.string(r.txId ?? "")
                    + ",\"ref_block_num\":\(r.refBlockNum)}}}", 200)
      } else {
        failure?(NSError(domain: "Actifit", code: -1, userInfo: [NSLocalizedDescriptionKey: r.error ?? HiveText.generic]))
      }
    }
  }

  // MARK: - Phase 1: Wallet parity (Android port)

  /// Active-key operation `[opName, params]`, signed on the device.
  private func broadcastActiveOperation(user: String, operation: [Any], activeKey: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    guard operation.count == 2, let name = operation[0] as? String, let params = operation[1] as? [String: Any],
          let op = try? HiveOp.from(name: name, params: params) else {
      failure?(NSError(domain: "Actifit", code: -1, userInfo: [NSLocalizedDescriptionKey: HiveText.generic]))
      return
    }
    signAndBroadcast([op], role: .active, key: activeKey, completion: completion, failure: failure)
  }

  /// Send an arbitrary Hive-Engine token (transfer / stake / unstake) via custom_json (active key).
  /// `action` is one of "transfer", "stake", "unstake".
  func hiveEngineTokenOperation(user: String, symbol: String, to: String, quantity: String, memo: String, action: String, activeKey: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    // Escaped field by field: a memo with a quote in it must not break the JSON.
    let j = HiveJSON.string
    let json = "{\"contractName\":\"tokens\",\"contractAction\":" + j(action) + ",\"contractPayload\":{\"symbol\":"
      + j(symbol) + ",\"to\":" + j(to) + ",\"quantity\":" + j(quantity)
      + ",\"memo\":" + j(memo) + "}}"
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

  /// Claims pending rewards: signed on the device with the posting key (the backend's
  /// /claimRewards is gone). Answers in the shape the caller already reads, {"hive":{"success"}}.
  func claimRewards(username: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    HiveBroadcaster.claimRewards(account: username.byTrimming(string: "@").lowercased()) { r in
      if r.ok && r.txId == nil {
        failure?(NSError(domain: "Actifit", code: 0, userInfo: [NSLocalizedDescriptionKey:
          Copy.text("rewards_nothing_to_claim", "You have no rewards to claim right now.")]))
      } else if r.ok {
        completion?("{\"hive\":{\"success\":true}}", 200)
      } else {
        failure?(NSError(domain: "Actifit", code: -1, userInfo: [NSLocalizedDescriptionKey: r.error ?? HiveText.generic]))
      }
    }
  }

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

  /// Latest X/Twitter posts for the dashboard news carousel.
  func getLatestXPost(completion: APICompletionHandler, failure: APIFailureHandler) {
    simpleGet(urlString: ApiUrls.latestXPost, completion: completion, failure: failure)
  }

  /// Server-computed estimated AFIT reward for today's step count.
  func getEstimatedReward(username: String, steps: Int, completion: APICompletionHandler, failure: APIFailureHandler) {
    var urlStr = ApiUrls.estimatedReward + "?user=\(username)"
    if steps > 0 { urlStr += "&steps=\(steps)" }
    simpleGet(urlString: urlStr, completion: completion, failure: failure)
  }

  /// A comment (wave, snap, reply) or vote: `comment` is the op name, `body` its params. Signed
  /// on the device with the posting key.
  func createWave(body: [String: Any], username: String, comment: String, completion: APICompletionHandler, failure: APIFailureHandler) {
    guard let op = try? HiveOp.from(name: comment, params: body) else {
      failure?(NSError(domain: "Actifit", code: -1, userInfo: [NSLocalizedDescriptionKey: HiveText.generic]))
      return
    }
    signAndBroadcast([op], role: .posting, completion: completion, failure: failure)
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


  func getTrackedActivity(username : String, completion : APICompletionHandler, failure : APIFailureHandler) {
    let urlStr = "\(ApiUrls.trackedActivity)\(username)"
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
            // A session the backend dropped (another device logged in, or it aged out) answers
            // 200 {success:false}: log in again quietly so the next call works.
            TokenManager.shared.noteReply(data)
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


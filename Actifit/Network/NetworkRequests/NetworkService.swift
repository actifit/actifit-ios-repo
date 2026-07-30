//
//  NetworkService.swift
//  Actifit
//
//  Created by Ali Jaber on 10/06/2024.
//

import Foundation
protocol MyAppServiceProtocols {
  func loginAPI(username: String, ppKey: String) async -> Result<NewUserModel, RequestError>
  func getLoginBannerImage() async -> Result<LoginBanner, RequestError>
  func getBanners() async -> Result <[BannerImageModel], RequestError>
  func getSurveys() async -> Result<[SurveyModel], RequestError>
  func getVotingStatus() async -> Result<VotingStatusModel,RequestError>
  func getRCPPercentage() async -> Result <RCPercentage, RequestError>
  func getAccountData(username: String) async -> Result <BlurtObject,RequestError>
  func getAfitBalance(username: String) async -> Result <AfitTokenModel,RequestError>
  func getDailyTips() async -> Result <[DailyTipsModel],RequestError>
  func getProducts() async -> Result <[Product],RequestError>
  func getActiveGadgetsForUser(username: String) async -> Result <ActiveGadgeByUserResponse,RequestError>
  func getSurveyStatus(username: String, surveyId: String) async -> Result<SurveyStatusModel,RequestError>
  func getNotificationsRead(username: String) async -> Result<[[ReadChatNotification]], RequestError>
  func getNotifications(username: String) async -> Result<[NotificationModel], RequestError>
  func getChainInfo() async -> Result <BlockchainInfoResponse, RequestError>
  func getHiveEngineToken(username: String, tableType: TableType) async -> Result <AllHiveEngineTokensResponse, RequestError>
  func getHiveEngineBalance(username: String, tableType: TableType) async -> Result <HiveEngineBalanceResponse, RequestError>
  func createWave(username: String, body: [String: Any], comment: String) async -> Result<CreateWaveModel, RequestError>
  func getWave() async -> Result<HivePosts, RequestError>
  func getSnaps() async -> Result<HivePosts, RequestError>
  func getLeoThreads() async -> Result<HivePosts, RequestError>
  func getUserPosts(username: String) async -> Result<HiveUserPosts, RequestError>
  func postActivity(body: [String:Any]) async -> Result<PostActivityModel, RequestError>
  func dailyLeaderboard() async -> Result<[LeaderboardModel], RequestError>
  func getSocialPosts(author: String?, permlink: String?) async -> Result<SocialPostModel, RequestError>
  func getComments(author: String, permlink: String) async -> Result<HivePostComment, RequestError>
  func getPostRewards(user: String, reportURL: String) async -> Result<PostReward, RequestError>
}

extension HTTPClient: MyAppServiceProtocols {
    func getPostRewards(user: String, reportURL: String) async -> Result<PostReward, RequestError> {
        return await sendRequest(endpoint: GetPostRewardEndPoint.getPostRewardEndPoint(user: user, reportURL: reportURL), responseModel: PostReward.self)
    }
    
    func getComments(author: String, permlink: String) async -> Result<HivePostComment, RequestError> {
        return await sendRequest(endpoint: PostCommentEndPoint.postComment(author: author, permlink: permlink), responseModel: HivePostComment.self)
    }
    
    func getSocialPosts(author: String? = nil, permlink: String? = nil) async -> Result<SocialPostModel, RequestError> {
      return await sendRequest(endpoint: GetWavesEndPoint.getSocialPosts(author: author, permlink: permlink), responseModel: SocialPostModel.self)
  }
    
  func dailyLeaderboard() async -> Result<[LeaderboardModel], RequestError> {
      return await sendRequest(endpoint: LeaderboardEndPoint.leaderboardEndpoint, responseModel: [LeaderboardModel].self)
  }

  func postActivity(body: [String : Any]) async -> Result<PostActivityModel, RequestError> {
    return await sendRequest(endpoint: PostActivityEndPoint.postReport(body: body), responseModel: PostActivityModel.self)
  }
  

  func getAccountData(username: String) async -> Result<BlurtObject, RequestError> {
    return await sendRequest(endpoint: AccountDataEndPoint.accountData(username: username), responseModel: BlurtObject.self)
  }
  
  func getActiveGadgetsForUser(username: String) async -> Result<ActiveGadgeByUserResponse, RequestError> {
    return await sendRequest(endpoint: ActiveGadgetsForUserEndPoint.activeGadgets(username: username), responseModel: ActiveGadgeByUserResponse.self)
  }

  
  func getAfitBalance(username: String) async -> Result<AfitTokenModel, RequestError> {
    return await sendRequest(endpoint: AfitBalanceEndPoint.afitBalance(username: username), responseModel: AfitTokenModel.self)
  }
  
  func getDailyTips() async -> Result<[DailyTipsModel], RequestError> {
    return await sendRequest(endpoint: DailyTipsEndPoint.dailyTips, responseModel: [DailyTipsModel].self)
  }
  
  func getProducts() async -> Result<[Product], RequestError> {
    return await sendRequest(endpoint: GetProductsEndPoint.products, responseModel: [Product].self)
  }
  
  func getSurveyStatus(username: String, surveyId: String) async -> Result<SurveyStatusModel, RequestError> {
    return await sendRequest(endpoint: SurveyStatusEndPoint.surveyStatus(username: username, surveyId: surveyId), responseModel: SurveyStatusModel.self)
  }
  
  func getNotificationsRead(username: String) async -> Result<[[ReadChatNotification]], RequestError> {
    return await sendRequest(endpoint: NotificationsReadEndPoint.notificationsRead(username: username), responseModel: [[ReadChatNotification]].self)
  }
  
  func getRCPPercentage() async -> Result<RCPercentage, RequestError> {
    return await sendRequest(endpoint: RCPPercentageEndPoint.rcpPercentage, responseModel: RCPercentage.self)
  }
  
  func getVotingStatus() async -> Result<VotingStatusModel, RequestError> {
    return await sendRequest(endpoint: VotingStatusEndPoint.votingStatus, responseModel: VotingStatusModel.self)
  }
  
  func getSurveys() async -> Result<[SurveyModel], RequestError> {
    return await sendRequest(endpoint: SurveysEndPoint.surver, responseModel: [SurveyModel].self)
  }

  func getBanners() async -> Result<[BannerImageModel], RequestError> {
    return await sendRequest(endpoint: BannersEndPoint.banner, responseModel: [BannerImageModel].self)
  }

  func getLoginBannerImage() async -> Result<LoginBanner, RequestError> {
    return await sendRequest(endpoint: LoginBannerEndPoint.loginBanner, responseModel: LoginBanner.self)
  }


  func loginAPI(username: String, ppKey: String) async -> Result<NewUserModel, RequestError> {
    return await sendRequest(endpoint: LoginEndpoint.login(username: username, ppKey: ppKey), responseModel: NewUserModel.self)
  }

  func translate(content: String) async -> Result<TranslatedContentModel, RequestError> {
    return await sendRequest(endpoint: TranslationEndPoint.translate(content: content), responseModel: TranslatedContentModel.self)
  }

  func getNotifications(username: String) async -> Result<[NotificationModel], RequestError> {
    return await sendRequest(endpoint: NotificationsEndPoint.getNotifications(username: username), responseModel: [NotificationModel].self)
  }

  func getChainInfo() async -> Result<BlockchainInfoResponse, RequestError> {
    return await sendRequest(endpoint: ChainInfoEndPoint.getChainInfo, responseModel: BlockchainInfoResponse.self)
  }

  func getHiveEngineToken(username: String, tableType: TableType) async -> Result<AllHiveEngineTokensResponse, RequestError> {
    return await sendRequest(endpoint: HiveEngineEndPoint.hiveEngine(username: username, tableType: tableType), responseModel: AllHiveEngineTokensResponse.self)
  }

  func getHiveEngineBalance(username: String, tableType: TableType) async -> Result<HiveEngineBalanceResponse, RequestError> {
    return await sendRequest(endpoint: HiveEngineEndPoint.hiveEngine(username: username, tableType: tableType), responseModel: HiveEngineBalanceResponse.self)
  }

  func createWave(username: String, body: [String : Any], comment: String) async -> Result<CreateWaveModel, RequestError> {
    return await sendRequest(endpoint: CreateWaveEndPoint.createWave(username: username, comment: comment, params: body), responseModel: CreateWaveModel.self)
  }

  func getWave() async -> Result<HivePosts, RequestError> {
    return await sendRequest(endpoint: GetWavesEndPoint.getWaves, responseModel: HivePosts.self)
  }

  func getUserPosts(username: String) async -> Result<HiveUserPosts, RequestError> {
    return await sendRequest(endpoint: GetWavesEndPoint.getPosts(username: username), responseModel: HiveUserPosts.self)
  }

    func getSnaps() async -> Result<HivePosts, RequestError> {
        return await sendRequest(endpoint: GetSnapsEndPoint.getSnaps, responseModel: HivePosts.self)
    }

    func getLeoThreads() async -> Result<HivePosts, RequestError> {
        return await sendRequest(endpoint: GetSnapsEndPoint.getLeoThreads, responseModel: HivePosts.self)
    }

}

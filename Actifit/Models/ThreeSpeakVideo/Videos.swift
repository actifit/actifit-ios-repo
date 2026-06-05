//
//  Videos.swift
//  Actifit
//
//  Created by Ali Jaber on 19/05/2024.
//

import Foundation

struct Beneficiary: Codable {
  let account: String
  let weight: Int
  let src: String?
}
struct Video: Codable, Equatable {
    let id: String?
    let updateSteem: Bool?
    let status: String?
   // let encodingPriceSteem: String?
  //  let encodingProgress: Int?
    let created: String?
   // let declineRewards: Bool?
  //  let rewardPowerup: Bool?
   // let category: String?
  //  let firstUpload: Bool?
  //  let community: String?
   // let views: Int?
   // let hive: String?
   // let upvoteEligible: Bool?
   // let publishType: String?
    let beneficiaries: String?
   // let votePercent: Int?
   // let reducedUpvote: Bool?
   // let postToHiveBlog: Bool?
   // let fromMobile: Bool?
   // let isReel: Bool?
    let originalFilename: String?
    let permlink: String?
    let duration: Double?
    let size: Double?
   // let owner: String?
    //let uploadType: String?
    let title: String?
    let description: String?
    let localFilename: String?
    let thumbnail: String?
  //  let app: String?
    let filename: String?
    let videoV2: String?
   // let publishFailed: Bool?
   // let recommended: Bool?
    let thumbUrl: String?
    //let visibleStatus: String?

  func extractBeneficiaries() -> [Beneficiary]? {
    guard let beneficiariesString = self.beneficiaries,
          let jsonData = beneficiariesString.data(using: .utf8) else {
      return nil
    }

    do {
      let decoder = JSONDecoder()
      return try decoder.decode([Beneficiary].self, from: jsonData)
    } catch {
      print("Error decoding beneficiaries:", error)
      return nil
    }
  }

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case updateSteem
        //case lowRc
        //case needsBlockchainUpdate
        case status
       // case encodingPriceSteem = "encoding_price_steem"
        //case paid
       // case encodingProgress
        case created
        //case is3CJContent
        //case isVOD

        //case isNsfwContent
     //   case declineRewards
     //   case rewardPowerup
        //case language
       // case category
      //  case firstUpload
       // case community
       // case indexed
        //case views
       // case hive

       // case upvoteEligible
        //case publishType = "publish_type"
        case beneficiaries
       // case votePercent
       // case reducedUpvote
        //case donations
      // case postToHiveBlog
//        case tagsV2 = "tags_v2"
      //  case fromMobile
       // case isReel

        case originalFilename
        case permlink
        case duration
        case size
       // case owner
        //case uploadType = "upload_type"
        case title
        case description
        case localFilename = "local_filename"
        case thumbnail
       // case app
        //case v = "__v"
        case filename
        //case jobId = "job_id"
        case videoV2 = "video_v2"
        //case badges
        //case curationComplete
       // case hasAudioOnlyVersion
      //  case hasTorrent
       // case isB2
      //  case pinned
       // case publishFailed
        //case recommended
       // case score
        case thumbUrl
       // case visibleStatus = "visible_status"
    }
}


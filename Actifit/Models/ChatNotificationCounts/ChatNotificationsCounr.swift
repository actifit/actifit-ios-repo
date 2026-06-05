//
//  ChatNotificationsCounr.swift
//  Actifit
//
//  Created by Ali Jaber on 14/10/2023.
//

import Foundation
struct ChatNotificationCount: Codable {
    let hiveCommunity: Int?
    enum CodingKeys: String, CodingKey {
        case hiveCommunity = "hive-193552"
    }
}


//struct HiveData: Codable {
//    let hive193552: Int
//}
//
//func extractHiveData(from response: Any) -> [HiveData]? {
//    guard let responseArray = response as? [Any], responseArray.count > 1,
//          let nestedArray = responseArray[1] as? [[String: Int]] else {
//        return nil
//    }
//
//    var hiveDataList: [HiveData] = []
//    for dict in nestedArray {
//        if let value = dict["hive-193552"] {
//            hiveDataList.append(HiveData(hive193552: value))
//        }
//    }
//    return hiveDataList
//}

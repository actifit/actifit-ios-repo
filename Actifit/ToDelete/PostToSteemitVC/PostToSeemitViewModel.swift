//
//  PostToSeemitViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 29/05/2024.
//

import Foundation
class PostToSeemitViewModel {

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


extension UserDefaults {
    // Save a dictionary to UserDefaults
    func set3SepakVideo(dictionary: [String: Any], forKey key: String = "3speak") {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: dictionary, requiringSecureCoding: false)
            set(data, forKey: key)
        } catch {
            print("Failed to archive dictionary: \(error)")
        }
    }

    // Retrieve a dictionary from UserDefaults
    func get3SpeakVideodictionary(forKey key: String = "3speak") -> [String: Any]? {
        guard let data = data(forKey: key) else {
            return nil
        }
        do {
            if let dictionary = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSDictionary.self, NSArray.self, NSString.self, NSNumber.self], from: data) as? [String: Any] {
                return dictionary
            }
        } catch {
            print("Failed to unarchive dictionary: \(error)")
        }
        return nil
    }

    // Clear the dictionary for the given key
    func clear(forKey key: String = "3speak") {
        removeObject(forKey: key)
    }
}

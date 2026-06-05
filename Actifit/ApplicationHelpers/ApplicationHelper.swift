//
//  ApplicationHelper.swift
//  Actifit
//
//  Created by Ali Jaber on 16/08/2023.
//

import Foundation
import UIKit
class ApplicationHelper {

  static let hiveComunity = "hive-193552"
  static func generateAndFindMin(minValue: Double, maxValue: Double) -> Double {
    var randomValues: [Double] = []
    for _ in 1...5 {
      let randomValue = Double.random(in: minValue...maxValue)
      randomValues.append(randomValue)
    }
    let minRandomValue = randomValues.min() ?? 0.0
    return truncateToThreeDecimalPlaces(minRandomValue)
    //return minRandomValue
  }

  static func truncateToThreeDecimalPlaces(_ value: Double) -> Double {
    return floor(value * 1000) / 1000
  }

  static func generateImageFromUnicode(unicode: Int) -> UIImage? {


    // Create a UIImage from the Unicode value
    if let emojiImage = imageFromUnicode(unicode) {
      return emojiImage
    }
    return nil
  }

  private static func imageFromUnicode(_ unicodeValue: Int) -> UIImage? {
    // Create a string from the Unicode value
    let unicodeString = String(UnicodeScalar(unicodeValue)!)

    // Create an attributed string with the Unicode string
    let attributes: [NSAttributedString.Key: Any] = [
      .font: UIFont.systemFont(ofSize: 50),
      .foregroundColor:  UIColor.primaryGreenColor()

    ]
    let attributedString = NSAttributedString(string: unicodeString, attributes: attributes)

    // Get an image from the attributed string
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 50, height: 50), false, 0.0)
    attributedString.draw(at: .zero)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return image
  }

  static func getSocialMedialURLByTag(tag: Int) -> URL? {
    switch tag {
    case 1: return URL(string: "https://www.facebook.com/Actifit.fitness")!
    case 2: return URL(string: "https://www.twitter.com/Actifit_fitness")!
    case 3: return URL(string: "https://links.actifit.io/discord")!
    case 4: return URL(string: "https://t.me/actifit")!
    case 5: return URL(string: "https://www.youtube.com/c/Actifitfitness")!
    case 6: return URL(string: "https://www.instagram.com/actifit.fitness")!
    case 7: return URL(string: "https://www.linkedin.com/company/actifit-io")!
    default: return nil
    }
  }

  var getAppStoreURL: URL {

    return URL(string: "itms-apps://apps.apple.com/app/\(1433969051)")!

  }

  static var appVersion: String? {
    if let info = Bundle.main.infoDictionary, let currentVersion = info["CFBundleShortVersionString"] as? String {
      return currentVersion
    }
    return nil
  }

  static func isUpdateAvailable() async -> Bool {
    guard let info = Bundle.main.infoDictionary,
          let currentVersion = info["CFBundleShortVersionString"] as? String,
          let identifier = info["CFBundleIdentifier"] as? String,
          let url = URL(string: "http://itunes.apple.com/lookup?bundleId=\(identifier)") else {
      return false
    }

    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let results = json["results"] as? [[String: Any]],
            let latestVersion = results.first?["version"] as? String else {
        return false
      }
      return latestVersion > currentVersion
    } catch {
      print("Error checking for app update: \(error)")
      return false
    }
  }


  func fetchUserImage(finalUsername: String) async -> UIImage? {
      let strImageUrl = "https://images.hive.blog/u/" + finalUsername + "/avatar"

      guard let imageURL = URL(string: strImageUrl) else {
          return nil
      }

      do {
          let (data, _) = try await URLSession.shared.data(from: imageURL)
          return UIImage(data: data)
      } catch {
          return nil
      }
  }

//  func uploadData(image:UIImage) {
//
//    let data: Data =  UIImageJPEGRepresentation(image, 0.7)! //Data() //UIImageJPEGRepresentation(image, 1)!
//    if data.count > 5 * 1024 * 1024 * 1024 {
//
//      return
//    }
//    let deviceUUID: String = (UIDevice.current.identifierForVendor?.uuidString)!
//    let filename = deviceUUID + String(Date().ticks)
//    print("file -\(filename)")
//
//    let expression = AWSS3TransferUtilityMultiPartUploadExpression()
//    expression.progressBlock = {(task, progress) in
//      print(progress)
//      DispatchQueue.main.async(execute: {
//        print(progress)
//      })
//    }
//
//    var completionHandler: AWSS3TransferUtilityMultiPartUploadCompletionHandlerBlock
//    completionHandler = { (task, error) -> Void in
//
//      DispatchQueue.main.async(execute: {
//        var imgUrl = "![](https://usermedia.actifit.io/\(filename))"
//        imgUrl = imgUrl.replacingOccurrences(of: "io//", with: "io/")
//      
//      })
//    }
//
//    let transferUtility = AWSS3TransferUtility.default()
//    transferUtility.uploadUsingMultiPart(data:data,
//                                         bucket: "actifit",
//                                         key:filename,
//                                         contentType: "image/jpeg",
//                                         expression: expression,
//                                         completionHandler: completionHandler).continueWith {
//      (task) -> AnyObject? in
//      if let error = task.error {
//        print("Error: \(error.localizedDescription)")
//      }
//
//      if let _ = task.result {
//        print(task.result?.status as Any)
//
//      }
//      return nil;
//    }
//  }

}

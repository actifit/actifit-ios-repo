//
//  File.swift
//  Actifit
//
//  Created by Deepak Bansal on 11/07/19.
//

import Foundation
import UIKit
extension UIApplication {
    static var appVersion: String? {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
    }
}

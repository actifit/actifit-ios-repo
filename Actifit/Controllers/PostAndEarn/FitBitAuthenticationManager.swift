//
//  AuthenticationManager.swift
//  Actifit
//
//  Created by Ali Jaber on 17/07/2024.
//

import SwiftUI
import SafariServices
import Combine

class FitBitAuthenticationManager: NSObject, ObservableObject, SFSafariViewControllerDelegate {
    @Published var isAuthorized = false
    @Published var showSafari = false
    @Published var authenticationToken: String?
    @Published var fitBitUserId: String?

    private var safariViewController: SFSafariViewController?

    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(handleNotification(_:)), name: NSNotification.Name(rawValue: "ACTIFIT"), object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func login() {
      isAuthorized = false
        guard let url = URL(string: "https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=" + AppCenter.clientID + "&redirect_uri=" + AppCenter.redirectURI + "&scope=" + AppCenter.defaultScope + "&expires_in=604800") else {
            NSLog("Unable to create authentication URL")
            return
        }

        safariViewController = SFSafariViewController(url: url)
        safariViewController?.delegate = self
        showSafari = true
    }

    @objc private func handleNotification(_ notification: Notification) {
        let success: Bool
        if let token = FitBitAuthenticationManager.extractToken(notification, key: "actifitcb://fitbitcallback#access_token") {
            self.authenticationToken = token
            self.fitBitUserId = FitBitAuthenticationManager.extractToken(notification, key: "user_id")

            NSLog("You have successfully authorized")
            success = true
        } else {
            print("There was an error extracting the access token from the authentication response.")
            success = false
        }

        DispatchQueue.main.async {
            self.safariViewController?.dismiss(animated: true) {
                self.isAuthorized = success
                self.showSafari = false
            }
        }
    }

    private static func extractToken(_ notification: Notification, key: String) -> String? {
        guard let url = notification.userInfo?[UIApplication.LaunchOptionsKey.url] as? URL else {
            NSLog("notification did not contain launch options key with URL")
            return nil
        }

        let strippedURL = url.absoluteString.replacingOccurrences(of: AppCenter.redirectURI, with: "")
        return parametersFromQueryString(strippedURL)[key]
    }

    private static func parametersFromQueryString(_ queryString: String?) -> [String: String] {
        var parameters = [String: String]()
        if let queryString = queryString {
            let parameterScanner: Scanner = Scanner(string: queryString)
            var name: NSString? = nil
            var value: NSString? = nil
            while !parameterScanner.isAtEnd {
                name = nil
                parameterScanner.scanUpTo("=", into: &name)
                parameterScanner.scanString("=", into: nil)
                value = nil
                parameterScanner.scanUpTo("&", into: &value)
                parameterScanner.scanString("&", into: nil)
                if let name = name, let value = value {
                    parameters[name.removingPercentEncoding!] = value.removingPercentEncoding!
                }
            }
        }
        return parameters
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        isAuthorized = false
        showSafari = false
    }
}

//
//  ChatViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 04/10/2023.
//

import UIKit
import WebKit

class ChatViewController: UIViewController {
    
    @IBOutlet weak var infoPopupBtn: UIButton!
    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var backgroundLayer: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        infoPopupBtn.setImage(UIImage(named: "exclamation-icon")?.withTintColor(.primaryRedColor()), for: .normal)
        webView.navigationDelegate = self
        if let htmlFileURL = Bundle.main.url(forResource: "chatHTML", withExtension: "html") {
//
            webView.configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        //    DispatchQueue.main.async {
                self.webView.load(URLRequest(url: URL(string: htmlFileURL.absoluteString)!))
           
                }
        UserDefaults.standard.lastChatDateDisplay = Date().getTodaysDateYearAndMonthAndDay()
        updateNotificationCounter()
        closeBtn.layer.cornerRadius = 5
        closeBtn.clipsToBounds = true
        backgroundLayer.layer.cornerRadius = 5
        backgroundLayer.clipsToBounds = true
        infoPopupBtn.transform =  CGAffineTransform(rotationAngle: .pi)

    }
    
    private func updateNotificationCounter() {
//            API().getNotificationStats { info, statusCode in
//                if let response = info as? String {
//                    let data = response.utf8Data()
//                    do {
//                        if var jsonArray = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] {
//                            jsonArray?.removeFirst()
//                            if var list = jsonArray?.first as? [Any] {
//                                if list.count > 1 {
//                                    list.removeLast()
//                                }
//                                if let jsonData = try? JSONSerialization.data(withJSONObject: list.first, options: []),
//                                let decodedArray = try? JSONDecoder().decode([ChatNotificationCount].self, from: jsonData) {
//                                    let reversedNotifications = Array(decodedArray.reversed())
//                                    for i in 0...reversedNotifications.count - 1 {
//                                        if reversedNotifications[i].hiveCommunity != nil && (reversedNotifications[i].hiveCommunity ?? 0) > 0 {
//                                            UserDefaults.standard.lastNotificationCount = reversedNotifications[i].hiveCommunity!
//                                            return
//                                        }
//                                    }
//                                }
//                            }
//                         
//                        }
//                    }
//                }
//            } failure: { error in
//                
//            }

        }
        
    
    
    @IBAction func closeBtnTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    

    @IBAction func infoPopupTapped(_ sender: Any) {
        let vc = TransparentPopupViewController.create(title: NSLocalizedString("chitchat", comment: ""), description: NSLocalizedString("chat_with_other", comment: ""), cancelButtonText: NSLocalizedString("close_upper", comment: ""), noteSize: .small)
        self.present(vc, animated: true)
    }
    

}


extension ChatViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
  
        if let user = User.current()?.steemit_username, let privateKey = User.current()?.private_posting_key {
            let setUserScript = "setUser('\(user)');"
            webView.evaluateJavaScript(setUserScript) { (result, error) in
                if let error = error {
                    print("Error calling setUser: \(error)")
                } else {
                    print("setUser function called successfully")
                }
            }
            let setPstingKeyScript = "setPstingKey('\(privateKey)');"
            webView.evaluateJavaScript(setPstingKeyScript) { (result, error) in
                if let error = error {
                    print("Error calling setPstingKey: \(error)")
                } else {
                    print("setPstingKey function called successfully")
                }
            }
        }
    }
}

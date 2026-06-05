//
//  ReferralsPopupViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 28/08/2023.
//

import UIKit
import Down
import WebKit

class ReferralsPopupViewController: UIViewController {
    var referralsList: [ReferralObject] = []
    @IBOutlet weak var referralsCountLabel: UILabel!
    @IBOutlet weak var checkMarkImageView: UIImageView!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var copyBtn: UIButton!
    @IBOutlet weak var fullReferralLinkLabel: UILabel!
    @IBOutlet weak var referralLinkLabel: UILabel!
    @IBOutlet weak var sucessfulReferralsLabel: UILabel!
    var reportView: ReportPreView!
    @IBOutlet weak var referralView: UIView!

    @IBOutlet weak var titleLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        updateMarkDownView()
        setUI()
        getReferrals()
        
        // Do any additional setup after loading the view.
    }
    
    static func create() ->ReferralsPopupViewController {
        let vc = UIStoryboard(name: "ReferralsPopup", bundle: nil).instantiateViewController(withIdentifier: "ReferralsPopupViewController") as! ReferralsPopupViewController
        vc.modalPresentationStyle = .overFullScreen
        return vc
    }
    
    func getReferrals() {
        if let userName = User.current()?.steemit_username {
            API().getReferrals(username: userName) { info, statusCode in
                if let response = info as? String {
                    let data = response.utf8Data()
                    let decoder = JSONDecoder()
                    do {
                        self.referralsList = try decoder.decode([ReferralObject].self, from: data)
                        print(self.referralsList)
                        DispatchQueue.main.async {
                            self.referralsCountLabel.text = String(self.referralsList.count)
                        }
                       
                    } catch let error {
                        print(error.localizedDescription)
                    }
                }
            } failure: { error in
                
            }

        }
    }
    
    
    func updateMarkDownView(){
        let webView = WKWebView(frame: referralView.bounds)
              webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
       
        referralView.addSubview(webView)

              // Define the HTML content
        let htmlContent = """
              <style>
                  body {
                      font-family: -apple-system, system-ui, BlinkMacSystemFont, "Segoe UI", "Helvetica Neue", Arial, sans-serif;
                      font-size: 48px; /* Adjust the font size as needed */
                      color: black;
                  }
              </style>
              For every referral that signs up to actifit using your referral link, you earn:<br><br>
              <ul>
                  <li>One-time AFIT amount equal to 20% of the AFIT rewards your referral earns upon successful signup! (usually minimum 20 AFIT)</li>
                  <li>Up to 35% of your referral's actifit report rewards for one month, across all tokens rewarded (AFIT, HIVE, ...)</li>
              </ul>
              """
              webView.loadHTMLString(htmlContent, baseURL: nil)

    }

    
    @IBAction func copyBtnTapped(_ sender: Any) {
        if let username = User.current()?.steemit_username {
            UIPasteboard.general.string = "https://actifit.io/signup?referrer=\(username)"
            showToast(message: "Copied", width: 80, height: 40)
            rotateImage(rotateButton: copyBtn)
           
        }
    }
    
    @objc func rotateImage(rotateButton: UIButton) {
        // Create a basic animation for the rotation
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotationAnimation.fromValue = 0.0
        rotationAnimation.toValue = Double.pi * 2.0 // 360 degrees in radians
        rotationAnimation.duration = 1.0 // Adjust the duration as needed

        // Set the animation properties
        rotationAnimation.repeatCount = 1
        rotationAnimation.isRemovedOnCompletion = false

        // Add the animation to the button's layer
        rotateButton.layer.add(rotationAnimation, forKey: "rotate")
        

    }
    
    
    @IBAction func shareBtnTapped(_ sender: Any) {
        if let username = User.current()?.steemit_username {
            rotateImage(rotateButton: shareBtn)
            let itemsToShare = ["https://actifit.io/signup?referrer=\(username)"]
            
            // Create an instance of UIActivityViewController with the items to share
            let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
            
            // On iPad, you need to specify a source view and arrow direction
         //   if let popoverController = activityViewController.popoverPresentationController {
               // popoverController.sourceView = sender
                //popoverController.sourceRect = sender.bounds
          //  }
            
            // Present the UIActivityViewController
            self.present(activityViewController, animated: true, completion: nil)
        }
    }

    private func setUI() {
        referralsCountLabel.textColor = .primaryGreenColor()
        checkMarkImageView.image = ApplicationHelper.generateImageFromUnicode(unicode: 10003)
        shareBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.shareIcon.rawValue, size: 25), for: .normal)
        copyBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.copyIcon.rawValue, size: 25), for: .normal)
        sucessfulReferralsLabel.text = NSLocalizedString("successful_referrals", comment: "")
        referralLinkLabel.text = NSLocalizedString("your_referral_link", comment: "")
        if let userName = User.current()?.steemit_username {
            fullReferralLinkLabel.text = "https://actifit.io/signup?referrer=\(userName)"
        }
    }
    
    @IBAction func closeBtnTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    
}

extension ReferralsPopupViewController: WKNavigationDelegate {
    
}

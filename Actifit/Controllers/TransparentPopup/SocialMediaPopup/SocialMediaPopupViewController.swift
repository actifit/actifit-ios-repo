//
//  SocialMediaPopupViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 08/09/2023.
//

import UIKit
import SafariServices
class SocialMediaPopupViewController: UIViewController {
    @IBOutlet weak var facebookBtn: UIButton!
    
    @IBOutlet weak var telegramBtn: UIButton!
    @IBOutlet weak var discortBtn: UIButton!
    @IBOutlet weak var twitterBtn: UIButton!
    @IBOutlet weak var popupTitleLabel: UILabel!
    @IBOutlet weak var youtubeBtn: UIButton!
    
    @IBOutlet weak var instagramBtn: UIButton!
    
    @IBOutlet weak var linkedInBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        setButtons()
        // Do any additional setup after loading the view.
    }
    
    private func setButtons() {
        facebookBtn.setImage(UIImage(named: "facebook")?.withTintColor(.white), for: .normal)
        telegramBtn.setImage(UIImage(named: "telegram")?.withTintColor(.white), for: .normal)
        discortBtn.setImage(UIImage(named: "discord")?.withTintColor(.white), for: .normal)
        twitterBtn.setImage(UIImage(named: "twitter")?.withTintColor(.white), for: .normal)
        youtubeBtn.setImage(UIImage(named: "youtube")?.withTintColor(.white), for: .normal)
        instagramBtn.setImage(UIImage(named: "instagram")?.withTintColor(.white), for: .normal)
        linkedInBtn.setImage(UIImage(named: "linkedin")?.withTintColor(.white), for: .normal)

    }
    
    @IBAction func closeBtnTapped(_ sender: Any) {
       
    }
    
    
    static func create() -> SocialMediaPopupViewController {
        let vc = UIStoryboard(name: "SocialMediaPopup", bundle: nil).instantiateViewController(withIdentifier: "SocialMediaPopupViewController") as! SocialMediaPopupViewController
        vc.modalPresentationStyle = .overFullScreen
        return vc
    }
    
    @IBAction func socialMediaBtnTapped(_ sender: UIButton) {
        openSafari(url: ApplicationHelper.getSocialMedialURLByTag(tag: sender.tag))
    }
    
    private func openSafari(url: URL?) {
        let safari = SFSafariViewController(url: url!)
        present(safari, animated: true)
    }
    
    
    @IBAction func clodeBtnTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

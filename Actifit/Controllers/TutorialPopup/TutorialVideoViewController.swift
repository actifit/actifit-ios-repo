//
//  TutorialVideoViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 17/09/2023.
//

import UIKit
import WebKit

class TutorialVideoViewController: UIViewController {

    @IBOutlet weak var webView: WKWebView!
    
    @IBOutlet weak var closeBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
            self.getVideoTutorial()
        })
       

        webView.scrollView.zoomScale = 0.5
        // Do any additional setup after loading the view.
    }
    
    private func getVideoTutorial() {
        SwiftLoader().sharedInstance.show(title: "Loading...", animated: true)
        API().getVideoTutorial { info, statusCode in
            DispatchQueue.main.async {
                SwiftLoader().sharedInstance.hide()
                if let response = info as? String {
                    let data = response.utf8Data()
                    let decoder = JSONDecoder()
                    do {
                        let videoURL = try decoder.decode(VideoTutorial.self, from: data)
                        self.loadURL(url: URL(string: videoURL.vidUrl ?? "")!)
                    }catch _ {
                       
                    }
                }
            }
        } failure: { error in
            
        }

    }
    
    func loadURL(url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
    
    @IBAction func closeBtnTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    static func create() -> TutorialVideoViewController {
        let vc = UIStoryboard(name: "TutorialPopup", bundle: nil).instantiateViewController(withIdentifier: "TutorialVideoViewController") as! TutorialVideoViewController
        vc.modalPresentationStyle = .overFullScreen
        return vc
        
    }

}

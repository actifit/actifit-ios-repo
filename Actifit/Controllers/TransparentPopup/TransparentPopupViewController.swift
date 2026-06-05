//
//  TransparentPopupViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 20/07/2023.
//

import UIKit
import SafariServices
class TransparentPopupViewController: UIViewController {

    @IBOutlet weak var backgroundView: UIView!
    @IBOutlet weak var backgroundButton: UIButton!

    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var actionButton: UIButton!
    var descritpionText: String?
    var titleText: String?
    var cancelButtonText: String?
    var actionButtonText: String?
    var noteSize: NoteSize?
  var onActionButtonTapped: (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
            setUI()
        // Do any additional setup after loading the view.
    }
    

    static func create (title: String, description: String,
                        cancelButtonText: String, actionButtonText: String? = nil, noteSize: NoteSize, onActionButtonTapped: (() -> Void)? = nil) ->TransparentPopupViewController {
        let vc = UIStoryboard(name: "TransparetPopup", bundle: nil).instantiateViewController(withIdentifier: "TransparentPopupViewController") as! TransparentPopupViewController
        vc.descritpionText = description
        vc.titleText = title
        vc.cancelButtonText =  cancelButtonText
        vc.actionButtonText = actionButtonText
        vc.noteSize = noteSize
        vc.onActionButtonTapped = onActionButtonTapped
        vc.modalPresentationStyle = .overFullScreen
        return vc
    }
    
    private func setUI() {
        if noteSize == .medium {
          //  bottomConstraint.constant = view.frame.size.height / 3.3
        }
        backgroundView.layer.cornerRadius = 5
        backgroundView.clipsToBounds = true
        titleLabel.text = titleText
        descriptionLabel.text = descritpionText
        cancelButton.setTitle(cancelButtonText, for: .normal)
        actionButton.setTitle(actionButtonText, for: .normal)
        
    }
    
    @IBAction func backgroundButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func actionButtonTapped(_ sender: Any) {
      if let action = onActionButtonTapped {
        onActionButtonTapped?()
      } else {
        let controller = SFSafariViewController(url: URL(string: "https://actifit.io/userrank")!)
        present(controller, animated: true, completion: nil)
      }
    }
}

enum ScreenSource {
    case rank
    case resource
}

enum NoteSize {
    case small
    case medium
    case large
}

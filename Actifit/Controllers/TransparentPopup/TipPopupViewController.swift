//
//  TipPopupViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 03/08/2023.
//

import UIKit

class TipPopupViewController: UIViewController {

    @IBOutlet weak var titleLabel: UILabel!
    
    @IBOutlet weak var dontShowAgainBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var previousBtn: UIButton!
    @IBOutlet weak var nextBtn: UIButton!
    @IBOutlet weak var tipLabel: UILabel!
    var tips: [DailyTipsModel] = []
    var titleText = ""
    var previousValues: [Int] = []
    var previousValue = 0
    var closePopup: (() ->())?
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        // Do any additional setup after loading the view.
    }
    
    private func setUI() {
        titleLabel.text = titleText
        guard !tips.isEmpty else { return }
       // tipLabel.text = tipObject?.tip
        closeBtn.setTitle(NSLocalizedString("close_upper", comment: ""), for: .normal)
        dontShowAgainBtn.setTitle(NSLocalizedString("dont_show_again", comment: ""), for: .normal)
        let randomIndex = Int.random(in: 0..<tips.count)
        previousValue = randomIndex
        tipLabel.text = tips[randomIndex].tip ?? ""
        previousValues.append(randomIndex)
        nextBtn.setImage(UIImage(systemName: "arrowtriangle.right.fill"), for: .normal)
        if let rightArrow = UIImage(systemName: "arrowtriangle.right.fill")?.withTintColor(.white), let leftArrow = UIImage(systemName: "arrowtriangle.backward.fill")?.withTintColor(.white) {
            let imageSize = CGSize(width: 10, height: 10)
            let resizedRightArrowImage = rightArrow.withConfiguration(UIImage.SymbolConfiguration(pointSize: imageSize.width, weight: .regular))
            let resizedLeftArrowImage = leftArrow.withConfiguration(UIImage.SymbolConfiguration(pointSize: imageSize.width, weight: .regular))
            
               // Now, you can set the resized image for your UIButton
               nextBtn.setImage(resizedRightArrowImage, for: .normal)
            previousBtn.setImage(resizedLeftArrowImage, for: .normal)
        }
        previousBtn.layer.cornerRadius = 5
        nextBtn.layer.cornerRadius = 5
        previousBtn.clipsToBounds = true
        nextBtn.clipsToBounds = true
    }
    
    private func generateTip(index: Int) {
        tipLabel.text = tips[index].tip ?? ""
    }
    
    
    static func create (tips: [DailyTipsModel], title: String, onClose:(() -> ())?) -> TipPopupViewController {
        let vc = UIStoryboard(name: "TransparetPopup", bundle: nil).instantiateViewController(withIdentifier: "TipPopupViewController") as! TipPopupViewController
        vc.tips = tips
        vc.titleText = title
        vc.modalPresentationStyle = .overFullScreen
        vc.closePopup = onClose
        return vc
    }
    

    @IBAction func onCLoseTapped(_ sender: Any) {
        
        dismiss(animated: true, completion: {
            self.closePopup?()
        })
    }
    
    @IBAction func dontShowAgainTapped(_ sender: Any) {
        UserDefaults.standard.showTips = false
        dismiss(animated: true)
    }
    
    @IBAction func nextTipTapped(_ sender: Any) {
        let randomIndex = Int.random(in: 0..<tips.count)
        if !previousValues.contains(where: {$0 == randomIndex}) {
            previousValues.append(randomIndex)
        } else {
            if previousValues.count == tips.count {
                previousValues.removeAll()
            }
        }
       
        generateTip(index: randomIndex)
        
    }
    
   
    
    @IBAction func previousTipTapped(_ sender: Any) {
        let randomIndex = Int.random(in: 0..<tips.count)
        generateTip(index: randomIndex)
    }


}

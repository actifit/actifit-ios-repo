//
//  CommonWalletHeader.swift
//  Actifit
//
//  Created by Ali Jaber on 13/11/2023.
//

import UIKit

class CommonWalletHeader: UIView {

    @IBOutlet weak var sectionNameLabel: UILabel!
    @IBOutlet weak var sectionButtonIcon: UIButton!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondBtn: UIButton!
    
    let nibName = "CommonWalletHeader"
    var onRefreshTapped: (() -> ())?
   
    

    func commonInit() {
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }
    
    func loadViewFromNib() -> UIView? {
        let nib = UINib(nibName: nibName, bundle: nil)
        if let views = nib.instantiate(withOwner: self, options: nil) as? [UIView], let view = views.first {
            print("Loaded view from nib:", view)
            print("Subviews:", view.subviews)
            return view
        } else {
            print("Failed to load view from nib")
            return nil
        }
    }
    
    func setUI(icon: NSAttributedString, sectionName: String, firstBntIcon: NSAttributedString? = nil, secondBtnIcon: UIImage? = nil) {
        firstButton.setAttributedTitle(firstBntIcon, for: .normal)
        firstButton.tintColor = .primaryRedColor()
        secondBtn.isHidden = secondBtnIcon == nil
        sectionNameLabel.text = sectionName
        sectionButtonIcon.setAttributedTitle(icon, for: .normal)
        sectionButtonIcon.tintColor = .primaryRedColor()
    }
    
    
    @IBAction func firstBntTapped(_ sender: Any) {//change this to refresh button
        onRefreshTapped?()
    }
    
    
    @IBAction func secondBtnTapped(_ sender: Any) {
        print("first button tapped")
    }

}
extension UIView {
    class func fromNib<T: UIView>() -> T {
        return Bundle(for: T.self).loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
}

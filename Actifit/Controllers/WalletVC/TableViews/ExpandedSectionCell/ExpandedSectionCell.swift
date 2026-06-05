//
//  ExpandedSectionCell.swift
//  Actifit
//
//  Created by Ali Jaber on 10/11/2023.
//

import UIKit
import Combine
class ExpandedSectionCell: UITableViewCell {
    @IBOutlet weak var balanceImageView: UIImageView!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var stakeLabel: UILabel!
    @IBOutlet weak var actionBtn: UIButton!
    
    @IBOutlet weak var actionBtnView: UIView!
    @IBOutlet weak var expandedRowView: UIView!
    @IBOutlet weak var sendBtn: UIButton!
    
    @IBOutlet weak var stakeBtn: UIButton!
    private var cancellable: AnyCancellable?
    @IBOutlet weak var unstakeBtn: UIButton!
    var onExpandTapped: ((Bool) -> ())?
    var onSendBtnTapped: (() -> ())?
    var onStakedBtnTapped: (() -> ())?
    var onUnstakeBtnTapped: (() -> ())?
    var balanceSectionObject: BalanceSections? {
        didSet {
            setUI()
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setUI() {
        guard let balance = balanceSectionObject else { return }
        if balance.allowExpanding == true {
            expandedRowView.isHidden = !balance.isExpanded
        } else {
            expandedRowView.isHidden = true
        }
        balanceImageView.image = balance.icon
        balanceLabel.text = balance.balance
        stakeLabel.text = balance.staked ?? ""
        actionBtn.setAttributedTitle(balance.actionIconAsAwesome, for: .normal)
        sendBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.transactionAction.rawValue , size: 25), for: .normal)
        stakeBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.lock.rawValue, size: 25), for: .normal)
        unstakeBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.unLock.rawValue, size: 25), for: .normal)
        if let iconURL = balance.iconURL, iconURL != "" {
            getImageFromURL(url: iconURL)
        }
        
    }
    
    func getImageFromURL(url: String) {

        cancellable =  URLSession.shared.dataTaskPublisher(for: URL(string: url)!)
            .map {data, _ -> UIImage? in
                UIImage(data: data)
            }.receive(on: DispatchQueue.main)
            .replaceError(with: nil)
            .sink{[weak self ] image in
                self?.balanceImageView.image = image
 
        }
    }
    
    @IBAction func actionBtnTapped(_ sender: Any) {
       // if balanceSectionObject?.allowExpanding == true {
            onExpandTapped?(!(balanceSectionObject?.isExpanded ?? false))
        //}
     
    }
    
    @IBAction func sendBtnTapped(_ sender: Any) {
        onSendBtnTapped?()
    }
    
    @IBAction func stakeBtnTapped(_ sender: Any) {
        onStakedBtnTapped?()
    }
    
    @IBAction func unstakeBtnTapped(_ sender: Any) {
        onUnstakeBtnTapped?()
    }
    
}

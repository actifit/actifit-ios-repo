//
//  PollChiceCell.swift
//  Actifit
//
//  Created by Ali Jaber on 28/09/2023.
//

import UIKit

class PollChoiceCell: UITableViewCell {
    var pollChoice: PollChoiceModel? {
        didSet {
            setUI()
        }
    }
    @IBOutlet weak var selectionBtn: UIButton!
    @IBOutlet weak var choiceNameLabel: UILabel!
    var changeSelection: ((Bool) -> ())?
    override func awakeFromNib() {
        super.awakeFromNib()
        selectionBtn.layer.cornerRadius = selectionBtn.frame.width / 2
        selectionBtn.clipsToBounds = true
        selectionBtn.layer.borderWidth = 2
        selectionBtn.layer.borderColor  = UIColor.darkGray.cgColor
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setUI() {
        guard let choice = pollChoice else { return }
        choiceNameLabel.text = choice.choiceName
        selectionBtn.backgroundColor = choice.isSelected ? .primaryRedColor() : .white
    }
    
    @IBAction func onChoiceBtnTapped(_ sender: Any) {
        changeSelection?(!(pollChoice?.isSelected ?? false))
//        if selectionBtn.backgroundColor == .primaryRedColor() {
//            selectionBtn.backgroundColor = .white
//        } else {
//            selectionBtn.backgroundColor = .primaryRedColor()
//        }
        
    }
}

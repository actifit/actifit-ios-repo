//
//  PollTextCell.swift
//  Actifit
//
//  Created by Ali Jaber on 28/09/2023.
//

import UIKit

class PollTextCell: UITableViewCell {
    var setGreyColor: Bool = false
    @IBOutlet weak var titleLabel: UILabel!
    var textString: String? {
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
        titleLabel.text = textString
        
        
    }
    
}

//
//  BodyCell.swift
//  Actifit
//
//  Created by Ali Jaber on 15/08/2023.
//

import UIKit

class BodyCell: UITableViewCell {
    @IBOutlet weak var prizeLabel: UILabel!
    
    @IBOutlet weak var prizeDescriptiopnLabel: UILabel!
    var bodyDataModel: ExtraPrizesModel? {
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
        guard let data = bodyDataModel else { return }
        prizeLabel.text = data.title
        prizeDescriptiopnLabel.text = data.descript
    }
    
}

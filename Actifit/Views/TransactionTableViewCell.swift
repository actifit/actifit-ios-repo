//
//  TransactionTableViewCell.swift
//  Actifit
//
//  Created by Hitender kumar on 17/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit

class TransactionTableViewCell: UITableViewCell {
    @IBOutlet weak var activityTypeLabel : UILabel!
    @IBOutlet weak var tokenCountLabel : UILabel!
    @IBOutlet weak var dateLabel : UILabel!
    @IBOutlet weak var noteLabel : UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupInitials()
    }
    
    func setupInitials()
    {
        activityTypeLabel.text                  = "activity_type_lbl".localized()
        tokenCountLabel.text                    = "token_count_lbl".localized()
        dateLabel.text                          = "date_added_lbl".localized()
        noteLabel.text                          = "note_lbl".localized()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureWith(transaction : Transaction) {
        self.setupInitials()
        self.activityTypeLabel.text = "Activity Type: ".localized() + transaction.reward_activity
        self.tokenCountLabel.text = "Token Count: ".localized() + String(transaction.token_count)
        self.dateLabel.text = "Date Added: ".localized() + transaction.date
        self.noteLabel.text = "Note: ".localized() + transaction.note
        
    }

}

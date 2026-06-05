//
//  DailyLeaderboardTableCell.swift
//  Actifit
//
//  Created by Hitender kumar on 16/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit

class DailyLeaderboardTableCell: UITableViewCell {

     @IBOutlet weak var leaderboardName : UILabel!
     @IBOutlet weak var leaderboardCount:UILabel!
     @IBOutlet weak var leaderboardRank :UILabel!
     @IBOutlet weak var leaderboardImage:UIImageView!
     @IBOutlet weak var btnDetails:UIButton!

    override func awakeFromNib(){
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}

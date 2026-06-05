//
//  NotificationsCell.swift
//  Actifit
//
//  Created by Ali Jaber on 25/07/2023.
//

import UIKit

class NotificationsCell: UITableViewCell {
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var linkButton: UIButton!
    var onLinkTapped: ((String) -> ())?
    var notificationModel: NotificationModel? {
        didSet {
            setUI()
        }
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        linkButton.layer.cornerRadius = 5
        linkButton.clipsToBounds = true
        // Initialization code
    }
    
    private func setUI() {
        guard let notification = notificationModel else { return }
        userNameLabel.text = notification.user ?? ""
        descriptionLabel.text = notification.details ?? ""
        timeLabel.text = DateConverter().compareDates(dateString: notification.date ?? "")
    }
    
    @IBAction func onLinktTapped(_ sender: Any) {
        onLinkTapped?(notificationModel?.url ?? "")
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

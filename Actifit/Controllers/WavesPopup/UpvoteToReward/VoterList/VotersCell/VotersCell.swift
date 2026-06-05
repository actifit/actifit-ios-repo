//
//  VotersCell.swift
//  Actifit
//
//  Created by Ali Jaber on 22/04/2024.
//

import UIKit

class VotersCell: UITableViewCell {
  @IBOutlet weak var nameLabel: UILabel!
  var vote: ActiveVote? {
    didSet {
      fillUI()
    }
  }
  @IBOutlet weak var profileImageView: UIImageView!
  override func awakeFromNib() {
        super.awakeFromNib()
    setUI()
        // Initialization code
    }

  private func setUI() {
    profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
    profileImageView.clipsToBounds = true
  }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
  private func fillUI() {
    guard let voter = vote else { return }
    nameLabel.text = voter.voter
    Task {
      let image = try? await ApplicationHelper().fetchUserImage(finalUsername: voter.voter ?? "")
      if let img = image {
        self.profileImageView.image = img
      }
    }
  }

}

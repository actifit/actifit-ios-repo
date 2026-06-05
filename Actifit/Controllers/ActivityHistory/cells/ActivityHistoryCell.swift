//
//  ActivityHistoryCell.swift
//  Actifit
//
//  Created by Hitender kumar on 09/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit

class ActivityHistoryCell: UITableViewCell {

  @IBOutlet weak var dailyStepsLabel : UILabel!
  @IBOutlet weak var viewHistoryDayButton : UIButton!
  @IBOutlet weak var formBtn: UIButton!
  @IBOutlet weak var stepsLabel : UILabel!
    var activity: HistoryWithReportModel? {
        didSet {
            updateUI()
        }
    }
    var onReportTap: (() -> Void)?
  override func awakeFromNib() {
    super.awakeFromNib()
    viewHistoryDayButton.setTitle("", for: .normal)
    viewHistoryDayButton.layer.cornerRadius = 5
    viewHistoryDayButton.clipsToBounds = true
    viewHistoryDayButton.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.charBar.rawValue, size: 24), for: .normal)



    viewHistoryDayButton.backgroundColor = .primaryRedColor()
    // Initialization code
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
  }

    func updateUI() {
        guard let activity = self.activity else { return }
        if activity.containsReport {
            formBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.form.rawValue, size: 26), for: .normal)
            formBtn.tintColor = .primaryGreenColor()
        } else {
            formBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.rectangleX.rawValue, size: 32), for: .normal)
            formBtn.tintColor = .primaryRedColor()
        }
        viewHistoryDayButton.titleLabel?.font = .systemFont(ofSize: 24)
        self.dailyStepsLabel.text = activity.activity.date.dateString()
        stepsLabel.text = "\(activity.activity.steps)"
        if activity.activity.steps < 5000 {
            stepsLabel.textColor = .darkGray
        } else if activity.activity.steps > 5000 && activity.activity.steps < 10000 {
            stepsLabel.textColor = .primaryRedColor()
        } else {
            stepsLabel.textColor = .primaryGreenColor()
        }
    }

  @IBAction func formBtnTapped(_ sender: Any) {
      if activity?.containsReport == true {
          onReportTap?()
      }
  }

  func formattedDAteStr(date : Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = NSLocale.current
    dateFormatter.dateFormat = "dd/MM/yyyy"
    return dateFormatter.string(from: date)
  }
}

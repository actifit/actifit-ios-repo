//
//  UpvoteToRewardViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 22/04/2024.
//

import UIKit

class UpvoteToRewardViewController: UIViewController {
  @IBOutlet weak var mainView: UIView!
  @IBOutlet weak var plusTenBtn: UIButton!
  @IBOutlet weak var minusTenBtn: UIButton!
  @IBOutlet weak var votingUsernameLabel: UILabel!
  @IBOutlet weak var percentTextField: UITextField!
  @IBOutlet weak var upVoteBtn: UIButton!
  @IBOutlet weak var voterListBtn: UIButton!
  @IBOutlet weak var closeBtn: UIButton!
  var percentageCount:Int = 50
  var comment: PostComments?
  var viewModel: UpvoteViewModel!
  var didVoteSuccessfully: ((Bool) -> Void)?
  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel = UpvoteViewModel()
    setUI()
    setBinding()
  }

  private func setBinding() {
    viewModel.loaderPublisher.sink { showLoader in
      showLoader ?
      self.showProgressIndicator() : self.hideProgressIndicator()
    }.store(in: &viewModel.cancellables)
    viewModel.dismissPublisher.sink { dismiss in
      if dismiss {
        self.showAlertWithOkCompletion(title: "", message: "Successfuly Voted!") { finished in
          self.didVoteSuccessfully?(true)
          self.dismiss(animated: true)
        }
      }
    }.store(in: &viewModel.cancellables)
  }

  private func setUI() {
    percentTextField.delegate = self
    votingUsernameLabel.text = "Voting @\(comment?.author ?? "")'s content"
    percentTextField.text = "\(percentageCount)"
    mainView.layer.cornerRadius = 10
    mainView.clipsToBounds = true

    percentTextField.layer.cornerRadius = 5
    percentTextField.clipsToBounds = true
    percentTextField.layer.borderWidth = 2
    percentTextField.layer.borderColor = UIColor.primaryRedColor().cgColor

    plusTenBtn.layer.cornerRadius = 5
    plusTenBtn.clipsToBounds = true
    minusTenBtn.layer.cornerRadius = 5
    minusTenBtn.clipsToBounds = true
    upVoteBtn.layer.cornerRadius = 5
    upVoteBtn.clipsToBounds = true

    voterListBtn.layer.cornerRadius = 5
    voterListBtn.clipsToBounds = true

    closeBtn.layer.cornerRadius = 5
    closeBtn.clipsToBounds = true
  }

  private func updatePercentageLabel() {
    percentTextField.text = "\(percentageCount)"
  }

  @IBAction func minusTenTapped(_ sender: Any) {
    if percentageCount > 10 {
      percentageCount -= 10
      updatePercentageLabel()
    }
  }

  @IBAction func plusTenTapped(_ sender: Any) {
    if percentageCount <= 90 {
      percentageCount += 10
      updatePercentageLabel()
    }
  }

  @IBAction func upvoteTapped(_ sender: Any) {
    if percentageCount < 1 {
      showAlertWith(title: "Error", message: "Percentage should be greater than 0")
      return
    }
    guard let comment = comment else { return }
    viewModel.upvoteAPI(comment: comment, vote: percentageCount)
  }

  @IBAction func voterListTapped(_ sender: Any) {
    self.present(VoterLisViewController.create(voters: comment?.activeVotes ?? []), animated: true)
  }

  @IBAction func closeTapped(_ sender: Any) {
    dismiss(animated: true)
  }

  static func create(comment: PostComments?, didVoteSuccessfully: ((Bool) -> Void)?) -> UpvoteToRewardViewController {
    let vc = UIStoryboard(name: "WavesPopup", bundle: nil).instantiateViewController(withIdentifier: "UpvoteToRewardViewController") as! UpvoteToRewardViewController
    vc.comment = comment
    vc.didVoteSuccessfully = didVoteSuccessfully
    return vc
  }

}

extension UpvoteToRewardViewController: UITextFieldDelegate {
  func textFieldDidEndEditing(_ textField: UITextField) {
    if let text = textField.text, let percentage = Int(text) {
      if percentage < 1 {
        self.showAlertWith(title: "Error", message: "Value must be greater than 1")
        textField.text = "1"
      }
    }
  }
}

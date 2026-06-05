//
//  CommentReplyViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 21/04/2024.
//

import UIKit
import Down

class CommentReplyViewController: UIViewController {

  @IBOutlet weak var photoBtn: UIButton!
  @IBOutlet weak var replyTextView: UITextView!
  @IBOutlet weak var mainView: UIView!

  @IBOutlet weak var replyLabel: UILabel!
  @IBOutlet weak var topConstraint: NSLayoutConstraint!
  @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var replyBtn: UIButton!
  @IBOutlet weak var cancelBtn: UIButton!
  var imagePicker: ImagePicker!
  var username: String?
  var viewModel: CommentReplyViewModel!
  var postComment: PostComments?
  var steps: Int?
  var appVersion: String?
  var author: String?
  var permlink: String?
  override func viewDidLoad() {
    super.viewDidLoad()
    setUI()


    // Do any additional setup after loading the view.
  }

  private func setUI() {
    viewModel = CommentReplyViewModel()
    mainView.layer.cornerRadius = 10
    mainView.clipsToBounds = true
    topConstraint.constant = self.view.frame.height / 4
    bottomConstraint.constant = self.view.frame.height / 4
    replyTextView.delegate = self
    photoBtn.layer.cornerRadius = 5
    photoBtn.clipsToBounds = true
    cancelBtn.layer.cornerRadius = 5
    cancelBtn.clipsToBounds = true
    replyBtn.layer.cornerRadius = 5
    cancelBtn.clipsToBounds = true
    imagePicker = ImagePicker(presentationController: self)
    imagePicker.delegate = self
    setBinding()
    replyLabel.text = "Replying to @\(postComment?.author ?? "")"
  }

  private func setBinding() {
    viewModel.loaderPublisher.sink { showLoader in
      showLoader ?
      self.showProgressIndicator() : self.hideProgressIndicator()
    }.store(in: &viewModel.cancellables)
    viewModel.uploadedImageURLPublisher.sink { imgURL in
      if self.replyTextView.text == "Reply with something cooool!" {
        self.replyTextView.text = ""

      }
      self.updateTextView(text: imgURL)

    }.store(in: &viewModel.cancellables)
    viewModel.dismissPublisher.sink { shouldDismiss in
      self.showAlertWithOkCompletion(title: "", message: "Comment Sent Successfully!") { finished in
        self.dismiss(animated: true)
      }

    }.store(in: &viewModel.cancellables)
  }

  private func updateTextView(text: String) {
    replyTextView.text = (replyTextView.text ?? "") + "\n" + text
    updatePreview()
  }

  private func updatePreview() {
    guard let markDownString = replyTextView.text else {
      return
    }
    do {
      let downView = try DownView(frame: self.contentView.frame, markdownString: markDownString)
      downView.pageZoom = 1.5
      downView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
      downView.frame = contentView.bounds
      contentView.addSubview(downView)
    } catch {
      print(error.localizedDescription)
    }
  }

  static func create(stepCount: Int, appVersion: String, post: PostComments?) -> CommentReplyViewController {
    let vc = UIStoryboard(name: "WavesPopup", bundle: nil).instantiateViewController(withIdentifier: "CommentReplyViewController") as? CommentReplyViewController
    vc?.steps = stepCount
    vc?.appVersion = appVersion
    vc?.postComment = post
    return vc!
  }

  @IBAction func cancelBtnTapped(_ sender: Any) {
    dismiss(animated: true)
  }

  @IBAction func replyTapped(_ sender: Any) {
    guard let comment = postComment else { return }
    viewModel.addCommentReply(reply: replyTextView.text, stepCount: "\(steps ?? 0)", appVersion: appVersion!, comment: comment)

  }

  @IBAction func photoBtnTapped(_ sender: Any) {
    imagePicker.present()
  }
}

extension CommentReplyViewController: UITextViewDelegate {
  func textViewDidBeginEditing(_ textView: UITextView) {
    if textView.text == "Reply with something cooool!" {
      textView.text = ""
    }
   // textView.text = ""
  }

  func textViewDidEndEditing(_ textView: UITextView) {
    updatePreview()
  }
}

extension CommentReplyViewController: ImagePickerDelegate {
  func didSelect(image: UIImage?) {
    guard let image = image else { return }
      Task {
          await viewModel.uploadData(image: image)
      }
  }

}

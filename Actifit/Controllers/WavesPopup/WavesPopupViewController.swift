//
//  WavesViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 03/04/2024.
//

import UIKit
import Down

class WavesPopupViewController: UIViewController {
    @IBOutlet weak var infoBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var updatesTextView: UITextView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var updatesPreview: UIView!
    var imagePicker: ImagePicker!
    @IBOutlet weak var mainView: UIStackView!
    @IBOutlet weak var imagePickerBtn: UIButton!
    @IBOutlet weak var postBtn: UIButton!
    var viewModel: WavesPopupViewModel!
    @IBOutlet weak var showAndHidePreviewBtn: UIButton!
    var rotationAngle: CGFloat = 0
    var stepsCount: Int?
    var appVersion: String?
    var isSnapTapped = true
    @IBOutlet weak var ecencyBtn: UIButton!
    @IBOutlet weak var snapButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        viewModel = WavesPopupViewModel()
        updatesTextView.text = viewModel.previewContent
        setUI()
    }

    private func setBinding() {
        viewModel.refreshPublisher.sink { _ in
            self.tableView.reloadData()
        }.store(in: &viewModel.cancellables)
        viewModel.loaderPublisher.sink { showLoader in
            showLoader ?
            self.showProgressIndicator() : self.hideProgressIndicator()
        }.store(in: &viewModel.cancellables)
        viewModel.uploadedImageURLPublisher.sink { imgURL in
            self.updateTextView(text: imgURL)
        }.store(in: &viewModel.cancellables)

        viewModel.clearTextPublisher.sink { clearText in
            if clearText {
                if clearText {
                    self.showToast(message: "Comment sent successfully!")
                }
                self.updatesTextView.text = self.viewModel.shareUpdate

                self.updateMarkDownView()
            }
        }.store(in: &viewModel.cancellables)
    }

    private func updateTextView(text: String) {
        if updatesTextView.text == viewModel.shareUpdate {
            updatesTextView.text = ""
        }
        updatesTextView.text = (updatesTextView.text ?? "") + "\n" + text
        updateMarkDownView()
    }

    @IBAction func onSnapBtnTapped(_ sender: Any) {
        ecencyBtn.setImage(UIImage(named: "radio"), for: .normal)
        snapButton.setImage(UIImage(named: "radioSelected"), for: .normal)
        isSnapTapped = true
    }

    @IBAction func onEcencyBtnTapped(_ sender: Any) {
        ecencyBtn.setImage(UIImage(named: "radioSelected"), for: .normal)
        snapButton.setImage(UIImage(named: "radio"), for: .normal)
        isSnapTapped = false
    }

    private func setUI() {

        ecencyBtn.setImage(UIImage(named: isSnapTapped ? "radio" : "radioSelected"), for: .normal)
        snapButton.setImage(UIImage(named: isSnapTapped ? "radioSelected": "radio" ), for: .normal)


        infoBtn.layer.cornerRadius = infoBtn.frame.width / 2
        infoBtn.clipsToBounds = true
        closeBtn.clipsToBounds = true
        closeBtn.layer.cornerRadius = 5
        postBtn.layer.cornerRadius = 5
        postBtn.clipsToBounds = true
        imagePickerBtn.layer.cornerRadius = 5
        imagePickerBtn.clipsToBounds = true
        updatesTextView.delegate = self
        showAndHidePreviewBtn.layer.cornerRadius = 5
        showAndHidePreviewBtn.clipsToBounds = true
        tableView.register(UINib(nibName: "WaveCell", bundle: nil), forCellReuseIdentifier: "WaveCell")
        setBinding()
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableViewAutomaticDimension
        mainView.layer.cornerRadius = 10
        mainView.clipsToBounds = true
        imagePicker = ImagePicker(presentationController: self)
        imagePicker.delegate = self
        updatesTextView.text = viewModel.shareUpdate
        updateMarkDownView()
    }

    func changePreviewState() {
        updatesPreview.isHidden = !updatesPreview.isHidden
        showAndHidePreviewBtn.setImage(UIImage(systemName: "arrow.up.circle.fill"), for: .normal)
        rotationAngle += CGFloat.pi
        UIView.animate(withDuration: 0.3, animations: {
            self.showAndHidePreviewBtn.imageView!.transform = CGAffineTransform(rotationAngle: self.rotationAngle)
        })
    }


    func updateMarkDownView() {
        guard let markDownString = updatesTextView.text else {
            return
        }
        do {
            let downView = try DownView(frame: self.updatesPreview.frame, markdownString: (markDownString == viewModel.shareUpdate ? "Preview" : markDownString))
            downView.pageZoom = 1.5
            downView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            downView.frame = updatesPreview.bounds
            updatesPreview.addSubview(downView)
        } catch {
            print(error.localizedDescription)
        }
    }


    static func create(steps: Int?, appversion: String?) -> WavesPopupViewController {
        let vc = UIStoryboard(name: "WavesPopup", bundle: nil).instantiateViewController(withIdentifier: "WavesPopupViewController") as! WavesPopupViewController
        vc.stepsCount = steps
        vc.appVersion = appversion
        vc.modalPresentationStyle = .overFullScreen
        return vc
    }

    @IBAction func closeBtnTapped(_ sender: Any) {
        TranslationManager.sharedInstance.clearWaves()
        dismiss(animated: true)
    }

    @IBAction func infoBtnTapped(_ sender: Any) {
        let vc = TransparentPopupViewController.create(title: "Discussions", description: "Waves by Ecency and Snaps by Peakd are additional short and quick communication means on hive blockchain. Engage with others, share your updates as you go through your daily journeys, and earn some extra rewards as well.", cancelButtonText: "CLOSE", noteSize: .medium)
        self.present(vc, animated: true)
    }

    @IBAction func postTapped(_ sender: Any) {
        if updatesTextView.text.isEmpty || updatesTextView.text == viewModel.shareUpdate {
            showToast(message: "Please type some content")
            return
        }
        Task {
            await viewModel.createWave(body: updatesTextView.text ?? "", stepCount: "\(stepsCount ?? 0)", appVersion: self.appVersion ?? "", isSnap: isSnapTapped)
        }
    }

    @IBAction func openImagePickerTapped(_ sender: Any) {
        imagePicker.present()
    }

    @IBAction func showAndHidePreviewTapped(_ sender: Any) {
        changePreviewState()

    }

    private func shareScreen(comment: PostComments?) {
        guard let comment = comment else { return }
        let url = "http://actifit.io/\(comment.author)/\(comment.permlink)"
        let itemsToShare = ["Check out this cool post on actifit, the social Move2Earn Project! \(url)"]
        let activityViewController = UIActivityViewController(activityItems: itemsToShare, applicationActivities: nil)
        self.present(activityViewController, animated: true, completion: nil)
    }

    func presentCommentView(comment: PostComments?) {
        guard let comment = comment else { return }
        self.present(CommentReplyViewController.create( stepCount: stepsCount ?? 0, appVersion:  self.appVersion ?? "", post: comment), animated: true)

    }

    func presentUpvoteScreen(comment: PostComments?) {
        self.present(UpvoteToRewardViewController.create(comment: comment, didVoteSuccessfully: { [weak self] didVote in
            self?.viewModel.upvotesId.append(comment?.id ?? 0)
            self?.viewModel.getPastWaveCommentsOnPagination(isSnap: self?.isSnapTapped ?? false)
            self?.tableView.reloadData()
        }), animated: true)
    }

}


extension WavesPopupViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = viewModel.shareUpdate
        } else {
            self.updateMarkDownView()
        }
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "Share a quick update..." {
            textView.text = ""
        } else {
            // viewModel.previewContent = textView.text
        }
    }


}

extension WavesPopupViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.commentCount
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WaveCell") as! WaveCell
        cell.comment = viewModel.commentsAndSnaps[indexPath.row]
        cell.wave = viewModel.postResult
        if viewModel.upvotesId.filter({$0 == viewModel.commentsAndSnaps[indexPath.row].id}).count > 0 {
            cell.didVoteForComment = true
        }

        cell.selectionStyle = .none
        cell.onReplyTapped = { [weak self] comment in
            self?.presentCommentView(comment: comment)
        }
        cell.onUpvoteTapped = {[weak self] comments in
            DispatchQueue.main.async {
                self?.presentUpvoteScreen(comment: comments)
            }
        }
        cell.onShareTapped = { [weak self] comment in
            self?.shareScreen(comment: comment)
        }
        cell.reloadCell = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.beginUpdates()
                self?.tableView.endUpdates()

            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == viewModel.commentsAndSnaps.count - 1 {
            viewModel.getPastWaveCommentsOnPagination(isSnap: true)
            viewModel.getPastWaveCommentsOnPagination(isSnap: false)
        }
    }
}

extension WavesPopupViewController: ImagePickerDelegate {
    func didSelect(image: UIImage?) {
        if let img = image {
            Task {
                await viewModel.uploadData(image: img)
            }
        }
    }
}

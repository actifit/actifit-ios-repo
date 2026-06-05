//
//  ThreeSpeakVideoViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 07/05/2024.
//

import UIKit
import AVKit
class ThreeSpeakVideoViewController: UIViewController {

  @IBOutlet weak var mainHeightConstraint: NSLayoutConstraint!
  @IBOutlet weak var videoProgressView: UIStackView!
  @IBOutlet weak var imageProgressView: UIStackView!
  @IBOutlet weak var uploadProgressView: UIStackView!
  @IBOutlet weak var displayVideoCollectionView: UICollectionView!
  @IBOutlet weak var playAndSubmitView: UIView!
  @IBOutlet weak var newVideoInfoBtn: UIButton!

  @IBOutlet weak var videosHeightConstraints: NSLayoutConstraint!
  @IBOutlet weak var refreshBtn: UIButton!
  @IBOutlet weak var closeBtn: UIButton!
  @IBOutlet weak var infoBtn: UIButton!
  var videoPickerManager: VideoPickerManager?
  @IBOutlet weak var recordVideoBtn: UIButton!
  @IBOutlet weak var chooseVideoBtn: UIButton!
  @IBOutlet weak var collectionView: UICollectionView!

  @IBOutlet weak var innerView: UIView!
  @IBOutlet weak var uploadedVideoConstraint: NSLayoutConstraint!

  @IBOutlet weak var uploadProcessView: UIView!
  @IBOutlet weak var videoUploadProcessLabel: UILabel!

  @IBOutlet weak var closeBtnConstraint: NSLayoutConstraint!
  @IBOutlet weak var imageUploadProcessLabel: UILabel!
  weak var delegate: ThreeSpeakVideoViewControllerDelegate?
  @IBOutlet weak var scrollView: UIScrollView!
  private var playerView: PlayerView!
  var onVideoSelection: ((Video) -> ())? = nil
  var hideAddToPost: Bool = true
  let viewModel = ThreeSpeakViewModel()
  var selectedVideoURL: URL!
  private var isRefreshRotating = false
  private var rotationAnimation: CABasicAnimation?
  var videoToUpload: ReadyToPublishVideoModel? {
    didSet {
      displayVideoCollectionView.isHidden = false
      UIView.animate(withDuration: 0.3) { // Animate layout changes
                         self.view.layoutIfNeeded()
      }
      scrollView.layoutIfNeeded()
      displayVideoCollectionView.reloadData()
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    setUI()
  }

  func didSelectVideo(_ video: Video) {
        delegate?.videoViewController(self, didPickVideo: video)
    }
  
  func didCancelView() {
    delegate?.videoViewControllerDidCancel(self)
  }

  func changeConstraintMultiplier(_ constraint: inout NSLayoutConstraint, multiplier: CGFloat) {
    // Remove the old constraint
    NSLayoutConstraint.deactivate([constraint])

    // Create a new constraint with the same properties but a different multiplier
    let newConstraint = NSLayoutConstraint(
      item: constraint.firstItem as Any,
      attribute: constraint.firstAttribute,
      relatedBy: constraint.relation,
      toItem: constraint.secondItem,
      attribute: constraint.secondAttribute,
      multiplier: multiplier,
      constant: constraint.constant
    )
    newConstraint.priority = constraint.priority
    newConstraint.identifier = constraint.identifier

    // Add the new constraint
    NSLayoutConstraint.activate([newConstraint])

    // Update the reference to the new constraint
    constraint = newConstraint

    // Force layout update
    UIView.animate(withDuration: 0.3) {
      self.view.layoutIfNeeded()
    }
  }

  private func hideBottomCollectionView() {
    closeBtn.translatesAutoresizingMaskIntoConstraints = false
    self.uploadedVideoConstraint.constant =  0
    closeBtn.bottomAnchor.constraint(equalTo: innerView.bottomAnchor, constant: 15).isActive = false
    view.layoutIfNeeded()
    scrollView.layoutIfNeeded()

  }

  private func showBottomCollectionView() {
    closeBtn.translatesAutoresizingMaskIntoConstraints = false

   self.uploadedVideoConstraint.constant = 410
    UIView.animate(withDuration: 0.3) { // Animate layout changes
    self.view.layoutIfNeeded()

    self.displayVideoCollectionView.reloadData()
    }
    self.scrollView.layoutIfNeeded()

    changeConstraintMultiplier(&mainHeightConstraint, multiplier:  DeviceType.isSmallScreen  ?  2.08 : 1.65)
  }
//582.67


  @IBAction func refreshBtnTapped(_ sender: Any) {
    viewModel.fetchUserVideos()
    startRotation()
  }

  let redLoader: UIActivityIndicatorView = {
    let loader = UIActivityIndicatorView(activityIndicatorStyle: .large)
    loader.color = .red
    loader.translatesAutoresizingMaskIntoConstraints = false
    loader.layer.cornerRadius = 25
    loader.layer.masksToBounds = true
    loader.backgroundColor = UIColor.clear
    loader.frame.size = CGSize(width: 50, height: 50)
    return loader
  }()

  private func setUI() {
   // uploadVideoCollectionViewHeightConstraint.constant = 0
    videosHeightConstraints.constant = 20
    imageUploadProgress(isVisible: false)
    videoUploadProgress(isVisible: false)
    setupRotationAnimation()
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
      self.startRotation()
    })

    recordVideoBtn.layer.cornerRadius = 5
    recordVideoBtn.clipsToBounds = true
    chooseVideoBtn.layer.cornerRadius = 5
    chooseVideoBtn.clipsToBounds = true
    closeBtn.layer.cornerRadius = 5
    closeBtn.clipsToBounds = true
    videoPickerManager = VideoPickerManager()
    videoPickerManager?.delegate = self
    collectionView.register(UINib(nibName: "VideoCell", bundle: nil), forCellWithReuseIdentifier: "VideoCell")
    displayVideoCollectionView.register(UINib(nibName: "VideoCell", bundle: nil), forCellWithReuseIdentifier: "VideoCell")
    setBinding()
    refreshBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.refreshCircle.rawValue, size: 24), for: .normal)
    hideBottomCollectionView()

  }

  func showVideoUploadLoader() {
    redLoader.startAnimating()
    redLoader.isHidden = false
  }

  func hideVideoUploadLoader() {
    redLoader.stopAnimating()
    redLoader.isHidden = true
  }

  private func imageUploadProgress(isVisible: Bool) {
    imageProgressView.isHidden = !isVisible
  }

  private func videoUploadProgress(isVisible: Bool) {
    videoProgressView.isHidden = !isVisible
  }

  private func setupRotationAnimation() {
    rotationAnimation = CABasicAnimation(keyPath: "transform.rotation")
    rotationAnimation?.fromValue = 0
    rotationAnimation?.toValue = CGFloat(Double.pi * 2)
    rotationAnimation?.duration = 1
    rotationAnimation?.repeatCount = .infinity
  }

  private func startRotation() {
    guard let rotationAnimation = rotationAnimation else { return }
    refreshBtn.layer.add(rotationAnimation, forKey: "rotationAnimation")
    isRefreshRotating = true
  }

  private func stopRotation() {
    refreshBtn.layer.removeAnimation(forKey: "rotationAnimation")
    isRefreshRotating = false
  }


  private func setBinding() {
    viewModel.loaderPublisher.sink { showLoader in
      showLoader ? self.showProgressIndicator() : self.hideProgressIndicator()
    }.store(in: &viewModel.cancellables)
    viewModel.refreshPublisher.sink { refresh in
      if self.viewModel.videos.isEmpty {
        self.videosHeightConstraints.constant = 20
      } else {
        self.videosHeightConstraints.constant = 450
        self.collectionView.reloadData()
      }
      self.stopRotation()
      UIView.animate(withDuration: 0.3) { // Animate layout changes
                         self.view.layoutIfNeeded()
      }
    }.store(in: &viewModel.cancellables)

    viewModel.videoProgressPublisher.sink { percentage in
      self.videoUploadProcessLabel.text = "Upload at \(Int(percentage)) %"
      if percentage == 100 {
        self.imageUploadProgress(isVisible: false)
        self.videoUploadProgress(isVisible: false)
        self.showBottomCollectionView()
        self.generateUploadedVideoModel(url: self.selectedVideoURL)

      }
    }.store(in: &viewModel.cancellables)

    viewModel.imageSubjectPublisher.sink { percentage in
      self.imageUploadProcessLabel.text = "Upload at \(Int(percentage)) %"
      if percentage == 100 {
        self.videoUploadProgress(isVisible: true)
       // self.hideVideoUploadLoader()

      }
    }.store(in: &viewModel.cancellables)
    viewModel.showDeleteAlertPublisher.sink { videoIsDeleted in
      self.showAlertWith(title:videoIsDeleted ? "" : "Error", message: videoIsDeleted ? "Video Successfully deleted" : "Please try again.")
      if videoIsDeleted {
        self.startRotation()
        self.viewModel.fetchUserVideos()
      }
    }.store(in: &viewModel.cancellables)

    viewModel.showSuccessSubmitPublisher.sink { value in
      if value {
        self.showToast(message: "Video submitted! Refresh the vids List to confirm ready to publish status.")
        self.displayVideoCollectionView.isHidden = true

//        self.changeConstraintMultiplier(&self.mainHeightConstraint, multiplier: 1.35)
//        self.view.layoutIfNeeded()
        self.imageUploadProcessLabel.text = "Upload at 0 %"
        self.videoUploadProcessLabel.text = "Upload at 0 %"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
          self.startRotation()
          self.viewModel.fetchUserVideos()
        })

      } else {
        self.showToast(message: "Error, Please try again")
      }
    }.store(in: &viewModel.cancellables)
  }

  static func create(hideAddPostBtn: Bool = true, selectedURL: ((Video) -> ())? = nil) -> ThreeSpeakVideoViewController {
    let vc = UIStoryboard(name: "ThreeSpeakVideo", bundle: nil).instantiateViewController(withIdentifier: "ThreeSpeakVideoViewController") as! ThreeSpeakVideoViewController
    vc.modalPresentationStyle = .overFullScreen
    vc.hideAddToPost = hideAddPostBtn
    vc.onVideoSelection = selectedURL
    return vc
  }

  @IBAction func infoBtnTapped(_ sender: Any) {
    self.present(TransparentPopupViewController.create(title: "Actifit Info", description: "List below contains all videos you had previously uploaded and submitted. To include any of those videos onto your actifit report content, you need to be on the Post & Earn screen, and your video status needs to be ready to publish. You can click the refresh button to refresh the status of all videos", cancelButtonText: "CLOSE", noteSize: .medium), animated: true)
  }

  @IBAction func chooseVideoTapped(_ sender: Any) {
    guard let videoPickerManager = videoPickerManager else {
      return
    }
    videoPickerManager.presentVideoPicker(in: self)
  }

  @IBAction func recordVideoTapped(_ sender: Any) {
    guard let videoPickerManager = videoPickerManager else {
      return
    }
    videoPickerManager.recordVideo(in: self)
  }

  @IBAction func newVideoInfoBtnTapped(_ sender: Any) {
    self.present(TransparentPopupViewController.create(title: "Actifit Info", description: "Use either options below (record or upload) to upload a video and submit it to be included in your current uploaded vids list. Please check the info button next to the uploaded vids list for further details", cancelButtonText: "CLOSE", noteSize: .medium), animated: true)
  }

  @IBAction func closeBtnTapped(_ sender: Any) {
    viewModel.stopAllUploadOperations()
    didCancelView()
    dismiss(animated: true)
  }


   func submitVideoTapped() {
    if viewModel.isReadyToSubmit {
      viewModel.submitVideoTo3Speak()
    }
  }
}//showToast(message: "Please login first")

extension ThreeSpeakVideoViewController: VideoPickerDelegate {
  func didSelect(videoUrl: URL) {
    viewModel.isImageReadyToUpload = false
    viewModel.isVideoReadyToUpload = false
    imageUploadProgress(isVisible: true)
    selectedVideoURL = videoUrl
    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
      self.viewModel.uploadThumbnailAndGetURL(url: videoUrl)
    })

    showVideoUploadLoader()
  }

  private func generateUploadedVideoModel(url: URL) {
    let videoSize = "\(String(format: "%.2f", viewModel.getVideoSize(url: url))) MB" //viewModel.getVideoSize(url: url)
    let videoDuration = "\(String(format: "%.2f", viewModel.getVideoDuration(url: url))) sec"
    let videoToUpload = ReadyToPublishVideoModel(videoDuration: videoDuration, videoSize: videoSize, videoURL: url)
    self.videoToUpload = videoToUpload
  }

  // Function to handle canceling video selection
  func didCancel() {
    // Handle cancellation here
    print("Video selection canceled")
  }
}
extension ThreeSpeakVideoViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    if collectionView == displayVideoCollectionView {
      return 1
    }
    return viewModel.videos.count
  }

  func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCell", for: indexPath) as? VideoCell
    if collectionView == displayVideoCollectionView {
      cell?.uploadedVideo = self.videoToUpload
      cell?.backgroundColor = .green
      cell?.onSubmitBtnTapped = {[weak self] in
        self?.submitVideoTapped()
      }
      return cell!
    } else {
      cell?.video = viewModel.videos[indexPath.row]
      if hideAddToPost == false {
        if let status =
            Utils.findMatchingStatus(statusCode:viewModel.videos[indexPath.row].status ?? "") {
          cell?.hideAddPost = !status.contains("Ready to publish")
        }
      }
      cell?.deleteVideoTap = { [weak self] video in
        self?.viewModel.deleteVideo(video: video)
      }
      cell?.onAddToPostTapped = { [weak self] video in
        self?.onVideoSelection?(video)
        self?.didSelectVideo(video)
        self?.dismiss(animated: true)
      }

    }
    return cell!
  }

  func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    return CGSize(width: collectionView.frame.width  , height: collectionView.frame.height)
  }
}

struct DeviceType {

    static let smallScreenMaxWidth: CGFloat = 375.0

    static var isSmallScreen: Bool {
        return UIScreen.main.bounds.width <= smallScreenMaxWidth
    }

    static var isBigScreen: Bool {
        return !isSmallScreen
    }
}

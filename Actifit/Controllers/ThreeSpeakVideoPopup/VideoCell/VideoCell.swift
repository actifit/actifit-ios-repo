//
//  VideoCell.swift
//  Actifit
//
//  Created by Ali Jaber on 07/05/2024.
//

import UIKit
import AVFoundation
class VideoCell: UICollectionViewCell {
  var videoPath = "https://uploads.3speak.tv/files/"
  var player: AVPlayer?
  var playerLayer: AVPlayerLayer?
  var hideAddPost: Bool = true {
    didSet {
      updatePostBtnStatus()
    }
  }
  @IBOutlet weak var playBtn: UIButton!

  @IBOutlet weak var videoTitleConstraint: NSLayoutConstraint!
  @IBOutlet weak var videoTitleView: UIView!
  @IBOutlet weak var cellBackgroundView: UIView!
  @IBOutlet weak var stackView: UIStackView!
  @IBOutlet weak var deleteBtn: UIButton!

  @IBOutlet weak var videoTitleLabel: UILabel!

  @IBOutlet weak var addToPostBtn: UIButton!
  @IBOutlet weak var timePassedLabel: UILabel!
  @IBOutlet weak var durationLabel: UILabel!
  @IBOutlet weak var sizeLabel: UILabel!

  @IBOutlet weak var videoView: UIView!
  var onAddToPostTapped: ((Video) -> ())?
  @IBOutlet weak var statusLabel: UILabel!
  var deleteVideoTap: ((Video) -> Void)?
  var onSubmitBtnTapped: (() -> Void)?

  private var playerView: PlayerView!
  var video: Video? {
    didSet {
      setUI()
    }
  }
  var uploadedVideo: ReadyToPublishVideoModel? {
    didSet {
      setUIForUploadVideo()
    }
  }


  private func setUIForUploadVideo() {
    guard let localVideo = uploadedVideo else { return }
    timePassedLabel.isHidden = true
    durationLabel.text = localVideo.videoDuration
    sizeLabel.text = localVideo.videoSize

    statusLabel.text = "Now"
    deleteBtn.setTitle("SUBMIT", for: .normal)
    deleteBtn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    videoTitleLabel.isHidden = true
    configure(with: localVideo.videoURL)
    videoTitleView.isHidden = true
    videoTitleConstraint.constant = 0
  }

  func updatePostBtnStatus() {
    addToPostBtn.isHidden = hideAddPost
  }
  override func awakeFromNib() {
    super.awakeFromNib()
    setupPlayerView()
    playBtn.layer.cornerRadius = 5
    deleteBtn.layer.cornerRadius  = 5
    addToPostBtn.layer.cornerRadius = 5
    cellBackgroundView.clipsToBounds = false // Set this to false to allow shadow to be visible
    cellBackgroundView.layer.cornerRadius = 10

    // Remove border if any
    cellBackgroundView.layer.borderWidth = 0.5

    // Add shadow
    cellBackgroundView.layer.shadowColor = UIColor.black.cgColor
    cellBackgroundView.layer.shadowOpacity = 0.25
    cellBackgroundView.layer.shadowOffset = CGSize(width: 2, height: 2)
    cellBackgroundView.layer.shadowRadius = 4
    cellBackgroundView.layer.masksToBounds = false
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupPlayerView()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupPlayerView()
  }

  private func setupPlayerView() {
    guard videoView != nil else {return}
    playerView = PlayerView(frame: videoView.bounds)
    playerView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    videoView.addSubview(playerView)
    NotificationCenter.default.addObserver(self,
                                                  selector: #selector(playerDidFinishPlaying),
                                                  name: .AVPlayerItemDidPlayToEndTime,
                                                  object: player)
  }

  deinit {
         NotificationCenter.default.removeObserver(self)
     }

  @objc func playerDidFinishPlaying() {
      playerView.player?.seek(to: kCMTimeZero)
      playBtn.setTitle("PLAY", for: .normal)
  }

  func configure(with url: URL) {
    let playerItem = AVPlayerItem(url: url)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(playerDidFinishPlaying),
                                           name: .AVPlayerItemDidPlayToEndTime,
                                           object: playerItem)
    player = AVPlayer(playerItem: playerItem)
    playerView.player = player
  }

  override func prepareForReuse() {
    super.prepareForReuse()
    playerView.player?.pause()
    playerView.player = nil
    clearPlayer()
  }

  private func clearPlayer() {
    player?.pause()
    player = nil
    playerView.player = nil
  }

  private func setUI() {
    guard let video = video else { return }
    videoTitleLabel.text = video.title
    timePassedLabel.text = Date().timeDifference(from: video.created ?? "", dateFromat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    if let videSize = video.size, videSize > 0 {
      var localVidSize = String(format: "%.2f", videSize)
      if localVidSize == "0.00" {
        localVidSize = "0.01"
      }
      sizeLabel.text =  "\(localVidSize) MB"

    }
    if let duration = video.duration, duration > 0 {
      durationLabel.text = "\(duration) sec"
    }
    playBtn.setTitle("PLAY", for: .normal)
    if let statusDescription = Utils.findMatchingStatus(statusCode: video.status ?? "") {
        let statusString = "Status \(statusDescription.string)"
        let attributedString = NSMutableAttributedString(string: statusString)

        // Apply bold font to the "Status" part
        let boldFont = UIFont.boldSystemFont(ofSize: 17)
        let regularFont = UIFont.systemFont(ofSize: 17)

        attributedString.addAttribute(.font, value: boldFont, range: NSRange(location: 0, length: 6))
        attributedString.addAttribute(.font, value: regularFont, range: NSRange(location: 6, length: statusString.count - 6))

        statusLabel.attributedText = attributedString
    }

    if var videoURL = video.filename {
      if !videoURL.starts(with: "http") {
        videoURL = "https://ipfs-3speak.b-cdn.net/ipfs/\(videoURL.replacingOccurrences(of: "ipfs://", with: ""))"
        configure(with: URL(string: videoURL)!)

      }
    }
  }

  @IBAction func addToPostTapped(_ sender: Any) {
    guard let video = video else { return }
    onAddToPostTapped?(video)
  }


  @IBAction func playBtnTapped(_ sender: Any) {
    if playBtn.titleLabel?.text == "PLAY" {
      playBtn.setTitle("STOP", for: .normal)
      playerView.player?.play()

    } else {
      playBtn.setTitle("PLAY", for: .normal)
      playerView.player?.pause()
     // playerView.player?.seek(to: kCMTimeZero)

    }
  }

  @IBAction func deleteBtnTapped(_ sender: Any) {
    if let video = video {
      deleteVideoTap?(video)
    } else if let localVideo = uploadedVideo  {
      onSubmitBtnTapped?()
    }
  }
}


struct ReadyToPublishVideoModel {
  let videoDuration: String
  let videoSize: String
  let videoURL: URL
  init(videoDuration: String, videoSize: String, videoURL: URL) {
    self.videoDuration = videoDuration
    self.videoSize = videoSize
    self.videoURL = videoURL
  }
}

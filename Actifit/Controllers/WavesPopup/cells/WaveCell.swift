//
//  WaveCell.swift
//  Actifit
//
//  Created by Ali Jaber on 06/04/2024.
//

import UIKit
import Down
import libcmark
import WebKit
class WaveCell: UITableViewCell {

    @IBOutlet weak var waveTypeImageView: UIImageView!
    @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var profileImageView: UIImageView!
  @IBOutlet weak var commentTimePassLabel: UILabel!
  @IBOutlet weak var bodyLabel: UILabel!
  @IBOutlet weak var monetaryBtn: UIButton!

  @IBOutlet weak var subStackView: UIStackView!
  @IBOutlet weak var childRepliesView: UIView!
  @IBOutlet weak var mainStackView: UIStackView!
  @IBOutlet weak var revertTranslateView: UIView!
  @IBOutlet weak var activityCountLabel: UILabel!
  @IBOutlet weak var activityCountView: UIView!
  @IBOutlet weak var sandHourImageView: UIImageView!
  @IBOutlet weak var sumPayoutLabel: UILabel!

  @IBOutlet weak var translateBtn: UIButton!
  @IBOutlet weak var subStackViewHeight: NSLayoutConstraint!
  @IBOutlet weak var actualCommentHeight: NSLayoutConstraint!
  @IBOutlet weak var commentsCountLabel: UILabel!
  @IBOutlet weak var upvoteCountLabel: UILabel!
  @IBOutlet weak var replyBtn: UIButton!
  let networkManager =  HTTPClient()
  var downView: DownView?
  var downViewHeightConstraint: NSLayoutConstraint?
  var didVoteForComment: Bool? {
    didSet {
      updateVoteFrontColor()
    }
  }
  private let textView: UITextView = {
    let textView = UITextView()
    textView.isScrollEnabled = false
    textView.isEditable = false
    textView.translatesAutoresizingMaskIntoConstraints = false
    return textView
  }()
  @IBOutlet weak var upvoteBtn: UIButton!
  @IBOutlet weak var shareBtn: UIButton!
  @IBOutlet weak var commentsInCommentsBtn: UIButton!
  var onReplyTapped: ((PostComments?) -> Void)?
  var onUpvoteTapped: ((PostComments?) -> Void)?
  var onShareTapped: ((PostComments?) -> Void)?
  var reloadCell: (()-> Void)?
  var childComments: [PostComments] = []
  private var activityIndicator: UIActivityIndicatorView!
  var comment: PostComments? {
    didSet {
      setUI()
    }
  }

  var wave: PostsResults? {
    didSet {
      DispatchQueue.main.async {
        self.updateSumLabel()
      }

    }
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    tableView.register(UINib(nibName: "WaveCell", bundle: nil), forCellReuseIdentifier: "WaveCell")
    mainStackView.layer.cornerRadius = 10
    mainStackView.layer.shadowOffset = CGSize(width: 0, height: 1)
    mainStackView.layer.shadowOpacity = 0.2
    mainStackView.layer.shadowColor = UIColor.darkGray.cgColor
    mainStackView.layer.shadowRadius = 10
    mainStackView.backgroundColor = .white
    replyBtn.layer.cornerRadius = 5
    shareBtn.layer.cornerRadius = 5
    shareBtn.clipsToBounds = true
    commentsInCommentsBtn.layer.cornerRadius = 5
    commentsInCommentsBtn.clipsToBounds = true
    upvoteBtn.layer.cornerRadius = 5
    upvoteBtn.clipsToBounds = true
    replyBtn.clipsToBounds = true
    commentsInCommentsBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.chatIcon.rawValue, size: 20), for: .normal)
    shareBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.shareIcon.rawValue, size: 20), for: .normal)
    translateBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.translate.rawValue, size: 16), for: .normal)
    translateBtn.layer.cornerRadius = 5
    translateBtn.clipsToBounds = true
  }

  override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

  }

  @IBAction func revertTranslationTapped(_ sender: Any) {
    if let commentId = comment?.id {
      let content = TranslationManager.sharedInstance.getOriginalContent(waveId: commentId)
      configure(with: content)
      TranslationManager.sharedInstance.removeTransitionById(waveId: commentId)
      revertTranslateView.isHidden = true
    }
  }
  

  @IBAction func translateBtnTapped(_ sender: Any) {
    if let content = comment?.body, let commentID = comment?.id {
      if TranslationManager.sharedInstance.isWaveTranslated(waveId: commentID) {
        revertTranslationTapped(self)
        return
      }
      Task {
        try? await translateContent(content: content)
      }
    }
  }

  func translateContent(content: String) async {
    let translatedContent = await networkManager.translate(content: content)
    switch translatedContent {
    case .success(let success):
      TranslationManager.sharedInstance.addWave(originalContent: comment?.body ?? "", updatedContent: success.translations.first?.text ?? "", waveId: comment?.id ?? 0)
      configure(with: success.translations.first?.text ?? "")
      revertTranslateView.isHidden = false
    case .failure(let failure):
      print("Unable to translate content. Try again later")
    }
  }


  private func updateVoteFrontColor() {
    guard let vote = didVoteForComment, vote == true else {
      upvoteBtn.tintColor = .white
      return
    }
    upvoteBtn.tintColor = .primaryGreenColor()
    if let countAsString = upvoteCountLabel.text, let count = Int(countAsString) {
      let finalCount = count + 1
      upvoteCountLabel.text = "\(finalCount)"
    }
  }

  private func setUI() {
    childRepliesView.isHidden = true
    guard let comment = comment else { return }
      waveTypeImageView.image = UIImage(named: comment.isSnap ?  "snap_comment": "ecency_comment")
    activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .large)
    activityIndicator.color = .gray
    activityIndicator.translatesAutoresizingMaskIntoConstraints = false
    contentView.addSubview(activityIndicator)
    NSLayoutConstraint.activate([
      activityIndicator.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      activityIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      activityIndicator.heightAnchor.constraint(equalToConstant: 100),
      activityIndicator.widthAnchor.constraint(equalToConstant: 100)
    ])
    activityIndicator.isHidden = true
    monetaryBtn.setAttributedTitle(NSAttributedString.generateFontAwesomeString(code: AwesomeButtonCodes.monetary.rawValue, size: 40), for: .normal)

    usernameLabel.text = "@\(comment.author)"
    //  bodyLabel.text = comment.body
    profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
    profileImageView.clipsToBounds = true
    setUserImage(username: comment.author)
    commentTimePassLabel.text =  Date().timeDifference(from: comment.created)
      extractStepCount(from: "\(comment.jsonMetadata?.stepCount?.first ?? 0)")
    if TranslationManager.sharedInstance.isWaveTranslated(waveId: comment.id) == true {
      revertTranslateView.isHidden = false
      configure(with:TranslationManager.sharedInstance.getTranslatedContentById(waveId: comment.id))
    } else {
      revertTranslateView.isHidden = true
      configure(with: comment.body)
    }
    upvoteCountLabel.text = "\(comment.activeVotes?.count ?? 0)"
    commentsCountLabel.text = "\(comment.children)"
    if let username = User.current()?.steemit_username, let activeVotes = comment.activeVotes {
      if activeVotes.count > 0 {
        if ((activeVotes.contains(where: {$0.voter ==  username}))) {
          upvoteBtn.tintColor = .primaryGreenColor()
        } else {
          upvoteBtn.tintColor = .white
        }
      }
    }
  }

  

  func stopLoading() {
    DispatchQueue.main.async {
      self.activityIndicator.stopAnimating()
      self.activityIndicator.isHidden = true
    }
  }


  private func setUserImage(username: String) {
    Task {
      do {
        let image = try await ApplicationHelper().fetchUserImage(finalUsername: username)
        profileImageView.image = image
      } catch {
        print(error.localizedDescription)
      }

    }
  }

  @IBAction func upvoteBtnTapped(_ sender: Any) {
    onUpvoteTapped?(comment)
  }

  @IBAction func shareBtnTapped(_ sender: Any) {
    onShareTapped?(comment)
  }

  @IBAction func replyBtnTapped(_ sender: Any) {
    onReplyTapped?(comment)
  }

  @IBAction func subCommentsTap(_ sender: Any) {
    childRepliesView.isHidden = !childRepliesView.isHidden
    reloadCell?()
    if !childRepliesView.isHidden {
      self.startLoading()
      loadChildCommentsFromAPI(author: comment?.author ?? "", permlink: comment?.permlink ?? "")
    }
  }

  func startLoading() {
    activityIndicator.isHidden = false
    activityIndicator.startAnimating()
  }

  private func loadChildCommentsFromAPI(author: String, permlink: String) {

    API().loadComments(author: author, permlink: permlink) { info, statusCode in
      if let response = info as? String {

        let data = response.utf8Data()
        let decoder = JSONDecoder()
        do {
          let results = try decoder.decode(HivePostComment.self, from: data)
          self.childComments = results.result
          DispatchQueue.main.async {
            self.stopLoading()
            if !results.result.isEmpty {
              self.tableView.delegate = self
              self.tableView.dataSource = self
              self.tableView.reloadData()
            }
          }
        } catch {
          print("Error decoding JSON: \(error.localizedDescription)")
        }
      }
    } failure: { error in
    }
  }


  private func updateSumLabel() {
    guard let result = wave else { return }
    var sumPayout = 0.0
    if let totalPayoutValue = result.totalPayoutValue {
      sumPayout = Double(totalPayoutValue.replacingOccurrences(of: " HBD", with: ""))!
    }
    if let pendingPayoutValue = result.pendingPayoutValue {
      sumPayout += Double(pendingPayoutValue.replacingOccurrences(of: " HBD", with: ""))!
    }
    if let curatorPayoutValue = result.curatorPayoutValue {
      sumPayout += Double(curatorPayoutValue.replacingOccurrences(of: " HBD", with: ""))!
    }
    if let authorPayoutValue = result.authorPayoutValue {
      sumPayout += Double(authorPayoutValue.replacingOccurrences(of: " HBD", with: ""))!
    }
    sumPayoutLabel.text = "\(sumPayout)"
    if result.isPaidout == true {
      sandHourImageView.image = UIImage(systemName: "checkmark")
    } else {
      sandHourImageView.image = UIImage(named: "sandhour")
    }

  }

  func extractStepCount(from steps: String)  {
    guard let jsonData = steps.data(using: .utf8) else {
      print("Failed to convert JSON string to Data.")
      activityCountView.isHidden = true
      return
    }

    do {
      if let json = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
      {

        if let stepCount = json["step_count"] as? String {
          activityCountView.isHidden = false
          activityCountLabel.text = stepCount
        } else {
          print("No step count found.")
          activityCountView.isHidden = true
        }
      } else {
        print("Failed to parse JSON.")
        activityCountView.isHidden = true
      }
    } catch {
      print("Error parsing JSON: \(error.localizedDescription)")
      activityCountView.isHidden = true
    }
  }


  func markdownToHTML(_ markdown: String) -> String? {
    // Use cmark to convert Markdown to HTML
    guard let cmarkHtml = cmark_markdown_to_html(markdown, markdown.utf8.count, CMARK_OPT_DEFAULT) else {
      return nil
    }
    return String(cString: cmarkHtml)
  }

  func configure(with markdownString: String) {
    // Remove previous DownView if it exists
    downView?.removeFromSuperview()

    // Initialize new DownView with the provided markdown content
    downView = try? DownView(frame: .zero, markdownString: markdownString)
    guard let downView = downView else { return }
    downView.pageZoom = 1.5
    downView.translatesAutoresizingMaskIntoConstraints = false
    downView.scrollView.isScrollEnabled = false // Disable scrolling in DownView
   // subStackView.addArrangedSubview(downView)
    let index = max(subStackView.arrangedSubviews.count - 1, 0)
    subStackView.insertArrangedSubview(downView, at: index - 1)
    NSLayoutConstraint.activate([
      downView.leadingAnchor.constraint(equalTo: subStackView.leadingAnchor),
      downView.trailingAnchor.constraint(equalTo: subStackView.trailingAnchor),
    ])

    // Set initial height constraint for downView
    downViewHeightConstraint = downView.heightAnchor.constraint(equalToConstant: 100)
    downViewHeightConstraint?.isActive = true

    // Observe the content size change
    downView.navigationDelegate = self
  }
}

extension WaveCell: WKNavigationDelegate {
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
      webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] (height, error) in
        guard let self = self, let height = height as? CGFloat else { return }
        self.downViewHeightConstraint?.isActive = false
        self.downViewHeightConstraint = self.downView?.heightAnchor.constraint(equalToConstant: height + 20)
        self.downViewHeightConstraint?.isActive = true
        self.contentView.setNeedsLayout()
        self.contentView.layoutIfNeeded()
        self.subStackView.setNeedsLayout()
        self.subStackView.layoutIfNeeded()
        reloadCell?()
    }
  }
}


extension WaveCell: UITableViewDelegate, UITableViewDataSource {
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "WaveCell") as! WaveCell
    cell.comment = childComments[indexPath.row]
    cell.selectionStyle = .none
    cell.onReplyTapped = { [weak self] comment in
      self?.onReplyTapped?(comment)
    }
    cell.onUpvoteTapped = {[weak self] comment in
      self?.onUpvoteTapped?(comment)

    }
    cell.onShareTapped = { [weak self] comment in
      self?.onShareTapped?(comment)
    }
    cell.reloadCell = { [weak self] in
      DispatchQueue.main.async {
        self?.tableView.beginUpdates()
        self?.tableView.endUpdates()

      }
    }
    return cell
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return childComments.count
  }
}




//
//  SocialView.swift
//  Actifit
//
//  Created by Ali Jaber on 13/09/2024.
//

import SwiftUI
import MarkdownUI
import Down
struct SocialView: View {
    @State private var webContentHeight: CGFloat = .zero
    @ObservedObject var viewModel = SocialViewModel()
    @State var expandedCommentIds: [String: [PostComments]] = [:]
    @State var isSharePresented = false
    @State private var expandedPosts: [String: Bool] = [:]
    @State private var loadedComments: [String: [PostComments]] = [:]
    @State private var estimatedHeigt: CGFloat = 150
    @State private var contentHeights: [String: CGFloat] = [:]
    @StateObject private var translationManager = TranslationContentManager()
    let networkManager =  HTTPClient()

    var body: some View {
        VStack {
            HStack {
                Text("Actifit Reports ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.leading, 15)
                    .padding(.bottom, 5)

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.primaryRedColor()))
            ScrollView {
                LazyVStack {
                    // Key on the stable author+permlink uid, NOT postId: Hive's get_ranked_posts no
                    // longer returns a post id, so postId is nil for every post — identical ForEach
                    // ids made SwiftUI render only ONE row and blank the rest. (uid is globally
                    // unique; a bare permlink is only unique per author.)
                    ForEach(viewModel.socialPosts, id: \.uid) { socialPost in
                        socialPostView(post: socialPost)
                            .background(.white)
                            .padding(.horizontal, 8)
                            .onAppear{
                                if viewModel.isLastItem(socialPost) {
                                    Task {
                                        await viewModel.getSocialPosts(author: socialPost.author, permlink: socialPost.permlink)
                                        }
                                    }
                            }

                        Rectangle()
                            .frame(height: 20)
                            .foregroundStyle(.thinMaterial)
                    }
                }
            }
            // On the ScrollView (not the inner stack) so the pull gesture actually triggers.
            .refreshable {
                await viewModel.refreshPosts(replace: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: .socialTabDidAppear)) { _ in
                Task { await viewModel.refreshPosts(minInterval: 60) }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name.UIApplicationWillEnterForeground)) { _ in
                Task { await viewModel.refreshPosts(minInterval: 60) }
            }
            .overlay {
                if viewModel.showLoader {
                    ProgressView()
                }
            }
            .overlay {
                if viewModel.showReply {
                    if let author = viewModel.selecteReport?.author {
                        ZStack {
                            Color.black.opacity(0.5)
                                .edgesIgnoringSafeArea(.all)
                            ReplyView(author: author, onReplyTapped: {reply in
                                Task {
                                    await viewModel.addCommentReply(reply: reply, stepCount: viewModel.selecteReport?.jsonMetadata.stepCount.first ?? "", appVersion: "1.0", author: viewModel.selecteReport?.author ?? "", permlink: viewModel.selecteReport?.permlink ?? "")
                                }
                                viewModel.showReply = false
                            }, onCancelTapped: {
                                viewModel.showReply = false
                            })

                            .frame(width: UIScreen.main.bounds.width * 0.95)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    } else if let author = viewModel.commentToReplyOn?.author {
                        ZStack {
                            Color.black.opacity(0.5)
                                .edgesIgnoringSafeArea(.all)
                            ReplyView(author: author, onReplyTapped: {reply in
                                Task {
                                    await viewModel.addCommentReply(reply: reply, stepCount: String(viewModel.commentToReplyOn?.jsonMetadata?.stepCount?.first ?? 0) , appVersion: "1.0", author: author, permlink: viewModel.commentToReplyOn?.permlink ?? "")
                                }
                                viewModel.showReply = false
                            }, onCancelTapped: {
                                viewModel.showReply = false
                            })

                            .frame(width: UIScreen.main.bounds.width * 0.95)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .overlay {
                if viewModel.showUpvote {
                    ZStack {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                        UpvoteToReward(author: viewModel.selecteReport?.author ?? "", onActionTap: { action in
                            switch action {
                            case .close:
                                viewModel.showUpvote = false
                            case .onVoterListTapped:
                                viewModel.showVoterList = true
                            case .upvote(let amount):
                                viewModel.upvoteTap(socialPost: viewModel.selecteReport!, vote: amount)
                            }
                        })
                        .frame(width: UIScreen.main.bounds.width * 0.95)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .overlay {
                if viewModel.showVoterList {
                    ZStack {
                        Color.black.opacity(0.5)
                            .edgesIgnoringSafeArea(.all)
                        VotersList(voterList: viewModel.selecteReport?.activeVotes ?? [], onCloseTap: {
                            viewModel.showVoterList = false
                        })
                        .frame(width: UIScreen.main.bounds.width * 0.95)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
        }
        .sheet(isPresented: $isSharePresented) {
            if let selecteReport = viewModel.selecteReport {
                let url = "http://actifit.io/\(selecteReport.author)\(selecteReport.permlink)"
                ShareSheet(items: ["Check out this cool report on Actifit!\(url)"])
            } else if let commentToReplyOn = viewModel.commentToReplyOn {
                let url = "http://actifit.io/\(commentToReplyOn.author)\(commentToReplyOn.permlink)"
                ShareSheet(items: ["Check out this cool report on Actifit!\(url)"])
            }
        }
        .alert("", isPresented: $viewModel.showAlert, actions: {
            Button("OK") {
                viewModel.showAlert = false
            }

        }, message: {
            Text(viewModel.alertMessage)
        })
        .background(.thinMaterial)
        .frame(maxWidth: .infinity)
    }

    func socialPostView(post: SocialPost) -> some View {
        VStack(alignment: .leading) {
            Text(post.title)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(.gray)
            HStack{
                AsyncImage(url:URL(string: viewModel.generateProfileURL(author: post.author))){ image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                Text("@\(post.author)")
                    .foregroundStyle(Color(uiColor: .primaryRedColor()))
                Spacer()
                Text(Date().timeDifference(from: post.created ?? "") ?? "")
                    .foregroundStyle(Color(uiColor: .primaryRedColor()))
            }.padding(.top, 5)

            VStack {
                if expandedPosts["\(post.author)-\(post.permlink)"] == false || expandedPosts["\(post.author)-\(post.permlink)"] == nil {
                    // No image, or one that fails to load, shows nothing rather than a
                    // spinner that never stops.
                    if let imageURL = URL(string: headerImage(for: post) ?? "") {
                        AsyncImage(url: imageURL) { phase in
                            switch phase {
                            case .success(let image):
                                // Fill the card's width at a fixed height, cropping the overflow
                                // (as the actifit.io cards do) instead of a small letterboxed thumb.
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 200)
                                    .overlay(image.resizable().scaledToFill())
                                    .clipped()
                            case .empty:
                                ProgressView().frame(maxWidth: .infinity).frame(height: 200)
                            default:
                                EmptyView()
                            }
                        }
                    }
                }

                // Each post keeps its own measured height. A single shared value meant every
                // card's web view overwrote it, so an expanded post took whichever height was
                // reported last and showed a block of empty space under its content.
                DownViewRepresentable(markdownText:  generateMarkdownText(for: post, expandedPosts: expandedPosts, translationManager: translationManager),
                                      contentHeight: Binding(get: { contentHeights[post.uid] ?? estimatedHeigt },
                                                             set: { contentHeights[post.uid] = $0 }),
                                      measuresContent: expandedPosts["\(post.author)-\(post.permlink)"] == true)
                    .frame(height:  expandedPosts["\(post.author)-\(post.permlink)"] == true ? (contentHeights[post.uid] ?? estimatedHeigt) : 100)
                    .edgesIgnoringSafeArea(.all)
                    .id(expandedPosts["\(post.author)-\(post.permlink)"] == true ? "expanded-\(post.author)-\(post.permlink)" : "collapsed-\(post.author)-\(post.permlink)")
            }
            HStack {
                Spacer()
                Button {
                    translateBtnTapped(post: post)
                } label: {
                    Image("translate")
                        .resizable()
                        .frame(width: 50, height: 35)
                }

            }.padding(.bottom, 20)
            HStack {
                VStack(alignment: .leading) {
                    Text("Activity Type")
                        .foregroundStyle(.gray)
                        .font(.system(size: 18, weight: .bold))
                    if let activityTypes = post.jsonMetadata.activityType {
                        Text(activityTypes.joined(separator: ", "))
                            .foregroundStyle(Color(uiColor: .primaryGreenColor()))
                    }
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("Activity Count")
                        .foregroundStyle(.gray)
                        .font(.system(size: 18, weight: .bold))
                    Text(post.jsonMetadata.stepCount.first ?? "")
                        .foregroundStyle(Color(uiColor: .primaryRedColor()))
                }
            }.padding(.horizontal, 10)
            HStack {
                Image("money-bill")
                    .resizable()
                    .frame(width: 35, height: 25)
                    .padding(.leading, 25)
                Text("\(viewModel.grabPostPayout(post: post)) HBD")
                    .foregroundStyle(Color(uiColor: .primaryRedColor()))
                    .padding(.leading, 10)
                if viewModel.isPostPaid(post: post) {
                    Image("sandhour")
                } else {
                    Image("checkmark")
                }
                Image("hive-icon")
                Spacer()
                Text(String("\(viewModel.postRewards[post.author] ?? 0) AFIT"))
                    .foregroundStyle(.gray)
                    .font(.system(size: 18, weight: .medium))
                Image("actifit-mini-icon")
                Spacer()
            }
            HStack {
                Spacer()
                Button(action: {
                    viewModel.showReply = true
                    viewModel.selecteReport = post
                }, label: {
                    Image("back")
                })
                .foregroundStyle(.white)
                .background(Color(uiColor: .primaryGreenColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                Spacer()

                Button(action: {
                    viewModel.showUpvote = true
                    viewModel.selecteReport = post
                }, label: {
                    Image(systemName: "hand.thumbsup.fill")
                        .resizable()
                        .frame(width: 20, height: 20)

                })
                .frame(width: 30, height: 30)
                .foregroundStyle(.white)
                .background(Color(uiColor: .primaryGreenColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                Spacer()
                Text(String(post.activeVotes?.count ?? 0))
                    .foregroundStyle(Color(uiColor: .primaryGreenColor()))
                Spacer()
                Button(action: {
                    if loadedComments.keys.contains("\(post.author)-\(post.permlink)") {
                        loadedComments["\(post.author)-\(post.permlink)"] = nil
                        viewModel.subCommentsArray.removeAll { subComment in
                            subComment.parentId == "\(post.author)-\(post.permlink)"
                        }
                    } else {
                        viewModel.selecteReport = post
                        Task {
                            let comments = await viewModel.getPostComments(author: post.author, permlink: post.permlink)
                            loadedComments["\(post.author)-\(post.permlink)"] = comments
                            viewModel.subCommentsArray.append(SubComment(parentId: "\(post.author)-\(post.permlink)", children: comments))
                        }
                    }
                }, label: {
                    Image("chat")
                        .resizable()
                        .frame(width: 20, height: 20)
                        .background(Color(uiColor: .primaryGreenColor()))
                })
                .frame(width: 30, height: 30)
                .background(Color(uiColor: .primaryGreenColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                Spacer()
                Text(String(post.children))
                    .foregroundStyle(Color(uiColor: .primaryGreenColor()))
                Spacer()
                Button {
                    togglePostExpansion(postId: "\(post.author)-\(post.permlink)")
                } label: {
                    Image("bottom_arrow")
                        .rotationEffect(.degrees( expandedPosts["\(post.author)-\(post.permlink)"] == true ? 180 : 0))
                        .background(Color(uiColor: .primaryGreenColor()))
                }
                .clipShape(RoundedRectangle(cornerRadius: 5))
                Spacer()
                Button {
                    viewModel.selecteReport = post
                    isSharePresented = true
                } label: {
                    Image("share")
                        .background(Color(uiColor: .primaryGreenColor()))
                        .frame(width: 20, height: 20)

                }
                .frame(width: 30, height: 30)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                Spacer()
            }
            if(loadedComments.keys.contains("\(post.author)-\(post.permlink)")) {
                commentView(comments: loadedComments["\(post.author)-\(post.permlink)"] ?? [])
            }
        }
        .padding(.horizontal, 8)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
            .onAppear {
                Task{
                    await viewModel.getReportReward(user: post.author, reportURL: post.url)
                }
            }
    }

    func generateMarkdownText(for post: SocialPost, expandedPosts: [String: Bool], translationManager: TranslationContentManager) -> String {
        let postId = "\(post.author)-\(post.permlink)"
        if let translatedContent = translationManager.translationContent.first(where: { $0.objectId == postId })?.translatedContent {
               // Return the translated content if expanded, otherwise a short text preview
               return expandedPosts[postId] == true ? translatedContent : previewText(translatedContent)
           }

           // Fallback to the original content if no translation is available
           return expandedPosts[postId] == true ? post.body : previewText(post.body)
        }

    /// Collapsed-card preview: the first readable text of the post. Cutting the raw body at
    /// 140 characters left an empty card whenever the body opened with blank lines, HTML or an
    /// image, because the cut landed mid-tag or mid-URL and rendered as nothing.
    func previewText(_ body: String) -> String {
        var text = body
        let rules: [(String, String)] = [
            ("!\\[[^\\]]*\\]\\([^)]*\\)", " "),          // markdown images
            ("\\[([^\\]]*)\\]\\([^)]*\\)", "$1"),        // markdown links -> their text
            ("<[^>]+>", " "),                                // HTML tags
            ("https?://\\S+", " "),                         // bare URLs
            ("\\s+", " ")                                    // collapse whitespace
        ]
        for (pattern, replacement) in rules {
            text = text.replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
        }
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.count > 140 ? String(text.prefix(140)) + "…" : text
    }

    /// Header image for a feed card: the author's first real image, from the post metadata or,
    /// for posts that list none there (often those made outside the Actifit apps), from the body.
    func headerImage(for post: SocialPost) -> String? {
        return rawHeaderImage(for: post).map(proxiedImageURL)
    }

    private func rawHeaderImage(for post: SocialPost) -> String? {
        let meta = post.jsonMetadata
        // Metadata order is the author's order, so the first real image is their own photo.
        // The stock Actifit banners every report carries are only used when nothing else exists
        // (preferring "has a file extension" picked the banner over extension-less iOS uploads).
        let listed = ((meta.images ?? []) + (meta.image ?? [])).filter { $0.hasPrefix("http") }
        if let own = listed.first(where: { !isStockBanner($0) }) { return own }
        let pattern = "!\\[[^\\]]*\\]\\((https?://[^)\\s]+)\\)|<img[^>]+src=[\"'](https?://[^\"']+)[\"']"
        if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) {
            let matches = regex.matches(in: post.body, range: NSRange(post.body.startIndex..., in: post.body))
            for m in matches {
                for i in 1...2 {
                    if let r = Range(m.range(at: i), in: post.body), !isStockBanner(String(post.body[r])) {
                        return String(post.body[r])
                    }
                }
            }
        }
        return listed.first
    }

    /// Actifit's own report-template graphics (banners, separators, the ACTIVITY DATE / COUNT /
    /// TYPE labels, tracker icons) that every report carries. Ported from the blocklist the
    /// actifit.io feed uses (excludedImagePatterns in actifit-landingpage/plugins/commonCardMixin.js)
    /// so a card never shows one of these in place of a real photo.
    private func isStockBanner(_ url: String) -> Bool {
        if SocialView.stockImageHashes.contains(where: { url.contains($0) }) { return true }
        let patterns = ["s3\\.us-east-1\\.amazonaws\\.com/actifit\\.io\\.website/",
                        "ACTIVITY(DATE|COUNT|TYPE)\\.png", "TRACKM\\.png",
                        "/(h1|w1a|bd1|w1|t1|c1)\\.png", "/actifit-"]
        return patterns.contains { url.range(of: $0, options: [.regularExpression, .caseInsensitive]) != nil }
    }

    private static let stockImageHashes: [String] = [
        "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"
    ]

    /// Routes an image through the Hive image proxy, as the actifit.io feed does
    /// (getResizedImageUrl in actifit-landingpage). The proxy fetches and caches server-side,
    /// so third-party hosts that throttle or block direct hotlinking (e.g. pixabay.com/get)
    /// still load. Same exclusions as the web: the proxy can't serve usermedia.actifit.io,
    /// and gif / leopedia are used directly.
    private func proxiedImageURL(_ url: String) -> String {
        let lower = url.lowercased()
        if !lower.hasPrefix("http") || lower.hasSuffix(".gif") || lower.contains("leopedia.io")
            || lower.contains("usermedia.actifit.io") || lower.contains("images.hive.blog") {
            return url
        }
        return "https://images.hive.blog/640x0/" + url
    }

    func togglePostExpansion(postId: String) {
        if expandedPosts.keys.contains(postId) {
            if expandedPosts[postId] == false {
                expandedPosts[postId] = true
            } else {
                expandedPosts[postId] = false
            }
        } else {
            expandedPosts[postId] = true
        }
    }


    func getBodyContent(body: String, id: String) -> String {
        if expandedPosts[id] == true {
            return body
        } else {
            return String(body.prefix(140))
        }
    }

    func convertMarkdownToAttributedString(markdown: String) -> NSAttributedString? {
        let down = Down(markdownString: markdown)
        return try? down.toAttributedString()
    }

    func postIsExpanded(postId: String) -> Bool {
        if loadedComments.keys.contains(postId) {
            return true
        }
        return false
    }

    @ViewBuilder
    func commentView(comments: [PostComments])  -> some View {
        ChildCommentView(subComments: viewModel.subCommentsArray, onActionTap: { action in
            viewModel.selecteReport = nil
            switch action {
            case .getComment(let comment):
                if loadedComments.keys.contains("\(comment.author)-\(comment.permlink)") {
                    loadedComments["\(comment.author)-\(comment.permlink)"] = nil
                } else {
                    viewModel.commentToReplyOn = comment
                    Task {
                        let comments = await viewModel.getPostComments(author: comment.author, permlink: comment.permlink)
                        viewModel.subCommentsArray.append(SubComment(parentId: "\(comment.author)-\(comment.permlink)", children: comments))
                       // loadedComments["\(comment.author)-\(comment.permlink)"] = comments
                    }
                }
            case .showReply(let comment):
                viewModel.selecteReport = nil
                viewModel.commentToReplyOn = comment
                viewModel.showReply = true
            case .showShare(let url, let comment):
                viewModel.commentToReplyOn = comment
                isSharePresented = true
            print(url)
            case .upvote(let comment):
                viewModel.commentToReplyOn = comment
                viewModel.showUpvote = true
            }

        })
            .frame(height: 300)
    }

    func revertTranslationTapped(post: SocialPost) {
        translationManager.translationContent.removeAll(where: {$0.objectId == "\(post.author)-\(post.permlink)"})
    }


    func translateBtnTapped(post: SocialPost) {
        if  translationManager.translationContent.contains(where: {$0.objectId == "\(post.author)-\(post.permlink)"}) {
          revertTranslationTapped(post: post)
            translationManager.translationContent.removeAll(where: {$0.objectId == "\(post.author)-\(post.permlink)"})
            togglePostExpansion(postId: "\(post.author)-\(post.permlink)")
          return
        }
        Task {
            await translateContent(post: post)
        }
      }

    func translateContent(post: SocialPost) async {
    let translatedContent = await networkManager.translate(content: post.body)
      switch translatedContent {
      case .success(let success):
          DispatchQueue.main.async {
              translationManager.translationContent.append(TranslatedContent(objectId: "\(post.author)-\(post.permlink)", originalContent: post.body, translatedContent: success.translations.first?.text ?? ""))
              togglePostExpansion(postId: "\(post.author)-\(post.permlink)")
          }
      case .failure(let failure):
          print(failure.localizedDescription)
      }
    }

}

#Preview {
    SocialView()
}


struct SubComment {
    let parentId: String //permlink + author
    let children: [PostComments]
}

struct TranslatedContent {
    let objectId: String
    let originalContent: String
    let translatedContent: String
}

class TranslationContentManager: ObservableObject {
    @Published var translationContent: [TranslatedContent] = []
    func updateTranslations() {
            objectWillChange.send()
        }
}

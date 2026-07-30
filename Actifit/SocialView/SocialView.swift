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
            .background(Color(UIColor.primaryRedColor()))
//            .frame(height: 40)
            ScrollView {
                LazyVStack {
                    // Key on permlink, NOT postId: Hive's get_ranked_posts no longer returns a
                    // post id, so postId is nil for every post — identical ForEach ids made SwiftUI
                    // render only ONE row and leave the rest blank. Permlink is unique per report.
                    ForEach(viewModel.socialPosts, id: \.permlink) { socialPost in
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
                .refreshable {
                    Task {
                       await viewModel.getSocialPosts(author: "", permlink: "")
                    }
                }
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
                    AsyncImage(url:URL(string: getImageFromMetadata(metaData: post.jsonMetadata) ?? "")){ image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        ProgressView()
                    }
                    .frame(height: 100)
                    .clipShape(Rectangle())
                }

                DownViewRepresentable(markdownText:  generateMarkdownText(for: post, expandedPosts: expandedPosts, translationManager: translationManager), contentHeight: $estimatedHeigt)
                    .frame(height:  expandedPosts["\(post.author)-\(post.permlink)"] == true ? estimatedHeigt : 100)
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
               // Return the translated content if expanded, otherwise limit it to 140 characters
               return expandedPosts[postId] == true ? translatedContent : String(translatedContent.prefix(140))
           }

           // Fallback to the original content if no translation is available
           return expandedPosts[postId] == true ? post.body : String(post.body.prefix(140))
        }

    func getImageFromMetadata(metaData: Metadata) -> String? {
        if let images = metaData.images {
            return images.first{$0.contains(find: ".png")
            }
        }
        else if let image = metaData.image {
            return image.first{$0.contains(find: ".png")
            }
        } else {
            return nil
        }
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

//
//  ChildCommentView.swift
//  Actifit
//
//  Created by Ali Jaber on 28/10/2024.
//

import SwiftUI
import FontAwesome_swift
enum Actions {
    case showReply(comment: PostComments)
    case showShare(url: String, comment: PostComments)
    case getComment(comment: PostComments)
    case upvote(comment: PostComments)
}
struct ChildCommentView: View {
    let subComments: [SubComment]
   // let comments: [PostComments]
    var onActionTap: (Actions) -> ()

    var body: some View {
        List {
            ForEach(subComments, id: \.parentId) { parentComment in
                ForEach(parentComment.children, id: \.id) { subComment in
                    CommentRow(comment: subComment) { action in
                        switch action {
                        case .showReply(let comment):
                            onActionTap(.showReply(comment: comment))
                        case .showShare(let url, let comment):
                            onActionTap(.showShare(url: url, comment: comment))
                        case .getComment(let comment):
                            onActionTap(.getComment(comment: comment))
                        case .upvote(let comment):
                            onActionTap(.upvote(comment: comment))
                        }
                    }
                }

            }
        }
    }
}

#Preview {
    ChildCommentView(subComments: [], onActionTap: { action in

    })
}

struct CommentRow: View {
    @StateObject var viewModel = SocialViewModel()
    let comment: PostComments
    var onActionTap: (Actions) -> ()
    @State var estimatedHeight: CGFloat = 100.0
    var body: some View {
        VStack {
            HStack {
                AsyncImage(url: URL(string: viewModel.generateProfileURL(author: comment.author))) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    ProgressView()
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                Text("@\(comment.author)")
                Spacer()
                Text(Date().timeDifference(from: comment.created) ?? "")
                    .foregroundStyle(Color(uiColor: .primaryRedColor()))
            }
            HStack {
                Spacer()
                Button {
                    print("")
                } label: {
                    Image("translate")
                        .resizable()
                        .frame(width: 50, height: 35)
                }
            }
            DownViewRepresentable(markdownText: comment.body, contentHeight: $estimatedHeight)

            HStack {
                Spacer()
                Image("money-bill")
                    .resizable()
                    .frame(width: 40, height: 30)
                Text("0")
                Image("sandhour")
                Image("hive-icon")
                Spacer()
            }

            HStack(spacing: 20) {
                Button(action: {
                    onActionTap(.showReply(comment: comment))
                    return
                }) {
                    Image("back")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .frame(width: 30, height: 30)
                .foregroundStyle(.white)
                .background(Color(uiColor: .primaryGreenColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .buttonStyle(BorderlessButtonStyle())

                Button(action: {
                    onActionTap(.upvote(comment: comment))
                    return
                }) {
                    Image(systemName: "hand.thumbsup.fill")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .frame(width: 30, height: 30)
                .foregroundStyle(.white)
                .background(Color(uiColor: .primaryGreenColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))

                Text(String(comment.children))

                Button(action: {
                    onActionTap(.getComment(comment: comment))
                }) {
                    Image("chat")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .frame(width: 30, height: 30)
                .foregroundStyle(.white)
                .background(Color(uiColor: .primaryGreenColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .buttonStyle(BorderlessButtonStyle())

                Text("\(comment.children)")

                Button(action: {
                    onActionTap(.showShare(url: "http://actifit.io/\(comment.author)\(comment.permlink)", comment: comment))
                    return
                }) {
                    Image("share")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .frame(width: 30, height: 30)
                .foregroundStyle(.white)
                .background(Color(uiColor: .primaryGreenColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .frame(height: 300)

    }
}

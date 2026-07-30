//
//  SocialViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 14/09/2024.
//

import Foundation
import UIKit

class SocialViewModel: ObservableObject {
    enum AlertMessages {
        case successReply
        case successUpvote
        case failureReply
        case failureUpvote
        var alertMessage: String {
            switch self {
            case .successReply:
                return "Comment Sent Successfully!"
            case .successUpvote:
                return "Upvote Sent Successfully!"
            case .failureReply, .failureUpvote:
                return "Error, please try again"
            }
        }
    }
    
    var alertMessage: String = ""
    @Published var selecteReport: SocialPost? = nil
    @Published var commentToReplyOn: PostComments? = nil
    @Published var socialPosts: [SocialPost] = []
    @Published var showReply: Bool = false
    @Published var showUpvote: Bool = false
    @Published var showVoterList: Bool = false
    @Published var showShare: Bool = false
    @Published var postRewards: [String: Int] = [:]
    @Published var reply: String = ""
    @Published var showLoader: Bool = false
    @Published var showAlert: Bool = false
    @Published var subCommentsArray:[SubComment] = []
  
    init() {
        Task {
           await getSocialPosts()
        }
    }

    func showReplyView(report: SocialPost) {
        self.selecteReport = report
        showReply.toggle()
    }

    func isLastItem(_ item: SocialPost) -> Bool {
         return item == socialPosts.last
     }

    func getSocialPosts(author: String? = nil, permlink: String? = nil) async {
        showLoader = true
        let posts = await HTTPClient().getSocialPosts(author: author, permlink: permlink)
        showLoader = false
        switch posts {
        case .success(let posts):
            if socialPosts.isEmpty {
                socialPosts = posts.result
            } else {
                // Only append posts we don't already have (keyed by author+permlink) so overlapping
                // pagination fetches can't duplicate the feed.
                let existing = Set(socialPosts.map { $0.uid })
                socialPosts.append(contentsOf: posts.result.filter { !existing.contains($0.uid) })
            }
        case .failure(let failure):
            print(failure.localizedDescription)
        }
    }

//    guard let username = User.current()?.steemit_username else { return }
//    loaderSubject.send(true)
//    let opName = "vote"
//    var customParams: [String:Any] =
//    [
//      "author": comment.author,
//      "permlink": comment.permlink,
//      "voter": username,
//      "weight": Int(vote * 100)
//    ]
//    var metadata: [String: Any] = [:]
//
//    let tagsBody = ["hive-193552", "actifit"]
//
//    metadata["tags"] = tagsBody
//    metadata["app"] = "actifit"



    func upvoteTap(socialPost: SocialPost, vote: Int) {
        guard let username = User.current()?.steemit_username else { return }
        showLoader = true
        let opName = "vote"
        var customParams: [String:Any] =
        [
            "author": socialPost.author,
            "permlink": socialPost.permlink,
            "voter": username,
            "weight": Int(vote * 100)
        ]
        var metadata: [String: Any] = [:]

        let tagsBody = ["hive-193552", "actifit"]

        metadata["tags"] = tagsBody
        metadata["app"] = "actifit"
        do {
            let metaDataJsonString  = try? JSONSerialization.data(withJSONObject: metadata, options: [])
            if let jsonString = String(data: metaDataJsonString!, encoding: .utf8) {
                customParams["json_metadata"] = jsonString
                API().createWave(body: customParams, username: User.current()?.steemit_username ?? "", comment: opName) { info, statusCode in
                    print(info)
                    print(statusCode)
                    self.showLoader = false
                    self.alertMessage = statusCode == 200 ? AlertMessages.successUpvote.alertMessage : AlertMessages.failureUpvote.alertMessage
                    self.showAlert = true
                    self.showUpvote = false
                } failure: { error in
                    self.alertMessage = AlertMessages.failureUpvote.alertMessage
                    self.showAlert = true
                    self.showUpvote = false
                }
            }
        }
        catch {
            print(error.localizedDescription)
        }
    }

    func addCommentReply(reply: String, stepCount: String, appVersion: String, author: String, permlink: String) async {
     // loaderSubject.send(true)
      let opName = "comment"
      let commentPerm = "\((User.current()?.steemit_username.replacingOccurrences(of: ".", with: "-")) ?? "") -re-\(author)-\(permlink)\(Date().converToServerDate())".lowercased().replacingOccurrences(of: ".", with: "-").replacingOccurrences(of: "[^a-zA-Z0-9-]+", with: "", options: .regularExpression)
      var customParams: [String:Any] =
      [
        "author": User.current()?.steemit_username ?? "",
       "permlink": commentPerm,
       "title": "",
       "body" : reply,
        "parent_author": author,
        "parent_permlink" : permlink

      ]
      var metadata: [String: Any] = [:]

      let tagsBody = ["hive-193552", "actifit"]

      metadata["tags"] = tagsBody
      metadata["app"] = "actifit"
      metadata["step_count"] = stepCount
      metadata["appVersion"] = appVersion
      do {
        let metaDataJsonString  = try? JSONSerialization.data(withJSONObject: metadata, options: [])
        if let jsonString = String(data: metaDataJsonString!, encoding: .utf8) {
          customParams["json_metadata"] = jsonString
            showLoader = true
          await API().createWave(body: customParams, username: User.current()?.steemit_username ?? "", comment: opName) { info, statusCode in
              self.alertMessage = AlertMessages.successReply.alertMessage
              self.showAlert = true
              self.showLoader = false
              self.showReply = false
          } failure: { error in
              self.alertMessage = AlertMessages.failureReply.alertMessage
              self.showAlert = true
              self.showReply = false
            print(error.localizedDescription)
          }
        }
      }
      catch {
        print(error.localizedDescription)
      }
    }


    func getReportReward(user: String, reportURL: String) async {
        let reward = await HTTPClient().getPostRewards(user: user, reportURL: reportURL)
        switch reward {
        case .success(let reward):
            DispatchQueue.main.async {
                self.postRewards[user] = reward.tokenCount
            }
        case .failure(let failure):
            print(failure.localizedDescription)
        }
    }

    func isPostPaid(post: SocialPost) -> Bool {
        return post.isPaidout ?? false
    }

    func preprocessHTMLTags(_ markdown: String) -> String {
        var processedMarkdown = markdown

        // Handle <br> tags
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<br>", with: "\n")

        // Handle <div> tags by removing them
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<div[^>]*>", with: "", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</div>", with: "")

        // Handle <center> tags
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<center>", with: "")
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</center>", with: "")

        // Handle <p> tags
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<p>", with: "\n\n")
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</p>", with: "\n\n")

        // Handle <pre> tags
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<pre[^>]*>", with: "```\n", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</pre>", with: "\n```\n", options: .regularExpression)

        // Handle <table> tags
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<table[^>]*>", with: "", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</table>", with: "\n", options: .regularExpression)

        // Handle <tr> tags (table rows)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<tr[^>]*>", with: "", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</tr>", with: "\n", options: .regularExpression)

        // Handle <td> and <th> tags (table data and headers)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<td[^>]*>", with: "| ", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</td>", with: " ", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<th[^>]*>", with: "| **", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</th>", with: "** ", options: .regularExpression)

        // Handle <img src> tags and convert to Markdown image syntax
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<img src=\"([^\"]+)\"[^>]*>", with: "![]($1)", options: .regularExpression)

        // Handle Markdown-style images
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "!\\[\\]\\(([^)]+)\\)", with: "![]($1)", options: .regularExpression)

        // Handle <a href> tags
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<a href=\"([^\"]+)\">([^<]+)</a>", with: "$2 (link: $1)", options: .regularExpression)

        // Handle <b> and <strong> tags for bold text
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<(b|strong)>", with: "**", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</(b|strong)>", with: "**", options: .regularExpression)

        // Handle <i> and <em> tags for italic text
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<(i|em)>", with: "_", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</(i|em)>", with: "_", options: .regularExpression)

        // Handle headers
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<h1[^>]*>([^<]+)</h1>", with: "# $1\n", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<h2[^>]*>([^<]+)</h2>", with: "## $1\n", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<h3[^>]*>([^<]+)</h3>", with: "### $1\n", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<h4[^>]*>([^<]+)</h4>", with: "#### $1\n", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<h5[^>]*>([^<]+)</h5>", with: "##### $1\n", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<h6[^>]*>([^<]+)</h6>", with: "###### $1\n", options: .regularExpression)

        // Handle unordered lists <ul> and ordered lists <ol>
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<ul[^>]*>", with: "", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</ul>", with: "", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<ol[^>]*>", with: "", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</ol>", with: "", options: .regularExpression)

        // Handle list items <li>
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "<li[^>]*>", with: "- ", options: .regularExpression)
        processedMarkdown = processedMarkdown.replacingOccurrences(of: "</li>", with: "\n", options: .regularExpression)
        return processedMarkdown
       // return parsHTMLMarkdown(processedMarkdown)
    }

    func parsHTMLMarkdown(_ markdown: String) -> [MarkdownComponent] {
        var components: [MarkdownComponent] = []

        // Basic regex for some common HTML tags like <div>, <p>, <br>, etc.
        let htmlTagRegex = try? NSRegularExpression(pattern: "<(/?\\w+)[^>]*>", options: [])

        let lines = markdown.split(separator: "\n")

        for line in lines {
            let lineStr = String(line)
            if let headerMatch = lineStr.range(of: #"^(#+)\s*(.*)"#, options: .regularExpression) {
                       let headerLevel = lineStr[headerMatch].prefix(while: { $0 == "#" }).count
                       let headerText = lineStr[headerMatch].replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)

                       // Add the header as a Markdown component based on the level
                       let markdownHeader = String(repeating: "#", count: headerLevel) + " " + headerText
                       components.append(MarkdownComponent(text: markdownHeader))
                       continue
                   }

            // Check if the line contains an HTML tag
            if let htmlMatch = htmlTagRegex?.firstMatch(in: lineStr, options: [], range: NSRange(location: 0, length: lineStr.utf16.count)) {
                let tagRange = Range(htmlMatch.range, in: lineStr)
                if let tagRange = tagRange {
                    let tagContent = String(lineStr[tagRange])

                    // Handle specific HTML tags (like <br>, <div>, etc.)
                    if tagContent == "<br>" {
                        components.append(MarkdownComponent(text: "\n"))
                    } else if tagContent.starts(with: "<div") || tagContent.starts(with: "<p") {
                        // Assuming you want to treat div and p tags as text containers
                        let text = lineStr.replacingOccurrences(of: tagContent, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                        if !text.isEmpty {
                            components.append(MarkdownComponent(text: text))
                        }
                    }
                }
            }

            // Handle Markdown image and link parsing
            if let nestedImageRange = line.range(of: "![]("),
               let nestedLinkRange = line.range(of: "[![]("),
               let nestedLinkEndRange = line.range(of: ")]", range: nestedLinkRange.upperBound..<line.endIndex) {

                let linkStart = nestedLinkRange.upperBound
                let linkEnd = line.range(of: ")", range: linkStart..<line.endIndex)?.lowerBound ?? nestedLinkEndRange.lowerBound
                let imageLinkStart = nestedImageRange.upperBound
                let imageLinkEnd = line.range(of: ")", range: imageLinkStart..<line.endIndex)?.lowerBound ?? linkEnd
                let imageURLString = String(line[imageLinkStart..<imageLinkEnd])
                let linkURLString = String(line[linkStart..<linkEnd])

                if let imageURL = URL(string: imageURLString), let linkURL = URL(string: linkURLString) {
                    components.append(MarkdownComponent(imageURL: imageURL, link: linkURL))
                }

            } else if line.starts(with: "![") && line.contains("](") {
                if let urlStartIndex = line.range(of: "](")?.upperBound,
                   let urlEndIndex = line.range(of: ")", range: urlStartIndex..<line.endIndex)?.lowerBound {
                    let urlString = String(line[urlStartIndex..<urlEndIndex])
                    if let url = URL(string: urlString) {
                        components.append(MarkdownComponent(imageURL: url))
                    }
                }
            } else {
                // If it's just text, add it as a text component
                components.append(MarkdownComponent(text: lineStr))
            }
        }

        return components
    }

    func getPostComments(author: String, permlink: String) async -> [PostComments] {
        showLoader = true
        let comments = await HTTPClient().getComments(author: author, permlink: permlink)
        showLoader = false
        switch comments {
        case .success(let comment):
            print(comments)
            return comment.result
        case .failure(let failure):
            print(failure.localizedDescription)
            return []
        }
    }

    func grabPostPayout(post: SocialPost) -> String {
        if let totalPayoutValue = post.totalPayoutValue, let finalPostPayout = Double(totalPayoutValue.replacingOccurrences(of: "[^\\d.]", with: "") ) {
            if finalPostPayout != 0 {
                return totalPayoutValue
            }

        } else if let authorPayoutValue = post.authorPayoutValue, let finalAuthorPayoutValue = Double(authorPayoutValue.replacingOccurrences(of: "[^\\d.]", with: "")) {
            if finalAuthorPayoutValue != 0 {
                return authorPayoutValue
            }

        } else if let pendingPayoutValue = post.pendingPayoutValue, let finalPendingPayoutValue = Double(pendingPayoutValue.replacingOccurrences(of: "[^\\d.]", with: "")) {
            if finalPendingPayoutValue != 0 {
                return pendingPayoutValue
            }
        }
        return "0.0"
    }

    func generateProfileURL(author: String) -> String {
        return "https://images.hive.blog/u/" + author + "/avatar"
    }

    func uploadImage(image: UIImage) async {
        DispatchQueue.main.async {
            self.showLoader = true
        }

        do {
            let imageURL = try await ImageUploadManager().uploadImage(image)
            DispatchQueue.main.async {
                self.showLoader = false
                self.reply = self.reply + "\n" + imageURL
            }
        } catch {
            print(error.localizedDescription)
            DispatchQueue.main.async {
                    self.showLoader = false
            }
        }
    }
}

//func uploadImage(image: UIImage) async {
//    DispatchQueue.main.async {
//        self.showLoader = true
//    }
//
//    let deviceUUID: String = await (UIDevice.current.identifierForVendor?.uuidString)!
//    let filename = deviceUUID + String(Date().ticks)
//
//    do {
//        let imageURL = try await ImageUploadManager().uploadImage(image)
//
//        DispatchQueue.main.async {
//            self.showLoader = false
//
//            if let data = UserDefaults.standard.postContent {
//                let newContent = data + "\n" + (imageURL + " " + "\n")
//                UserDefaults.standard.postContent = newContent
//                self.markDownContent = newContent
//            } else {
//                self.markDownContent = imageURL
//                UserDefaults.standard.postContent = imageURL
//            }
//        }
//    } catch {
//        DispatchQueue.main.async {
//            self.showLoader = false
//        }
//        print(error.localizedDescription)
//    }
//}

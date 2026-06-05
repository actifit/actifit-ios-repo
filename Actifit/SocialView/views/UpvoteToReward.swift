//
//  UpvoteToReward.swift
//  Actifit
//
//  Created by Ali Jaber on 08/10/2024.
//

import SwiftUI

struct UpvoteToReward: View {
    enum Actions {
        case onVoterListTapped
        case close
        case upvote(amount: Int)
    }
    @State private var upvoteAmount: Int = 50
    var author: String
    var onActionTap: (Actions) -> Void
    var body: some View {
        VStack {
            HStack {
                Image("")
                Text("Upvote to reward")
            }
            Text("Voting @\(author)'s content")
            HStack {
                Button(action: {
                    upvoteAmount -= 10
                }, label: {
                    Text("-10%")
                        .foregroundStyle(.white)
                        .padding(8)
                })
                .background(Color(uiColor: .primaryRedColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))

                Text("\(upvoteAmount)")
                Text("%")

                Button(action: {
                    upvoteAmount += 10
                }, label: {
                    Text("+10%")
                        .foregroundStyle(.white)
                        .padding(8)

                })
                .background(Color(uiColor: .primaryRedColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))

            }

            HStack {
                Button(action: {
                    onActionTap(.close)
                }, label: {
                    Text("CLOSE")
                        .foregroundStyle(.white)
                        .padding(8)

                })
                .background(Color(uiColor: .primaryRedColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))

                Button(action: {
                    onActionTap(.onVoterListTapped)
                }, label: {
                    Text("VOTERS LIST")
                        .foregroundStyle(.white)
                        .padding(8)
                })
                .background(Color(uiColor: .primaryRedColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))

                Button(action: {
                    onActionTap(.upvote(amount: upvoteAmount))
                }, label: {
                    Text("UPVOTE")
                        .foregroundStyle(.white)
                        .padding(8)
                })
                .background(Color(uiColor: .primaryRedColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))
            }
        }
        .padding()
        .background(.white)
    }
}

#Preview {
    UpvoteToReward(author: "@aliJaber", onActionTap: { _ in

    })
}

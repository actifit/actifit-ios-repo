//
//  VotersList.swift
//  Actifit
//
//  Created by Ali Jaber on 08/10/2024.
//

import SwiftUI

struct VotersList: View {
    var voterList: [Vote] = []
    var onCloseTap: () -> Void
    var body: some View {
        VStack {
            HStack{
                Image("actifit-mini-icon")
                Text("Voters list")
            }
           List {
                ForEach(voterList, id: \.voter) { voter in
                    HStack(spacing: 10) {
                        if let voter = voter.voter {
                            NetworkImage(imageURL: URL(string: "https://images.hive.blog/u/\(voter)/avatar")!)
                            Text(voter)
                        }
                    }
                }
            }
            HStack {
                Spacer()
                Button(action: {
                    onCloseTap()
                }, label: {
                    Text("CLOSE")
                        .foregroundStyle(Color(uiColor: .primaryRedColor()))
                })
            }
            .padding()
        }
        .padding()
        .background(.white)
    }
}

#Preview {
    VotersList(onCloseTap:  {

    })
}

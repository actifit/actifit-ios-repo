//
//  PostSubmittionAlert.swift
//  Actifit
//
//  Created by Ali Jaber on 19/07/2024.
//

import SwiftUI

struct PostSubmittionAlert: View {
    enum Actions {
        case viewPost
        case share
        case dismiss
    }
    
    var didPostSuccessfully: Bool
    var action: (Actions) -> ()
    var body: some View {
        VStack(spacing: 10) {
            Image(didPostSuccessfully ? "success" : "error")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
            Text(didPostSuccessfully ? "Success" : "Failure")
                .foregroundStyle(.black)
                .font(.system(size: 20, weight: .bold))
            
            Text( didPostSuccessfully ? Messages.success_post : Messages.failed_post)
                .foregroundStyle(.black)
                .font(.system(size: 16, weight: .medium))
                .padding(.bottom, 10)
            
            HStack {
                if didPostSuccessfully {
                    Button {
                        action(.viewPost)
                    } label: {
                        Text("VIEW POST")
                    }
                    Spacer()
                    Button {
                        action(.share)
                    } label: {
                        Text("SHARE")
                    }
                    .padding(.trailing, 20)
                }
                Button {
                    action(.dismiss)
                } label: {
                    Text( didPostSuccessfully ? "DISMISS" : "OK")
                }
            }
            .foregroundStyle(.red)
            .font(.system(size: 18, weight: .medium))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    PostSubmittionAlert(didPostSuccessfully: false, action: { _ in
    })
}

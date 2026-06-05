//
//  MarkDownInfoView.swift
//  Actifit
//
//  Created by Ali Jaber on 19/07/2024.
//

import SwiftUI

struct MarkDownInfoView: View {
  var onCloseTapped: () -> Void
    var body: some View {
      VStack(alignment: .center) {
        HStack(spacing: 5){
          Image("actifit-mini-icon")
            .font(.system(size: 12))
          Text("Minimum Characters Requirement")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(.black)
        }.padding(.bottom, 10)
        Text("A minimum of 100 characters is required in your post content. The more quality/lengthier content you provide, the better!")
          .font(.system(size: 14, weight: .regular))
          .foregroundStyle(.black)
          .padding(.bottom, 20)

        HStack {
          Spacer()
          Button(action: {
            onCloseTapped()
          }, label: {
            Text("CLOSE")
              .font(.system(size: 18, weight: .medium))
              .foregroundStyle(Color(.primaryRedColor()))
          })
        }
        .padding(.bottom, 20)
      }
      .padding()
      .background(.white)
    }
}

#Preview {
  MarkDownInfoView(onCloseTapped: {
    
  })
}

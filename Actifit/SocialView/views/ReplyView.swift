//
//  ReplyView.swift
//  Actifit
//
//  Created by Ali Jaber on 04/10/2024.
//

import SwiftUI

struct ReplyView: View {
    @StateObject var viewModel = SocialViewModel()
    var author: String
    @State var showImagePicker = false
    @State private var isPickerPresented = false
    @State private var selectedImage: UIImage?
    var onReplyTapped:(String) -> Void?
    var onCancelTapped:() -> Void?

    var body: some View {
        VStack(alignment:.leading) {
            HStack {
                VStack(alignment:.leading) {
                    Text("Replying to \(author)")
                        .padding(.vertical, 16)
                        .font(.system(size: 26, weight: .medium))
                        .foregroundStyle(Color.gray)
                    TextView(text: $viewModel.reply, placeholder: "Reply with something cool!")
                       .frame(height: 50)
                      .background(Color.white)
                      .cornerRadius(10)
                }
                Button(action: {
                    isPickerPresented = true
                }, label: {
                    Image(systemName: "photo")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundStyle(.red)
                })
                .clipShape(RoundedRectangle(cornerRadius: 5))

            }
            Divider()
                .background(.red)
                .frame(height: 1)
            MarkDownView(markdownText: viewModel.reply)
               // .frame(height: 100)
            HStack {
                Button(action: {
                    onCancelTapped()
                }, label: {
                    Text("Cancel")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: 45)
                })
                .background(Color(uiColor: .primaryRedColor()))
                .clipShape(RoundedRectangle(cornerRadius: 5))


                Button(action: {
                    onReplyTapped(viewModel.reply)
                }, label: {
                    Text("Reply")
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity, maxHeight: 45)

                })
                .background(Color(uiColor: .primaryRedColor()))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)

        .background(.white)
        .sheet(isPresented: $isPickerPresented) {
          PhotoPicker(isPresented: $isPickerPresented, selectedImage: $selectedImage)
        }
        .onChange(of: selectedImage, perform: { value in
          if let image = value {
              Task {
                  await viewModel.uploadImage(image:  image)
              }
          }
        })
    }


}

#Preview {
    ReplyView(author: "@Ali", onReplyTapped: { reply in

    }, onCancelTapped: {

    })
}

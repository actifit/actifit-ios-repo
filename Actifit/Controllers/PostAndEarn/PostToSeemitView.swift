//
//  PostToSeemitView.swift
//  Actifit
//
//  Created by Ali Jaber on 15/07/2024.
//

import SwiftUI
import SafariServices
import _PhotosUI_SwiftUI
import Combine
import MarkdownUI
struct PostToSeemitView: View {
  @State private var isVideoPickerPresented = false
  @ObservedObject var viewModel = PostToSeemitViewModel2()
  @StateObject private var authManager = FitBitAuthenticationManager()
  @StateObject var coordinator: Coordinator
  @State var showSyncSheet = false
  @State private var showFitbitLogin = false
  @State var showImagePicker = false
  @State private var isPickerPresented = false
  @State private var selectedImage: UIImage?
  @State var postContent = ""
  @State private var isPulsing = false
  enum FocusedField: Int, CaseIterable {
      case markdown, postTitle, reportTags, height, weigth, bodyFat, waist, thigs, chest
  }

  @FocusState var focusedField: FocusedField?
  var body: some View {
    VStack(spacing: 0) {
      topNavigationBar
    ScrollView {
        submitButton
          .padding(.top, 10)
          .scaleEffect(isPulsing ? 1 : 0.9)
          .onAppear {
              withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
              ) {
                  isPulsing = true // Start pulsing animation
              }
          }

      titleHeader(digit: "1", title: "Report Title")
        tagsAndTitleTextField(text: $viewModel.postTitle, focusType: .postTitle)
        titleHeader(digit: "2", title: "Activity Date")
        activityDates
      titleHeader(digit: "3", title: "Activity Count", redTitle: !viewModel.isStepsValid)
        activityCount(steps: $viewModel.stepCount)
      titleHeader(digit: "4", title: "Activity Type", redTitle: viewModel.isActivityTypeEmpty)
        activityTypeButton
        titleHeader(digit: "5", title: "Track Measurements")
        trackMeasurements
      titleHeader(digit: "6", title: "Report Tags", redTitle: viewModel.isReportTagsEmpty)
        tagsAndTitleTextField(text: $viewModel.reportTags, focusType: .reportTags)
      titleHeader(digit: "7", title: "Activity Report Content", redTitle: viewModel.isContentValid)
        markDownTopSection
      }
    }
    .toolbar {
        ToolbarItemGroup(placement: .keyboard) {
          Spacer()
            Button("Done") {
              focusedField = nil
            }
            .foregroundColor(.blue)
        }
    }
    .ignoresSafeArea(edges: .top)
    .onAppear {
      viewModel.postTitle =  "\(Messages.default_post_title)\(viewModel.todayDateStringWithFormat(format: "MMMM d yyyy"))"
      viewModel.getInitialMarkdownContent()
    }

    .sheet(isPresented: $viewModel.showActivityTypes, content: {
      NewActivityTypesView(activities: viewModel.activityTypes, selectedActivities: viewModel.selectedActivities, onDoneTapped: { selectedActivities in
        viewModel.showActivityTypes = false
        if selectedActivities.isEmpty {
          viewModel.selectedActivities = ["Activity Type"]
        } else {
          viewModel.selectedActivities = selectedActivities
        }
      })
    })
    .actionSheet(isPresented: $showSyncSheet) {
      ActionSheet(
        title: Text("Sync your data from"),
        message: Text("Please Select an Option"),
        buttons: [
          .default(Text("FitBit")) {
            authManager.login()
          },
          .default(Text("Watch/Health App")) {
            UserDefaults.standard.isThirdPartySensor = false
            if viewModel.isToday {
              viewModel.btnTodayTapped()
            } else {
              viewModel.btnYesterdayTapped()
            }
          },

          .cancel()
        ]
      )
    }
    .alert("", isPresented: $viewModel.showMinStepsAlert, actions: {
      Button("OK") {
        viewModel.showMinStepsAlert = false
      }

    }, message: {
      Text("\(Messages.min_activity_steps_count_error) \(PostMinActivityStepsCount) activity yet ")
    })

      .alert("", isPresented: $viewModel.showMinCharsAlert, actions: {
        Button("OK") {
          viewModel.showMinCharsAlert = false
        }

      }, message: {
        Text(Messages.min_word_count_error + "\(PostContentMinCharsCount) " + Messages.characters_plural_label)
      })

      .alert("", isPresented: $viewModel.showNoActivitiesAlert, actions: {
        Button("OK") {
          viewModel.showNoActivitiesAlert = false
        }

      }, message: {
        Text(Messages.error_need_select_one_activity)
      })
    .alert("", isPresented: $viewModel.showCharityAlert, actions: {
      Button("YES") {
        viewModel.showCharityAlert = false
      }
      Button("NO") {
        viewModel.showCharityAlert = false
      }
    }, message: {
      Text("\(Messages.current_workout_going_charity) \(viewModel.settings?.charityDisplayName) based on your settings choice. Are you sure you want to proceed?")
    })
    .alert("", isPresented: $viewModel.showSuccessPosting, actions: {
      Button("Continue") {
        coordinator.action = .dismiss
      }
     
    }, message: {
      Text(Messages.success_post)
    })
    .alert("", isPresented: $viewModel.showNotReachedMinimumAlert, actions: {
      Button("YES") {
        viewModel.showNotReachedMinimumAlert = false
        viewModel.triggerCharityAlert()
      }
      Button("NO") {
        viewModel.showNotReachedMinimumAlert = false
      }
    }, message: {
      Text("You have not reached the minimum 5,000 activity count yet to earn rewards. Post anyway?")
    })

    .sheet(isPresented: $authManager.showSafari) {
      SafariView(url: URL(string: "https://www.fitbit.com/oauth2/authorize?response_type=token&client_id=" + AppCenter.clientID + "&redirect_uri=" + AppCenter.redirectURI + "&scope=" + AppCenter.defaultScope + "&expires_in=604800")!)
    }
    .sheet(isPresented: $isPickerPresented) {
      PhotoPicker(isPresented: $isPickerPresented, selectedImage: $selectedImage)
    }
    .onChange(of: authManager.isAuthorized) { newValue in
      if let authenticationToken = authManager.authenticationToken {
        viewModel.authorizationDidFinish(authToken: authenticationToken, fitbitId: authManager.fitBitUserId)
      }
    }
    .onChange(of: selectedImage, perform: { value in

            if let image = value {
                Task {
                    await viewModel.uploadImage(image:  image)
                }
            
        }
    })
    .onChange(of: viewModel.selectedActivities, perform: { value in
      if viewModel.selectedActivities.count > 1 {
          viewModel.selectedActivities.removeAll { activity in
              return activity == "Activity Type"
          }
      }
    })
    .onDisappear{
      coordinator.action = nil
    }
    .onChange(of: viewModel.markDownContent) { value in
      viewModel.updatePostContent(content: value)
    }
    .overlay {
      if viewModel.showLoader {
          ProgressView()
      }
    }
    .overlay {
      if viewModel.postState != .none {
        ZStack {
          Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
          PostSubmittionAlert(didPostSuccessfully: viewModel.postState == .success ? true : false, action: { action in
            switch action {
            case .viewPost:
                coordinator.action = .viewPost(url: "http://actifit.io/\(viewModel.username)/\(viewModel.activityPostModel?.permlink ?? "")")
              //TODO: open safari
            case .share:
              coordinator.action = .sharePost(url: "http://actifit.io/\(viewModel.username)/\(viewModel.activityPostModel?.permlink ?? "")")
            case .dismiss:
              viewModel.postState = .none
              if viewModel.postState == .success {
                coordinator.action = .dismiss
              }
            }
          })
        }
      }
    }
    .overlay {
      if viewModel.showMarkDownInfoAlert {
        ZStack {
          Color.black.opacity(0.5)
            .edgesIgnoringSafeArea(.all)
          MarkDownInfoView {
            viewModel.showMarkDownInfoAlert = false
          }
          .frame(width: UIScreen.main.bounds.width * 0.95)
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
      }
    }
    .sheet(isPresented: $isVideoPickerPresented, content: {
      ThreeSpeakVideoView(isPresented: $isVideoPickerPresented, video: $viewModel.selectedVideo)
    })
    .onChange(of: viewModel.selectedVideo, perform: { value in
      viewModel.handle3speakVideo()
    })
    .navigationBarHidden(true)
  }

    var topNavigationBar: some View {
        ZStack {
            HStack {
                Button(action: {
                    coordinator.action = .dismiss
                }, label: {
                    Image(systemName: "chevron.backward")
                        .foregroundStyle(.white)
                })
                Spacer()
            }

            Text("Post And Earn")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .padding(.top, 50)
        .padding(.leading, 20)
        .padding(.bottom, 10)
        .background(Color(.primaryRedColor()))
    }

  @ViewBuilder
  var submitButton: some View {
    Button(action: {
      if viewModel.stepCountInDigit < 5000 {
        viewModel.showNotReachedMinimumAlert = true
      } else {
        viewModel.triggerCharityAlert()
      }


    }, label: {
      Text("POST & EARN")
        .font(.system(size: 16, weight: .medium))
        .padding(.vertical, 5)
        .frame(maxWidth: .infinity)
        .foregroundStyle(.white)
        .background(Color(.primaryRedColor()))
        .clipShape(.rect(cornerRadius: 2))
        .padding(.horizontal, 100)
    })

  }

  func titleHeader(digit: String, title: String, redTitle: Bool = false) -> some View {
    HStack {
      Text(digit)
        .foregroundColor(Color(uiColor: redTitle ? .primaryRedColor() : .primaryGreenColor()))
        .font(.headline)
        .frame(width: 25, height: 25)
        .background(Circle().fill(Color.white))
        .overlay(Circle().stroke(Color(uiColor: redTitle ? .primaryRedColor() : .primaryGreenColor()), lineWidth: 3))
      Text(title)
      Spacer()
    }.padding()
  }

  func tagsAndTitleTextField(text: Binding<String>, focusType: FocusedField) -> some View {
    VStack {
      TextField("", text: text)
        .focused($focusedField, equals: focusType)
      Rectangle()
        .frame(height: 1)
    }
    .padding()
  }

  var activityDates: some View {
    VStack(spacing: 5) {
      HStack {
        Button(action: {
          viewModel.btnTodayTapped()
        }, label: {
          ZStack {
            radioButtonBorder
            if viewModel.isToday {
              radioButtonCircle
            }
          }
        })
        Text("Today")
        Spacer()
      }
      HStack {
        Button(action: {
          viewModel.btnYesterdayTapped()
        }, label: {
          ZStack {
            radioButtonBorder
            if !viewModel.isToday {
              radioButtonCircle
            }
          }
        })
        Text("Yesterday")
        Spacer()
      }
    }.padding()
  }

  func activityCount(steps: Binding<String>) -> some View {
    HStack {
      VStack {
        TextField("", text: steps)
          .multilineTextAlignment(.center)
          .disabled(true)
          .foregroundStyle(Color(.primaryGreenColor()))
        Rectangle()
          .frame(height: 1)
      }.frame(width: 100)
      Button(action: {
        showSyncSheet = true
      }, label: {
        Text("WEARABLE SYNC")
          .font(.system(size: 16, weight: .medium))
          .padding(5)
          .foregroundStyle(.white)
          .background(Color(.primaryRedColor()))
          .clipShape(.rect(cornerRadius: 2))

      })
      Spacer()
    }.padding()
  }

  var radioButtonBorder: some View {
    Circle()
      .fill(Color.white)
      .frame(width: 30, height: 30)
      .overlay {
        Circle().stroke(Color.gray, lineWidth: 2)
      }
  }

  var radioButtonCircle: some View {
    Circle()
      .fill(Color(.primaryRedColor()))
      .frame(width: 20, height: 20)
  }

  var activityTypeButton: some View {
    Button(action: {
      viewModel.showActivityTypes = true
    }, label: {
      HStack {
        Text( viewModel.selectedActivities.joined(separator: ", "))
          .foregroundStyle(.black)
        Spacer()
        Button(action: {
          viewModel.showActivityTypes = true
        }, label: {
         Image(systemName: "arrowtriangle.down.fill")
            .foregroundStyle(.black)
            .font(.system(size: 6))
        })
      }
    }).padding()
  }

  func measureSection(text: String, binding: Binding<String>, measure: String) -> some View {
    HStack(spacing: 0) {
      Text(text)
        .font(.system(size: 12, weight: .regular))
      VStack {
        TextField("", text: binding)
          .multilineTextAlignment(.center)
        Rectangle()
          .frame(height: 1)
      }
      Text(measure)
        .font(.system(size: 12, weight: .regular))
    }
    .keyboardType(.decimalPad)
  }

  var trackMeasurements: some View {
    VStack {
      HStack {
        measureSection(text: "Height", binding: $viewModel.height, measure: "cm")
          .focused($focusedField, equals: .height)
        measureSection(text: "Weight", binding: $viewModel.weight, measure: "kg")
          .focused($focusedField, equals: .weigth)
        measureSection(text: "Body Fat", binding: $viewModel.bodyFat, measure: "%")
          .focused($focusedField, equals: .bodyFat)
      }
      HStack {
        measureSection(text: "Waist", binding: $viewModel.waist, measure: "cm")
          .focused($focusedField, equals: .waist)
        measureSection(text: "Thighs", binding: $viewModel.thights, measure: "cm")
          .focused($focusedField, equals: .thigs)
        measureSection(text: "Chest", binding: $viewModel.chest, measure: "cm")
          .focused($focusedField, equals: .chest)
      }
    }
    .frame(maxWidth: .infinity)
    .padding()
  }


  var markDownTopSection: some View {
    VStack {
      HStack {
        Text("Markdown Content Accepted")

        Spacer()
      }
      HStack {
        photoAndVideoButtons(imageName: "photo") {
          isPickerPresented = true
        }
        photoAndVideoButtons(imageName: "video.fill") {
          isVideoPickerPresented = true
        }

        Spacer()
        HStack{
          Text("\(viewModel.markDownContent.count)")
            .foregroundStyle(viewModel.markDownContent.count < 100 ? Color(uiColor: .primaryRedColor()) : Color(.primaryGreenColor()))
          Text(" / ")
          Text("100")
        }

        Button(action: {
          viewModel.showMarkDownInfoAlert = true
        }, label: {
          Image(systemName: "info.circle")
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
        })
        .background(Color(.primaryRedColor()))
        .clipShape(Circle())
      }
      textFieldForMarkDonw(placeholder: viewModel.randomHints.randomElement() ?? "", text: $viewModel.markDownContent)
      ScrollView {
          Markdown(viewModel.markDownContent)
          .padding()
      }

    }.padding()
  }

  @ViewBuilder
  func textFieldForMarkDonw(placeholder: String, text: Binding<String>) -> some View {
    VStack {
      if #available(iOS 16.0, *) {
        VStack {
            TextView(text: text, placeholder: placeholder)
               .frame(height: 200)
              .background(Color.white)
              .cornerRadius(10)
        }
      }
      else {
        ZStack(alignment: .topLeading) {
          VStack {
            TextEditor(text: $viewModel.markDownContent)
              .padding(.vertical)
              .foregroundStyle(.black)
              .font(.system(size: 18, weight: .regular))
              .frame(height: 200)
              .focused($focusedField, equals: .markdown)

          }
          if viewModel.markDownContent.isEmpty {
            Text(placeholder)
              .foregroundColor(.gray)
              .padding(.top, 8)
              .padding(.leading, 5)
              .onTapGesture {
                focusedField = .markdown
              }
          }
        }

      }
      Rectangle()
        .frame(height: 1)
    }
    .foregroundStyle(.black)
    .font(.system(size: 18, weight: .regular))
    .focused($focusedField, equals: .markdown)
  }


  func photoAndVideoButtons(imageName: String, onTap: @escaping () -> Void) -> some View {
    Button(action: {
      onTap()
    }, label: {
      RoundedRectangle(cornerRadius: 10)
          .stroke(Color.gray, lineWidth: 2)
          .frame(width: 40, height: 40)
          .overlay(
              Rectangle()
                .fill(Color.red)
                .frame(width: 40, height: 40)
                  .overlay(
                      Image(systemName: imageName)
                          .foregroundColor(.white)

                  )
          )
    })
    .background(Color(.primaryRedColor()))
    .cornerRadius(10)
  }
}

#Preview {
  PostToSeemitView(coordinator: Coordinator())
}


struct MarkdownComponent: Hashable {
    var text: String?          // Text content
    var imageURL: URL?         // To handle image URLs
    var link: URL?             // To handle hyperlink URLs
    var heading: String? = nil
    var level: Int? = nil // For heading level (e.g., 1 for `#`, 2 for `##`)
    var listItem: String? = nil // For list items
    // Additional properties to handle various HTML tags
    var isBreak: Bool = false          // To handle <br> tag (line breaks)
    var isCentered: Bool = false       // To handle <center> tag
    var isBold: Bool = false           // To handle <strong> tag
    var isItalic: Bool = false         // In case you want to handle <i> or <em>
    var isJustified: Bool = false          // To handle <div class="text-justify">
    var codeBlock: String? = nil // For code snippets
    var language: String? = nil // Optional language for syntax highlighting

    var style: TextStyle = .body       // To handle text style (e.g., headers like <h5>)

    enum TextStyle {
        case body          // Regular text
        case headline      // For header tags like <h5>, <h1>, etc.
        case subheadline   // If you need another text style
        // You can add more styles as needed
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

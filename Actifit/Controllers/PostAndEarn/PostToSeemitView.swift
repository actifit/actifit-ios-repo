//
//  PostToSeemitView.swift
//  Actifit
//
//  Created by Ali Jaber on 15/07/2024.
//  Revamped to match the Actifit Android "Post to Hive" screen — card-based
//  sections on a light background, activity/tag chips, collapsible measurement
//  sliders, a content toolbar with a character-count progress bar and an
//  expandable editor, and a floating pulsing "Post & Earn" FAB. The posting
//  payload / API layer is unchanged.
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
  @State private var showMoreActivities = false
  @State private var measurementsExpanded = false
  @State private var isEditorExpanded = false
  @State private var tagInput = ""

  enum FocusedField: Int, CaseIterable {
      case markdown, postTitle, tagInput
  }
  @FocusState var focusedField: FocusedField?

  // MARK: Design tokens (Android parity)
  private let pageBg = Color(red: 245/255, green: 245/255, blue: 245/255)
  private let inputBg = Color(red: 245/255, green: 245/255, blue: 245/255)
  private let separator = Color(red: 224/255, green: 224/255, blue: 224/255)
  private let chipBg = Color(red: 238/255, green: 238/255, blue: 238/255)
  private let textSecondary = Color(red: 117/255, green: 117/255, blue: 117/255)
  private let successGreen = Color(red: 0, green: 200/255, blue: 83/255)
  private var brandRed: Color { Color(.primaryRedColor()) }

  var body: some View {
    ZStack(alignment: .bottomTrailing) {
      pageBg.ignoresSafeArea()

      VStack(spacing: 0) {
        topNavigationBar
        ScrollView {
          VStack(spacing: 16) {
            if !isEditorExpanded {
              titleCard
              dateAndStepsCard
              activityTypeCard
              measurementsCard
              tagsCard
            }
            contentCard
            Color.clear.frame(height: 90) // clearance for the floating FAB
          }
          .padding(16)
        }
      }

      if !isEditorExpanded { postFab }
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

  // MARK: - Top bar

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
      Text("Post & Earn")
        .font(.headline)
        .foregroundStyle(.white)
    }
    .padding(.top, 50)
    .padding(.horizontal, 20)
    .padding(.bottom, 12)
    .background(brandRed)
  }

  // MARK: - Reusable card container

  private func card<Content: View>(_ title: String, redTitle: Bool = false, trailing: AnyView? = nil, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text(title)
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(redTitle ? brandRed : Color(red: 0.13, green: 0.13, blue: 0.13))
        Spacer()
        if let trailing = trailing { trailing }
      }
      content()
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
  }

  private func styledField(_ placeholder: String, text: Binding<String>, focus: FocusedField) -> some View {
    TextField(placeholder, text: text)
      .focused($focusedField, equals: focus)
      .padding(.horizontal, 12)
      .padding(.vertical, 12)
      .background(inputBg)
      .overlay(RoundedRectangle(cornerRadius: 12).stroke(separator, lineWidth: 1))
      .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  // MARK: 1 — Title

  var titleCard: some View {
    card("Report Title") {
      styledField("", text: $viewModel.postTitle, focus: .postTitle)
    }
  }

  // MARK: 2 — Date & Steps

  var dateAndStepsCard: some View {
    card("Date & Steps", redTitle: !viewModel.isStepsValid) {
      HStack(spacing: 10) {
        toggleButton("Today", selected: viewModel.isToday) { viewModel.btnTodayTapped() }
        toggleButton("Yesterday", selected: !viewModel.isToday) { viewModel.btnYesterdayTapped() }
      }
      HStack(spacing: 12) {
        Text(viewModel.stepCount)
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(successGreen)
          .frame(minWidth: 70)
          .padding(.vertical, 10)
          .padding(.horizontal, 12)
          .background(inputBg)
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(separator, lineWidth: 1))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        Button(action: { showSyncSheet = true }, label: {
          Text("SYNC DATA")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(brandRed)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        })
        Spacer()
      }
    }
  }

  private func toggleButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action, label: {
      Text(title)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(selected ? Color.white : brandRed)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(selected ? brandRed : Color.clear)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(brandRed, lineWidth: 1.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    })
  }

  // MARK: 3 — Activity type chips

  var activityTypeCard: some View {
    card("Activity Type", redTitle: viewModel.isActivityTypeEmpty) {
      let extras = viewModel.selectedActivities.filter { $0 != "Activity Type" && !viewModel.topActivities.contains($0) }
      let shown = showMoreActivities
        ? viewModel.activityTypes
        : (viewModel.topActivities + extras)
      FlowLayout(items: shown, spacing: 8) { activity in
        chip(activity,
             selected: viewModel.selectedActivities.contains(activity),
             closable: false) {
          toggleActivity(activity)
        }
      }
      Button(action: { showMoreActivities.toggle() }, label: {
        Text(showMoreActivities ? "Show fewer activities" : "Show more activities")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(brandRed)
      })
    }
  }

  private func toggleActivity(_ activity: String) {
    if viewModel.selectedActivities.contains(activity) {
      viewModel.selectedActivities.removeAll { $0 == activity }
      if viewModel.selectedActivities.isEmpty {
        viewModel.selectedActivities = ["Activity Type"]
      }
    } else {
      viewModel.selectedActivities.removeAll { $0 == "Activity Type" }
      viewModel.selectedActivities.append(activity)
    }
  }

  // MARK: 4 — Measurements (collapsible sliders)

  var measurementsCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      Button(action: {
        withAnimation(.easeInOut(duration: 0.2)) { measurementsExpanded.toggle() }
      }, label: {
        HStack {
          Text("Track Measurements")
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(Color(red: 0.13, green: 0.13, blue: 0.13))
          Spacer()
          Image(systemName: "chevron.down")
            .foregroundStyle(textSecondary)
            .rotationEffect(.degrees(measurementsExpanded ? 180 : 0))
        }
        .contentShape(Rectangle())
      })
      .buttonStyle(PlainButtonStyle())

      if measurementsExpanded {
        VStack(spacing: 14) {
          MeasureSlider(title: "Height", stringValue: $viewModel.height, range: isMetric ? 100...220 : 39...87, step: 1, decimals: 0, unit: isMetric ? "cm" : "in", accent: brandRed, secondary: textSecondary)
          MeasureSlider(title: "Weight", stringValue: $viewModel.weight, range: isMetric ? 30...200 : 66...440, step: 1, decimals: 0, unit: isMetric ? "kg" : "lb", accent: brandRed, secondary: textSecondary)
          MeasureSlider(title: "Body Fat", stringValue: $viewModel.bodyFat, range: 0...60, step: 0.5, decimals: 1, unit: "%", accent: brandRed, secondary: textSecondary)
          MeasureSlider(title: "Waist", stringValue: $viewModel.waist, range: isMetric ? 40...150 : 16...60, step: 1, decimals: 0, unit: isMetric ? "cm" : "in", accent: brandRed, secondary: textSecondary)
          MeasureSlider(title: "Thighs", stringValue: $viewModel.thights, range: isMetric ? 30...90 : 12...35, step: 1, decimals: 0, unit: isMetric ? "cm" : "in", accent: brandRed, secondary: textSecondary)
          MeasureSlider(title: "Chest", stringValue: $viewModel.chest, range: isMetric ? 60...150 : 24...60, step: 1, decimals: 0, unit: isMetric ? "cm" : "in", accent: brandRed, secondary: textSecondary)
        }
      }
    }
    .padding(16)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: Color.black.opacity(0.06), radius: 4, x: 0, y: 2)
  }

  private var isMetric: Bool {
    (viewModel.settings?.measurementSystem ?? MeasurementSystem.metric.rawValue) == MeasurementSystem.metric.rawValue
  }

  // MARK: 5 — Tag chips

  var tagsCard: some View {
    card("Report Tags", redTitle: viewModel.isReportTagsEmpty) {
      if !tagsArray.isEmpty {
        FlowLayout(items: tagsArray, spacing: 8) { tag in
          chip(tag, selected: true, closable: true) { removeTag(tag) }
        }
      }
      HStack {
        TextField("Add a tag", text: $tagInput)
          .focused($focusedField, equals: .tagInput)
          .autocapitalization(.none)
          .disableAutocorrection(true)
          .onChange(of: tagInput) { value in
            if value.contains(",") || value.contains(" ") {
              addTag(value)
            }
          }
          .onSubmit { addTag(tagInput) }
          .padding(.horizontal, 12)
          .padding(.vertical, 12)
          .background(inputBg)
          .overlay(RoundedRectangle(cornerRadius: 12).stroke(separator, lineWidth: 1))
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
  }

  private var tagsArray: [String] {
    viewModel.reportTags
      .split(whereSeparator: { $0 == "," || $0 == " " })
      .map { String($0) }
      .filter { !$0.isEmpty }
  }

  private func addTag(_ raw: String) {
    let tag = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    tagInput = ""
    guard !tag.isEmpty else { return }
    var arr = tagsArray
    guard arr.count < 10, !arr.contains(tag) else { return }
    arr.append(tag)
    viewModel.reportTags = arr.joined(separator: ",")
  }

  private func removeTag(_ tag: String) {
    viewModel.reportTags = tagsArray.filter { $0 != tag }.joined(separator: ",")
  }

  // MARK: 6 — Report content

  var contentCard: some View {
    card("Report Content") {
      Text("Markdown content accepted")
        .font(.system(size: 12))
        .foregroundStyle(textSecondary)

      // Toolbar
      HStack(spacing: 10) {
        toolbarIcon("photo") { isPickerPresented = true }
        toolbarIcon("video.fill") { isVideoPickerPresented = true }
        toolbarIcon(isEditorExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right") {
          withAnimation(.easeInOut(duration: 0.2)) { isEditorExpanded.toggle() }
        }
        Spacer()
        HStack(spacing: 2) {
          Text("\(viewModel.markDownContent.count)")
            .foregroundStyle(viewModel.markDownContent.count < 100 ? brandRed : successGreen)
          Text("/100").foregroundStyle(textSecondary)
        }
        .font(.system(size: 13, weight: .semibold))
        Button(action: { viewModel.showMarkDownInfoAlert = true }, label: {
          Image(systemName: "info.circle")
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(brandRed)
            .clipShape(Circle())
        })
      }

      // Character-count progress bar
      GeometryReader { geo in
        ZStack(alignment: .leading) {
          Capsule().fill(separator)
          Capsule()
            .fill(viewModel.markDownContent.count >= 100 ? successGreen : brandRed)
            .frame(width: geo.size.width * min(CGFloat(viewModel.markDownContent.count) / 100.0, 1))
        }
      }
      .frame(height: 3)

      editorField
        .frame(height: isEditorExpanded ? max(UIScreen.main.bounds.height * 0.5, 300) : 200)

      // Preview — always shown (incl. expanded editor) and auto-grows to fit all
      // content; the outer page ScrollView handles any overflow, so no inner
      // fixed-height scroll that would hide content behind invisible scrollbars.
      Text("Preview")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(Color(red: 0.13, green: 0.13, blue: 0.13))
      Markdown(viewModel.markDownContent)
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
        .background(inputBg)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(separator, lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
  }

  private var editorField: some View {
    Group {
      if #available(iOS 16.0, *) {
        TextView(text: $viewModel.markDownContent, placeholder: viewModel.randomHints.randomElement() ?? "")
          .background(Color.white)
      } else {
        ZStack(alignment: .topLeading) {
          TextEditor(text: $viewModel.markDownContent)
            .padding(6)
            .foregroundStyle(.black)
            .font(.system(size: 16))
            .focused($focusedField, equals: .markdown)
          if viewModel.markDownContent.isEmpty {
            Text(viewModel.randomHints.randomElement() ?? "")
              .foregroundColor(.gray)
              .padding(.top, 14)
              .padding(.leading, 10)
          }
        }
      }
    }
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(separator, lineWidth: 1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }

  private func toolbarIcon(_ systemName: String, action: @escaping () -> Void) -> some View {
    Button(action: action, label: {
      Image(systemName: systemName)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(brandRed)
        .frame(width: 38, height: 34)
        .background(chipBg)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    })
  }

  // MARK: - Chip primitive

  private func chip(_ label: String, selected: Bool, closable: Bool, action: @escaping () -> Void) -> some View {
    Button(action: action, label: {
      HStack(spacing: 6) {
        Text(label)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(selected ? Color.white : Color(red: 0.13, green: 0.13, blue: 0.13))
        if closable {
          Image(systemName: "xmark")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(selected ? Color.white : textSecondary)
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 8)
      .background(selected ? brandRed : chipBg)
      .clipShape(Capsule())
    })
  }

  // MARK: - Floating Post FAB

  var postFab: some View {
    Button(action: {
      commitPendingTag()
      if viewModel.stepCountInDigit < 5000 {
        viewModel.showNotReachedMinimumAlert = true
      } else {
        viewModel.triggerCharityAlert()
      }
    }, label: {
      Text("Post")
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(.white)
        .padding(.vertical, 14)
        .padding(.horizontal, 30)
        .background(brandRed)
        .clipShape(Capsule())
        .shadow(color: Color.black.opacity(0.25), radius: 8, x: 0, y: 4)
    })
    .scaleEffect(isPulsing ? 1 : 0.94)
    .padding(.trailing, 20)
    .padding(.bottom, 24)
    .onAppear {
      withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
        isPulsing = true
      }
    }
  }

  private func commitPendingTag() {
    if !tagInput.trimmingCharacters(in: .whitespaces).isEmpty {
      addTag(tagInput)
    }
  }
}

// MARK: - Collapsible measurement slider

private struct MeasureSlider: View {
  let title: String
  @Binding var stringValue: String
  let range: ClosedRange<Double>
  let step: Double
  let decimals: Int
  let unit: String
  let accent: Color
  let secondary: Color

  @State private var value: Double
  @State private var touched: Bool

  init(title: String, stringValue: Binding<String>, range: ClosedRange<Double>, step: Double, decimals: Int, unit: String, accent: Color, secondary: Color) {
    self.title = title
    self._stringValue = stringValue
    self.range = range
    self.step = step
    self.decimals = decimals
    self.unit = unit
    self.accent = accent
    self.secondary = secondary
    let existing = Double(stringValue.wrappedValue)
    _value = State(initialValue: existing ?? range.lowerBound)
    _touched = State(initialValue: existing != nil && existing! > 0)
  }

  private var formatted: String { String(format: "%.\(decimals)f", value) }

  var body: some View {
    VStack(spacing: 2) {
      HStack {
        Text(title)
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(secondary)
        Spacer()
        Text(touched ? "\(formatted) \(unit)" : "—")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(touched ? accent : secondary)
      }
      Slider(value: $value, in: range, step: step, onEditingChanged: { _ in
        touched = true
        stringValue = formatted
      })
      .accentColor(accent)
      .onChange(of: value) { newValue in
        if touched { stringValue = String(format: "%.\(decimals)f", newValue) }
      }
    }
  }
}

// MARK: - Wrapping flow layout for chips (iOS 13+ via alignmentGuide)

private struct FlowLayout<Content: View>: View {
  let items: [String]
  let spacing: CGFloat
  let content: (String) -> Content
  @State private var totalHeight: CGFloat = .zero

  var body: some View {
    GeometryReader { geo in
      generate(in: geo)
    }
    .frame(height: totalHeight)
  }

  private func generate(in g: GeometryProxy) -> some View {
    var width = CGFloat.zero
    var height = CGFloat.zero
    return ZStack(alignment: .topLeading) {
      ForEach(Array(items.enumerated()), id: \.offset) { index, item in
        content(item)
          .padding(.trailing, spacing)
          .padding(.bottom, spacing)
          .alignmentGuide(.leading) { d in
            if abs(width - d.width) > g.size.width {
              width = 0
              height -= d.height
            }
            let result = width
            if index == items.count - 1 { width = 0 } else { width -= d.width }
            return result
          }
          .alignmentGuide(.top) { _ in
            let result = height
            if index == items.count - 1 { height = 0 }
            return result
          }
      }
    }
    .background(heightReader($totalHeight))
  }

  private func heightReader(_ binding: Binding<CGFloat>) -> some View {
    GeometryReader { geo -> Color in
      DispatchQueue.main.async {
        binding.wrappedValue = geo.frame(in: .local).size.height
      }
      return Color.clear
    }
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

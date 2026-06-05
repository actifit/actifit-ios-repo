//
//  ActivityTypesView.swift
//  Actifit
//
//  Created by Ali Jaber on 15/07/2024.
//

import SwiftUI

struct NewActivityTypesView: View {
  let activities: [String]
  @State var selectedActivities: [String] = []
  var onDoneTapped: (([String]) -> Void)
    var body: some View {
      VStack {
        List {
          ForEach(activities, id: \.self) { activity in
              activityView(activity: activity)
              .onTapGesture {
                if let index = selectedActivities.firstIndex(of: activity) {
                    selectedActivities.remove(at: index)
                } else {
                    selectedActivities.append(activity)
                }
              }
          }
        }
        .padding(.bottom, 50)
      }
      .overlay(alignment: .bottom) {
        Button(action: {
//          selectedActivities.removeAll { activity in
//            activity == "Activity Type"
//          }
          onDoneTapped(selectedActivities)
        }, label: {
          Text("DONE")
            .foregroundStyle(.black)
            .background(.white)
            .frame(maxWidth: .infinity)

        })
        .padding()

      }
    }

  func activityView(activity: String) -> some View {
        HStack {
            Button(action: {
                if let index = selectedActivities.firstIndex(of: activity) {
                    selectedActivities.remove(at: index)
                } else {
                    selectedActivities.append(activity)
                }
            }, label: {
                radioButtonBorder(isSelected: selectedActivities.contains(activity))
            })
            .buttonStyle(PlainButtonStyle())
            .frame(width: 30, height: 30)
            Text(activity)
        }
        .padding(.vertical, 5)
    }

    func radioButtonBorder(isSelected: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .stroke(Color.gray, lineWidth: 2)
            .frame(width: 30, height: 30)
            .overlay(
                Rectangle()
                  .fill(isSelected ? Color.red : Color.clear)
                  .frame(width: 30, height: 30)
                    .overlay(
                        Image(systemName: "checkmark")
                            .foregroundColor(.white)
                            .opacity(isSelected ? 1 : 0)
                    )
            )
            .cornerRadius(10)
    }
}

#Preview {
  NewActivityTypesView(activities: ["Swimming", "Footbal"], onDoneTapped: { _ in

  })
}

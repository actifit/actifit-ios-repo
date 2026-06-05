//
//  MarkDownTextView.swift
//  Actifit
//
//  Created by Ali Jaber on 23/07/2024.
//

import Foundation
import SwiftUI
import UIKit

struct TextView: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String

    class Coordinator: NSObject, UITextViewDelegate {
        var parent: TextView

        init(parent: TextView) {
            self.parent = parent
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if textView.text == parent.placeholder {
                textView.text = ""
                textView.textColor = .black // Placeholder color
            }
        }


        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor =  .gray // Placeholder color
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
                       if textView.text.isEmpty {
                           textView.textColor = .gray // Update color when text becomes empty
                         //  textView.text = parent.placeholder
                       } else {
                           textView.textColor = .black
                       }
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.text = placeholder
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.isScrollEnabled = true
        textView.backgroundColor = .white
        textView.layer.borderColor = UIColor.white.cgColor  // Remove border
        textView.layer.borderWidth = 0                      // Remove border width
        textView.textContainerInset = .zero                 // Adjust text insets if needed
        textView.textContainer.lineFragmentPadding = 0
        return textView
    }


    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            let selectedRange = uiView.selectedTextRange
            if !text.isEmpty {
                uiView.text = text + "\n"
            }
            if text.isEmpty && uiView.text != placeholder {
                       uiView.textColor = .gray // Placeholder color
                   } else if uiView.text != text {
                       uiView.textColor = .black // User typing color
                   }
            uiView.selectedTextRange = selectedRange
            let endPosition = uiView.endOfDocument
            uiView.selectedTextRange = uiView.textRange(from: endPosition, to: endPosition)
        }
    }
}

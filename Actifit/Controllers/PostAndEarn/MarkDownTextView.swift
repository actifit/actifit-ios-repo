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
            // Clear the placeholder (identified by its colour) when editing starts.
            if textView.textColor == .placeholderText {
                textView.text = ""
                textView.textColor = .black
            }
        }


        func textViewDidEndEditing(_ textView: UITextView) {
            if textView.text.isEmpty {
                textView.text = parent.placeholder
                textView.textColor = .placeholderText
            }
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            textView.textColor = textView.text.isEmpty ? .placeholderText : .black
        }
    }

    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.font = UIFont.systemFont(ofSize: 18)
        textView.isScrollEnabled = true
        textView.backgroundColor = .white
        textView.layer.borderColor = UIColor.white.cgColor  // Remove border
        textView.layer.borderWidth = 0                      // Remove border width
        textView.textContainerInset = .zero                 // Adjust text insets if needed
        textView.textContainer.lineFragmentPadding = 0
        // Seed the field from the binding, falling back to the placeholder.
        if text.isEmpty {
            textView.text = placeholder
            textView.textColor = .placeholderText
        } else {
            textView.text = text
            textView.textColor = .black
        }
        return textView
    }


    func updateUIView(_ uiView: UITextView, context: Context) {
        // Only push the bound value into the text view when it genuinely differs
        // — i.e. a programmatic change from outside. Doing this on every keystroke
        // (as the old code did, appending "\n" and forcing the caret to the end)
        // made the field visibly flicker and jump the cursor while typing.
        if uiView.textColor == .placeholderText && text.isEmpty { return }
        guard uiView.text != text else { return }
        let selectedRange = uiView.selectedTextRange
        uiView.text = text
        uiView.textColor = text.isEmpty ? .placeholderText : .black
        // Preserve the caret so an external sync doesn't send it to the end.
        if let selectedRange = selectedRange {
            uiView.selectedTextRange = selectedRange
        }
    }
}

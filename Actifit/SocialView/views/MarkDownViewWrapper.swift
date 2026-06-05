//
//  MarkDownViewWrapper.swift
//  Actifit
//
//  Created by Ali Jaber on 24/10/2024.
//

import SwiftUI
import Down
import WebKit

struct DownViewRepresentable: UIViewRepresentable {
    var markdownText: String
    @Binding var contentHeight: CGFloat  // Bindable property to update height

    func filteredMarkdown(_ markdown: String) -> String {
        let regex = try! NSRegularExpression(pattern: #"(\[.*?\]\()((https?://)?(?:www\.)?unwantedwebsite\.com/.*?)\)"#, options: [])
        let range = NSRange(markdown.startIndex..., in: markdown)
        return regex.stringByReplacingMatches(in: markdown, options: [], range: range, withTemplate: "[Filtered Link]")
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        do {
            let downView = try DownView(frame: view.bounds, markdownString: filteredMarkdown(markdownText))
            downView.pageZoom = 1.5
            downView.scrollView.isScrollEnabled = contentHeight == 150 ? true : false// Disable scrolling

            downView.navigationDelegate = context.coordinator
            view.addSubview(downView)

            downView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                downView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                downView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                downView.topAnchor.constraint(equalTo: view.topAnchor),
                downView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])

            context.coordinator.downView = downView
        } catch {
            print("Error rendering markdown: \(error.localizedDescription)")
        }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // Updates can go here if needed
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: DownViewRepresentable
        weak var downView: DownView?

        init(_ parent: DownViewRepresentable) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.body.scrollHeight") { [weak self] (height, error) in
                guard let self = self, let height = height as? CGFloat else { return }
                DispatchQueue.main.async {
                    self.parent.contentHeight = height + 20 // Update the height with padding
                }
            }
        }
    }
}

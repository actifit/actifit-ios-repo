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
    /// Only an expanded card reports its height; collapsed previews use a fixed frame.
    var measuresContent: Bool = true

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
            guard parent.measuresContent else { return }
            // Images can still be arriving when the page reports finished, so measure again
            // shortly after.
            for delay in [0.0, 1.0, 3.0] {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self, weak webView] in
                    guard let webView = webView else { return }
                    self?.measure(webView)
                }
            }
        }

        private func measure(_ webView: WKWebView) {
            // The bottom edge of the content itself. document.body.scrollHeight is never less
            // than the web view's own height, so it could not shrink to fit short content.
            // (The value already reflects pageZoom; scaling it again adds 50% empty space.)
            let js = "Math.ceil(document.body.getBoundingClientRect().bottom + window.scrollY)"
            webView.evaluateJavaScript(js) { [weak self] (height, error) in
                guard let self = self, let height = height as? CGFloat, height > 0 else { return }
                let points = height + 20
                if abs(self.parent.contentHeight - points) > 1 {
                    self.parent.contentHeight = points
                }
            }
        }
    }
}

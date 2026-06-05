//
//  HTMLMarkdownConverter.swift
//  Actifit
//
//  Created by Ali Jaber on 17/10/2024.
//
import SwiftUI
import WebKit
import Down

struct WebView: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.pageZoom  = 0.2
        webView.loadHTMLString(htmlContent, baseURL: nil)
    }
}

func splitHTMLAndMarkdown(content: String) -> [(type: String, value: String)] {
    var sections: [(type: String, value: String)] = []

    let htmlRegex = "<[^>]+>" // Simple regex to detect HTML tags
    let regex = try! NSRegularExpression(pattern: htmlRegex, options: [])

    let range = NSRange(location: 0, length: content.utf16.count)
    var lastIndex = 0

    regex.enumerateMatches(in: content, options: [], range: range) { match, _, _ in
        if let matchRange = match?.range {
            let beforeMatch = (content as NSString).substring(with: NSRange(location: lastIndex, length: matchRange.location - lastIndex))
            if !beforeMatch.isEmpty {
                sections.append((type: "markdown", value: beforeMatch))
            }

            let matchString = (content as NSString).substring(with: matchRange)
            sections.append((type: "html", value: matchString))
            lastIndex = matchRange.location + matchRange.length
        }
    }

    // Add any remaining content after the last match
    if lastIndex < content.count {
        let remaining = (content as NSString).substring(from: lastIndex)
        sections.append((type: "markdown", value: remaining))
    }

    return sections
}

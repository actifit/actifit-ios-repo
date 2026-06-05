
import SwiftUI

struct MarkDownView: View {
  let markdownText: String
  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      ForEach(parseMarkdown(markdownText), id: \.self) { component in
        if let imageURL = component.imageURL {
          AsyncImage(url: imageURL) { image in
            image
              .resizable()
              .scaledToFit()
              .frame(maxWidth: 300, maxHeight: 300)
              .cornerRadius(10)
          } placeholder: {
            ProgressView()
          }
        } else if let text = component.text {
          Text(LocalizedStringKey(text))
            .padding(.vertical, 5)
        }
      }
    }

  }

  func parseMarkdown(_ markdown: String) -> [MarkdownComponent] {
    var components: [MarkdownComponent] = []
    let lines = markdown.split(separator: "\n")
    for line in lines {

        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
        if trimmedLine.starts(with: "#") {
            // Handle headings
            let headingLevel = trimmedLine.prefix { $0 == "#" }.count
            let headingText = trimmedLine.dropFirst(headingLevel).trimmingCharacters(in: .whitespaces)
            components.append(MarkdownComponent(heading: headingText, level: headingLevel))
        }




      if let nestedImageRange = line.range(of: "![]("),
         let nestedLinkRange = line.range(of: "[![]("),
         let nestedLinkEndRange = line.range(of: ")]", range: nestedLinkRange.upperBound..<line.endIndex) {
        let linkStart = nestedLinkRange.upperBound
        let linkEnd = line.range(of: ")", range: linkStart..<line.endIndex)?.lowerBound ?? nestedLinkEndRange.lowerBound
        let imageLinkStart = nestedImageRange.upperBound
        let imageLinkEnd = line.range(of: ")", range: imageLinkStart..<line.endIndex)?.lowerBound ?? linkEnd
        let imageURLString = String(line[imageLinkStart..<imageLinkEnd])
        let linkURLString = String(line[linkStart..<linkEnd])
        if let imageURL = URL(string: imageURLString), let linkURL = URL(string: linkURLString) {
          components.append(MarkdownComponent(imageURL: imageURL, link: linkURL))
        }
      } else if line.starts(with: "![") && line.contains("](") {
        if let urlStartIndex = line.range(of: "](")?.upperBound,
           let urlEndIndex = line.range(of: ")", range: urlStartIndex..<line.endIndex)?.lowerBound {
          let urlString = String(line[urlStartIndex..<urlEndIndex])
          if let url = URL(string: urlString) {
            components.append(MarkdownComponent(imageURL: url))
          }
        }
      } else {
        components.append(MarkdownComponent(text: String(line)))
      }
    }
    return components
  }
}

#Preview {
  MarkDownView(markdownText: "HI")
}


//func parseMarkdown(_ markdown: String) -> [MarkdownComponent] {
//    var components: [MarkdownComponent] = []
//    let lines = markdown.split(separator: "\n")
//    var isInCodeBlock = false
//    var codeBlockLanguage: String? = nil
//    var codeBlockContent = ""
//    for line in lines {
//        let trimmedLine = line.trimmingCharacters(in: .whitespaces)
//
//        if trimmedLine.starts(with: "```") {
//                   if isInCodeBlock {
//                       // End of code block
//                       components.append(MarkdownComponent(codeBlock: codeBlockContent.trimmingCharacters(in: .whitespacesAndNewlines), language: codeBlockLanguage))
//                       isInCodeBlock = false
//                       codeBlockLanguage = nil
//                       codeBlockContent = ""
//                   } else {
//                       // Start of code block
//                       isInCodeBlock = true
//                       codeBlockLanguage = trimmedLine.count > 3 ? String(trimmedLine.dropFirst(3)) : nil
//                   }
//                   continue
//               }
//        if isInCodeBlock {
//            // Append to the code block content
//            codeBlockContent += line + "\n"
//
//            // Detect headings (e.g., # Heading, ## Subheading)
//
//
//            // Detect headings (e.g., # Heading, ## Subheading)
//        } else if trimmedLine.starts(with: "#") {
//                  let headingLevel = trimmedLine.prefix { $0 == "#" }.count
//                  let headingText = trimmedLine.dropFirst(headingLevel).trimmingCharacters(in: .whitespaces)
//                  components.append(MarkdownComponent(heading: headingText, level: headingLevel))
//              }
//        else if let firstChar = trimmedLine.first, ["-", "*"].contains(firstChar) || trimmedLine.prefix(2).contains(".") {
//                  let listItemText = trimmedLine.dropFirst().trimmingCharacters(in: .whitespaces)
//                  components.append(MarkdownComponent(listItem: listItemText))
//              }
//        // Detect nested image inside a link: [![alt text](image_url)](link_url)
//        else if let linkStartRange = line.range(of: "[!["), // Detect start of nested structure
//           let imageAltStartRange = line.range(of: "![", range: linkStartRange.upperBound..<line.endIndex),
//           let imageAltEndRange = line.range(of: "](", range: imageAltStartRange.upperBound..<line.endIndex),
//           let imageURLStartRange = line.range(of: "](", range: imageAltEndRange.upperBound..<line.endIndex),
//           let imageURLEndRange = line.range(of: ")", range: imageURLStartRange.upperBound..<line.endIndex),
//           let linkURLStartRange = line.range(of: "](", range: imageURLEndRange.upperBound..<line.endIndex),
//           let linkURLEndRange = line.range(of: ")", range: linkURLStartRange.upperBound..<line.endIndex) {
//
//            // Extract URLs
//            let imageURLString = String(line[imageURLStartRange.upperBound..<imageURLEndRange.lowerBound])
//            let linkURLString = String(line[linkURLStartRange.upperBound..<linkURLEndRange.lowerBound])
//
//            if let imageURL = URL(string: imageURLString), let linkURL = URL(string: linkURLString) {
//                components.append(MarkdownComponent(imageURL: imageURL, link: linkURL))
//            }
//        }
//        // Detect simple image: ![alt text](image_url)
//        else if let imageAltStartRange = line.range(of: "!["),
//                let imageAltEndRange = line.range(of: "](", range: imageAltStartRange.upperBound..<line.endIndex),
//                let imageURLStartRange = line.range(of: "](", range: imageAltEndRange.upperBound..<line.endIndex),
//                let imageURLEndRange = line.range(of: ")", range: imageURLStartRange.upperBound..<line.endIndex) {
//
//            let imageURLString = String(line[imageURLStartRange.upperBound..<imageURLEndRange.lowerBound])
//
//            if let imageURL = URL(string: imageURLString) {
//                components.append(MarkdownComponent(imageURL: imageURL))
//            }
//        }
//        // Handle regular text
//        else {
//            components.append(MarkdownComponent(text: String(line)))
//        }
//    }
//
//    return components
//}
//}

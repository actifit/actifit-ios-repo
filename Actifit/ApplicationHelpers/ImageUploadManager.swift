//
//  ImageUploadManager.swift
//  Actifit
//
//  Created by Ali Jaber on 14/11/2024.
//

import Foundation
import UIKit
class ImageUploadManager {

    private func createDataBody(media: Media, boundary: String, filename: String) -> Data {
        let lineBreak = "\r\n"
        var body = Data()
        body.append("--\(boundary + lineBreak)")
        body.append("Content-Disposition: form-data; name=\"\(media.key)\"; filename=\"\(filename)\"\(lineBreak)")
        body.append("Content-Type: \(media.mimeType + lineBreak + lineBreak)")
        body.append(media.data)
        body.append(lineBreak)
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }

    func generateBoundary() -> String {
        return "Boundary-\(UUID().uuidString)"
    }

    func uploadImage(_ image: UIImage) async throws -> String {
        guard let url = URL(string: "https://usermedia.actifit.io/upload") else {
            throw URLError(.badURL)
        }

        guard let imageData = UIImageJPEGRepresentation(image, 0.7) else {
            throw NSError(domain: "Invalid Image", code: 0, userInfo: nil)
        }

        let deviceUUID = await UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        let filename = deviceUUID + String(Date().timeIntervalSince1970)

        guard let mediaImage = Media(withImage: image, forKey: "image") else {
            throw NSError(domain: "Failed to create media data", code: 0, userInfo: nil)
        }

        let boundary = generateBoundary()
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(Secrets.imageUploadToken, forHTTPHeaderField: "Authorization")
        request.httpBody = createDataBody(media: mediaImage, boundary: boundary, filename: filename)

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw NSError(domain: "Upload failed", code: (response as? HTTPURLResponse)?.statusCode ?? 0, userInfo: nil)
            }

            // Assuming success, construct the image URL and return it
            var imgUrl = "![](https://usermedia.actifit.io/\(filename))"
            imgUrl = imgUrl.replacingOccurrences(of: "io//", with: "io/")
            return imgUrl
        } catch {
            print(error.localizedDescription)
            return ""
        }
    }
}

struct Media {
    let data: Data
    let key: String
    let mimeType: String

    init?(withImage image: UIImage, forKey key: String) {
        guard let data = UIImageJPEGRepresentation(image, 0.7) else { return nil }
        self.data = data
        self.key = key
        self.mimeType = "image/jpeg"
    }
}

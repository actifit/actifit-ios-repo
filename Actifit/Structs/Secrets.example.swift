//
//  Secrets.example.swift
//  Actifit
//
//  TEMPLATE for credentials. Copy this file to `Secrets.swift` (same folder)
//  and replace the placeholder values with the real ones. `Secrets.swift` is
//  gitignored so real credentials are never committed.
//
//  In Xcode, `Secrets.swift` is already referenced by the target, so once you
//  create it the project will build. This template file is NOT compiled.
//

import Foundation

enum Secrets {
    /// Microsoft App Center app secret.
    static let appCenterSecret = "YOUR_APP_CENTER_SECRET"

    /// DeepL API auth key (sent as the value after "DeepL-Auth-Key ").
    static let deepLAuthKey = "YOUR_DEEPL_AUTH_KEY"

    /// Authorization token for usermedia.actifit.io image uploads.
    static let imageUploadToken = "YOUR_IMAGE_UPLOAD_TOKEN"
}

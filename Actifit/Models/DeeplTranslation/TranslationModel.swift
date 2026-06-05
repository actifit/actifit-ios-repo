//
//  TranslationModel.swift
//  Actifit
//
//  Created by Ali Jaber on 02/08/2024.
//

import Foundation

struct TranslatedContentModel: Codable {
  let translations: [TranslationObject]
}

struct TranslationObject: Codable {
  let detectedSourceLanguage: String
  let text: String
}

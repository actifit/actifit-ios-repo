//
//  TranslationManager.swift
//  Actifit
//
//  Created by Ali Jaber on 02/08/2024.
//

import Foundation

class TranslationManager {
  var translatedWaves: [Int: String] = [:]
  var originalWaveContent: [Int: String] = [:]
  static let sharedInstance = TranslationManager()
  private init() {}

  func addWave(originalContent: String, updatedContent: String, waveId: Int) {
    originalWaveContent.updateValue(originalContent, forKey: waveId)
    translatedWaves.updateValue(updatedContent, forKey: waveId)
  }

  func isWaveTranslated(waveId: Int) -> Bool {
    return !translatedWaves.filter({$0.key == waveId}).isEmpty
  }

  func getTranslatedContentById(waveId: Int) -> String {
    return translatedWaves.filter({$0.key == waveId}).first?.value ?? ""
  }

  func getOriginalContent(waveId: Int) -> String {
    return originalWaveContent.filter({$0.key == waveId}).first?.value ?? ""
  }

  func removeTransitionById(waveId: Int) {
    translatedWaves.removeValue(forKey: waveId)
  }

  func clearWaves() {
    originalWaveContent = [:]
    translatedWaves = [:]
  }
}

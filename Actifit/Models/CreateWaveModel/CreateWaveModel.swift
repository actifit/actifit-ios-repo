//
//  CreateWaveModel.swift
//  Actifit
//
//  Created by Ali Jaber on 14/08/2024.
//

import Foundation

struct CreateWaveModel: Codable {
  let success: Bool
  /// Why a broadcast failed, fit to show (set by the on-device signer, never decoded).
  var message: String? = nil
}

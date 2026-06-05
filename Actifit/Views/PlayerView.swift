//
//  PlayerView.swift
//  Actifit
//
//  Created by Ali Jaber on 05/06/2024.
//

import AVFoundation
import UIKit
import Foundation
class PlayerView: UIView {
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        set {
            playerLayer.player = newValue
        }
    }

    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }

    override static var layerClass: AnyClass {
        return AVPlayerLayer.self
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayerLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayerLayer()
    }

    private func setupPlayerLayer() {
        playerLayer.videoGravity = .resizeAspect
    }
}

//
//  GradientView.swift
//  Actifit
//
//  Created by Ali Jaber on 21/07/2023.
//

import Foundation
import UIKit
class GradientView: UIView {
    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    private var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupGradient()
    }
    
    private func setupGradient() {
        let startColor = UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 0.8).cgColor // Red color at the bottom
               let midColor = UIColor(red: 0.5, green: 0.0, blue: 0.0, alpha: 0.5).cgColor // More red in the middle
               let endColor = UIColor.clear.cgColor
               gradientLayer.colors = [startColor, midColor, endColor]
               gradientLayer.locations = [0.0, 0.5, 1.0] // Gradient stops
               gradientLayer.startPoint = CGPoint(x: 0.5, y: 1.0) // Start point at the bottom center
               gradientLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
    }
}

//
//  CircularImage.swift
//  Actifit
//
//  Created by Ali Jaber on 03/08/2023.
//

import Foundation
import UIKit

class CircularImageView: UIImageView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCircularImage()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupCircularImage()
    }
    
    private func setupCircularImage() {
        self.contentMode = .scaleAspectFill
        self.clipsToBounds = true
        self.layer.cornerRadius = self.frame.width / 2
    }
}

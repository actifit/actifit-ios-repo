//
//  UIImage+Extensions.swift
//  Actifit
//
//  Created by Ali Jaber on 06/07/2023.
//

import Foundation
import UIKit

extension UIImageView {
    private var loaderTag: Int { return 999 }
    
    func showLoader() {
        // Remove existing loader if any
        hideLoader()
        
        // Create and configure the loader view
        let loader = UIActivityIndicatorView(activityIndicatorStyle: UIActivityIndicatorViewStyle.medium)
        loader.center = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        loader.tag = loaderTag
        addSubview(loader)
        
        // Start animating the loader
        loader.startAnimating()
    }
    
    func hideLoader() {
        // Remove the loader view if it exists
        if let loader = viewWithTag(loaderTag) as? UIActivityIndicatorView {
            loader.stopAnimating()
            loader.removeFromSuperview()
        }
    }
}


extension UIImage {
    func imageWithSize(_ size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}

//
//  ToastView.swift
//  Actifit
//
//  Created by Ali Jaber on 18/08/2023.
//

import Foundation
import UIKit

class ToastView: UIView {
    private var textLabel: UILabel!
    private var imageView: UIImageView!
    
    init(frame: CGRect, text: String) {
        super.init(frame: frame)
      
        
        // Create and configure the label
        textLabel = UILabel(frame: CGRect(x: 0, y: 0, width: frame.width - 20, height: frame.height))
        textLabel.numberOfLines = 0
        textLabel.textAlignment = .left
        textLabel.textColor = .white
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 12)
       // textLabel.backgroundColor = .red
        let image = UIImage(named: "logo")?.imageWithSize(CGSize(width: 20, height: 20))
        // Create and configure the image view
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
       // imageView.backgroundColor = .blue
        // Stack label and image view horizontally
        let stackView = UIStackView(arrangedSubviews: [imageView, textLabel])
        stackView.distribution = .fillProportionally
        //stackView.alignment = .center
        stackView.axis = .horizontal
        stackView.spacing = 5.0
        stackView.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.height)
        
        addSubview(stackView)
        
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 8.0
        clipsToBounds = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension UIViewController {
    func showToast(message: String, width: CGFloat? = nil, height: CGFloat? = nil) {
        let toastWidth: CGFloat =  width ?? 200
        let toastHeight: CGFloat = height ?? 60
        let toastX = (view.frame.width - toastWidth) / 2
        let toastY = view.frame.height - toastHeight - 100
        
        let toastView = ToastView(frame: CGRect(x: toastX, y: toastY, width: toastWidth, height: toastHeight), text: message)
        view.addSubview(toastView)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            toastView.removeFromSuperview()
        }
    }
    
    func heightForString(_ text: String, font: UIFont, width: CGFloat) -> CGFloat {
        let textAttributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: font]
        
        let boundingRect = NSString(string: text).boundingRect(
            with: CGSize(width: width, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: textAttributes,
            context: nil
        )
        
        return ceil(boundingRect.height)
    }
}

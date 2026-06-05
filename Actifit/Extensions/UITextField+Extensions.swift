//
//  UITextField+Extensions.swift
//  Actifit
//
//  Created by Ali Jaber on 07/07/2023.
//

import Foundation
import UIKit
class PasswordTextField: UITextField {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        self.isSecureTextEntry = true
        
        //show/hide button
        let button = UIButton(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        button.setImage(UIImage(systemName: "eye.slash.circle")!.withTintColor(.primaryRedColor()).withRenderingMode(.alwaysTemplate), for: .normal)
        button.setImage(UIImage(systemName: "eye.circle")!.withTintColor(.primaryRedColor()).withRenderingMode(.alwaysTemplate), for: .selected)
        button.tintColor = .primaryRedColor()
        rightView = button
        rightViewMode = .always
        button.addTarget(self, action: #selector(showHidePassword(_:)), for: .touchUpInside)
    }
    
    @objc private func showHidePassword(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        self.isSecureTextEntry = !sender.isSelected
    }
    
}


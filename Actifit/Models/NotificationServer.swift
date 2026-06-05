//
//  Notification.swift
//  Actifit
//
//  Created by Ali M on 6/2/22.
//

import UIKit

struct NotificationKeys {
    static let _category = "category"
    static let _name = "name"
    
}

class NotificationServer {
    var isSelected = false
    var category = ""
    var name = ""
    
    init(info : [String : Any]) {
        self.category = info.stringValue(forKey: NotificationKeys._category)
        self.name = info.stringValue(forKey: NotificationKeys._name)
        
    }
    
    func changeSelection(selected: Bool) {
        self.isSelected = selected
    }

}

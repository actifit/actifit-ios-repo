//
//  User.swift
//  Actifit
//
//  Created by Hitender kumar on 13/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit
import RealmSwift
import Realm

class User : Object {
    
    @objc dynamic var steemit_username: String = "vevita"
    @objc dynamic var private_posting_key: String = "5JeAQvwUdeuvZvSbvHW24r5jQrQ1kLXHcyn3Echqg6b2LkJHhhe"
    @objc dynamic var last_post_date: Date = Date()

    class var sharedInstance : User {
        return User()
    }
    
    class func saveWith(info : [String : Any]) {
        DispatchQueue.global().async {
            // Get new realm and table since we are in a new thread
            autoreleasepool {
                if let realm = AppDelegate.defaultRealm() {
                    realm.beginWrite()
                    realm.create(User.self, value: info)
                  do {
                    try realm.commitWrite()
                  } catch let error {
                    print(error.localizedDescription)
                  }
                }
            }
        }
    }
    
    //get current user(with credentials)
    class func current() -> User? {
        guard let realm = AppDelegate.defaultRealm() else { return nil }
        if let user = realm.objects(User.self).first {
            return User(value: user) // Return a detached copy
        }

        return nil
    }

    //delete current user credentials
    class func deleteCurrentUser() {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = CurrentRealmSchemaVersion //increase schemaversion if properties changed
        config.migrationBlock = { (migration, oldSchemaVersion) in
            // nothing to do
        }
        do {
            let realm =  try Realm.init(configuration: config)
            let objs = realm.objects(User.self)
            realm.beginWrite()
            realm.delete(objs)
            try! realm.commitWrite()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    //update the credentials
    func updateUser(steemit_username :String, private_posting_key : String, last_post_date : Date) {
        autoreleasepool {
            if let realm = AppDelegate.defaultRealm() {
                realm.beginWrite()
                self.steemit_username = steemit_username
                self.private_posting_key = private_posting_key
                self.last_post_date = last_post_date
                try! realm.commitWrite()
            }
        }
    }
    
}


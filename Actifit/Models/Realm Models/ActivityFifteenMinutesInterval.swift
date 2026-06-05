//
//  ActivityFifteenMinutesInterval.swift
//  Actifit
//
//  Created by Deepak Bansal on 23/07/19.
//

import UIKit
import Foundation
import RealmSwift
import Realm


class ActivityFifteenMinutesInterval : Object, NSCoding, Decodable, Encodable {
    @objc dynamic var id: Int = 0
    @objc dynamic var steps: Int = 0
    
    @objc dynamic var date: String = ""
    @objc dynamic var stepsInString: String = "123"
    @objc dynamic var idInString: String = "45"
    @objc dynamic var interval : String = ""
    
    override static func primaryKey() -> String? { //primary key needs to be a string or int
        return "id"
    }
    
    convenience init(name: String, age: Int) {
        self.init()
    }
    
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(idInString, forKey: "idInString")
        aCoder.encode(date, forKey: "date")
        aCoder.encode(stepsInString, forKey: "stepsInString")
        aCoder.encode(interval, forKey: "interval")
    }
    
    required convenience init(coder aDecoder: NSCoder)
    {
        self.init()
        self.idInString  = aDecoder.decodeObject(forKey: "idInString")       as! String
        self.date           = aDecoder.decodeObject(forKey: "date")         as! String
        self.stepsInString  = aDecoder.decodeObject(forKey: "stepsInString")       as! String
        self.interval       = aDecoder.decodeObject(forKey: "interval")    as! String
    }
    
    
    //class func saveWith(info : [String : Any]) {
    //    DispatchQueue.global().async {
    //        // Get new realm and table since we are in a new thread
    //        autoreleasepool {
    //            if let realm = AppDelegate.defaultRealm() {
    //                realm.beginWrite()
    //
    //
    //                // Updating book with id = 1
    //                try! realm.write {
    //                    realm.add(cheeseBook, update: .modified)
    //                }
    //
    //                try! realm.commitWrite()
    //            }
    //        }
    //    }
    //}
    
    //get all saved activities
    class func all() -> [ActivityFifteenMinutesInterval] {
        var contents = [ActivityFifteenMinutesInterval]()
        if let realm = AppDelegate.defaultRealm() {
            contents = realm.objects(ActivityFifteenMinutesInterval.self).map({$0})
            // contents = self.removeDuplicates(activities: contents)
        }
        return contents
    }
    
    class  func upadteAfterFifteen(info : [String : Any]) {
        DispatchQueue.global().async {
            // Get new realm and table since we are in a new thread
            autoreleasepool {
                if let realm = AppDelegate.defaultRealm() {
                    realm.beginWrite()
                    realm.create(ActivityFifteenMinutesInterval.self, value: info, update: .all)  //true //1122
                    try! realm.commitWrite()
                }
            }
        }
    }
}



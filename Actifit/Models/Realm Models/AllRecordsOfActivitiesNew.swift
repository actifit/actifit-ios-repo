//
//  AllRecordsOfActivitiesNew.swift
//  Actifit
//
//  Created by Imran Balouch on 14/11/2019.
//

import Foundation
import UIKit
import RealmSwift
import Realm

class AllRecordsOfActivitiesNew : Object {
 
    //let activities = List<ActivityFifteenMinutesInterval>()
    
    @objc dynamic var date                  : String     = ""
    @objc dynamic var id                    : Int        = 0
    @objc dynamic var activitiesListData    : Data!
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
     func saveWith(info : [String : Any]) {
          // DispatchQueue.global().async {
            DispatchQueue.main.async {
               
               // Get new realm and table since we are in a new thread
               autoreleasepool {
                   if let realm = AppDelegate.defaultRealm() {
                       realm.beginWrite()
                       realm.create(AllRecordsOfActivitiesNew.self, value: info, update: .error) //false //1122
                       try! realm.commitWrite()
                   }
               }
           }
       }
    
    
    func upadteWith(info : [String : Any]) {
//           DispatchQueue.global().async {
        DispatchQueue.main.async {
               // Get new realm and table since we are in a new thread
               autoreleasepool {
                   if let realm = AppDelegate.defaultRealm() {
                       realm.beginWrite()
                    realm.create(AllRecordsOfActivitiesNew.self, value: info, update: .all) //true //1122
                        
                       try! realm.commitWrite()
                   }
               }
           }
       }
    
    
    class func all() -> [AllRecordsOfActivitiesNew] {
           var contents = [AllRecordsOfActivitiesNew]()
           if let realm = AppDelegate.defaultRealm() {
               contents = realm.objects(AllRecordsOfActivitiesNew.self).map({$0})
              // contents = self.removeDuplicates(activities: contents)
           }
           return contents
       }
    
    
    
    class func deleteAll() {
           var config = Realm.Configuration.defaultConfiguration
           config.schemaVersion = CurrentRealmSchemaVersion //increase schemaversion if properties changed
           config.migrationBlock = { (migration, oldSchemaVersion) in
               // nothing to do
           }
           do {
               let realm =  try Realm.init(configuration: config)
               let objs = realm.objects(AllRecordsOfActivitiesNew.self)
                
               realm.beginWrite()
               realm.delete(objs)
               try! realm.commitWrite()
           } catch {
               
           }
       }
    
}

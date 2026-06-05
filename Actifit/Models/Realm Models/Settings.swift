//
//  Settings.swift
//  Actifit
//
//  Created by Hitender kumar on 21/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import UIKit
import RealmSwift
import Realm

enum MeasurementSystem : String {
    case metric = "metric"
    case us = "us"
    case none = "none"
}

class Settings: Object {
    
    @objc dynamic var measurementSystem: MeasurementSystem.RawValue = MeasurementSystem.metric.rawValue
    @objc dynamic var isDonatingCharity: Bool = false
    @objc dynamic var isDeviceSensorSystemSelected: Bool = true
    @objc dynamic var fitBitMeasurement: Bool = false
    @objc dynamic var isSbdSPPaySystemSelected: Bool = true
    @objc dynamic var isReminderSelected: Bool = false
    @objc dynamic var charityName: String = ""
    @objc dynamic var charityDisplayName: String = ""
    @objc dynamic var appVersion: String = ""
    @objc dynamic var notificationSelected: Bool = true
    @objc dynamic var hiveChain: String = ""
    @objc dynamic var steemChain: String = ""
    @objc dynamic var blurtChain: String = ""
    @objc dynamic var isLiquidHBDSelected: Bool = false
    @objc dynamic var isDeclinePayoutSelected: Bool = false
    @objc dynamic var is100SPSelected: Bool = false
    
    class func saveWith(info : [String : Any]) {
        DispatchQueue.global().async {
            // Get new realm and table since we are in a new thread
            autoreleasepool {
                if let realm = AppDelegate.defaultRealm() {
                    realm.beginWrite()
                    realm.create(Settings.self, value: info)
                    try! realm.commitWrite()
                }
            }
        }
    }
    
    //get saved settings
    class func current() -> Settings? {
        var settings : Settings?
        if let realm = AppDelegate.defaultRealm() {
            let objs = realm.objects(Settings.self)
            settings = objs.first
        }
        return settings
    }
    
    
    //clear activity history
    class func deleteAll() {
        var config = Realm.Configuration.defaultConfiguration
        config.schemaVersion = CurrentRealmSchemaVersion //increase schemaversion if properties changed
        config.migrationBlock = { (migration, oldSchemaVersion) in
            // nothing to do
        }
        do {
            let realm =  try Realm.init(configuration: config)
            let objs = realm.objects(Activity.self)
            realm.beginWrite()
            realm.delete(objs)
            try! realm.commitWrite()
        } catch {
            
        }
    }
    
    //update the activity(steps count)
    func update(measurementSystem :MeasurementSystem, isDonatingCharity : Bool, charityName : String, charityDisplayName : String,isDeviceSensorSystemSelected: Bool,isSbdSPPaySystemSelected: Bool, isReminderSelected: Bool,  fitBitMeasurement: Bool,appVersion:String, notificationSelected: Bool, hiveChainSelected: String, steemChainSelected: String, blurtChainSelected: String, isLiquidHBDSelected: Bool, isDeclinePayoutSelected: Bool, is100PSelected: Bool) {
        autoreleasepool {
            if let realm = AppDelegate.defaultRealm() {
                realm.beginWrite()
                self.measurementSystem = measurementSystem.rawValue
                self.isDonatingCharity = isDonatingCharity
                self.charityName = charityName
                self.charityDisplayName = charityDisplayName
                self.isReminderSelected = isReminderSelected
                self.isSbdSPPaySystemSelected = isSbdSPPaySystemSelected
                self.isDeviceSensorSystemSelected = isDeviceSensorSystemSelected
                self.fitBitMeasurement = fitBitMeasurement
                self.appVersion = appVersion
                self.notificationSelected = notificationSelected
                self.hiveChain = hiveChainSelected
                self.steemChain = steemChainSelected
                self.blurtChain = blurtChainSelected
                self.isLiquidHBDSelected = isLiquidHBDSelected
                self.isDeclinePayoutSelected = isDeclinePayoutSelected
                self.is100SPSelected = is100PSelected
                do {
                    try? realm.commitWrite()
                } catch let error {
                    print(error.localizedDescription)
                }
                
            }
        }
    }
    
}

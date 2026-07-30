//
//  StepStat.swift
//  Actifit
//
//  Created by Srini on 02/02/19.
//

import UIKit

import UIKit

struct StepStat {
    
    let day: DateComponents
    let steps: UInt
    
    init?(withJSON json: String) {
        guard let jsonData = json.data(using: .utf8) else {
            return nil
        }
        self.init(withJSON: jsonData)
    }
    
    init?(withJSON jsonData: Data) {
        guard let data = (try? JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)) as? [String: Any] else {
            return nil
        }
        self.init(withDictionary: data)
    }
    
    init?(withDictionary data: [String: Any]) {
        guard let dateTime = data["dateTime"] as? String,
            let dateComponents = dateTime.dateComponents() else {
                return nil
        }
        
        guard let stepCount = (data["value"] as? NSNumber)?.uintValue ?? UInt((data["value"] as? String) ?? "") else {
            return nil
        }
        
        day = dateComponents
        steps = stepCount
    }
    
    static func fetchTodaysStepStat(forDate:Date,callback: @escaping (StepStat?, Error?)->Void) -> URLSessionDataTask? {
        let appdelegate = AFAppDelegate()
        let today = appdelegate.todayStartDate().toString(dateFormat: "yyyy-MM-dd")
        let datepassed = forDate.toString(dateFormat: "yyyy-MM-dd")
        var datePath = ""
        
        if today == datepassed{
            datePath = "/today/1d.json"
        }else{
            datePath = "/\(datepassed)/1d.json"
            
        }
        
        return fetchSteps(for: datePath) { (stepStats, error) in
            callback(stepStats?.first, error)
        }
    }
    
    static func fetchUser(acceptLanguage: String? = nil, callback: @escaping (NSDictionary?, Error?)->Void) -> URLSessionDataTask? {
        let datePath = "/today/1d.json"
        return fetchUser(for: datePath, acceptLanguage: acceptLanguage) { (stepStats, error) in
            callback(stepStats, error)
        }
    }
    
    static func fetchSteps(for dateRange: NSDateInterval, callback: @escaping ([StepStat]?, Error?)->Void) -> URLSessionDataTask? {
        let startDate = dateRange.startDate.dateString()
        let endDate = dateRange.endDate.dateString()
        let datePath = "/\(startDate)/\(endDate).json"
        return fetchSteps(for: datePath, callback: callback)
    }
    
    static func fetchSteps(for datePath: String, callback: @escaping ([StepStat]?, Error?)->Void) -> URLSessionDataTask? {
        guard let session = FitbitAPI.sharedInstance.session,
            let stepURL = URL(string: "https://api.fitbit.com/1/user/-/activities/steps/date\(datePath)") else {
                return nil
        }
        let dataTask = session.dataTask(with: stepURL) { (data, response, error) in
            guard let response = response as? HTTPURLResponse, response.statusCode < 300 else {
                DispatchQueue.main.async {
                    callback(nil, error)
                }
                return
            }
            
            guard let data = data,
                let dictionary = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: AnyObject] else {
                    DispatchQueue.main.async {
                        callback(nil, error)
                    }
                    return
            }
            print(dictionary)
            guard let steps = dictionary["activities-steps"] as? [[String: AnyObject]] else { return }
            let stats = steps.flatMap({ StepStat(withDictionary: $0) })
            DispatchQueue.main.async {
                callback(stats, nil)
            }
        }
        dataTask.resume()
        return dataTask
    }
    
    /// Builds today's/`forDate`'s datePath and fetches a Fitbit daily activity time series, e.g.
    /// `resource: "activities/tracker/distance", responseKey: "activities-tracker-distance"` or
    /// `resource: "activities/activityCalories", responseKey: "activities-activityCalories"`.
    /// Returns `nil` when unavailable → the caller falls back to a step estimate. `acceptLanguage`
    /// pins the unit system (nil = Fitbit metric default / km; "en_US" = US / miles) so the fetched
    /// distance unit matches the one the UI displays.
    static func fetchTodaysActivitySeries(resource: String, responseKey: String, acceptLanguage: String? = nil, forDate: Date, callback: @escaping (Double?) -> Void) -> URLSessionDataTask? {
        let appdelegate = AFAppDelegate()
        let today = appdelegate.todayStartDate().toString(dateFormat: "yyyy-MM-dd")
        let datepassed = forDate.toString(dateFormat: "yyyy-MM-dd")
        let datePath = (today == datepassed) ? "/today/1d.json" : "/\(datepassed)/1d.json"
        return fetchActivitySeries(resource: resource, responseKey: responseKey, acceptLanguage: acceptLanguage, for: datePath, callback: callback)
    }

    /// Sums a Fitbit daily activity time series (parallels the Android `sumFitbitTrackerMetric`).
    static func fetchActivitySeries(resource: String, responseKey: String, acceptLanguage: String? = nil, for datePath: String, callback: @escaping (Double?) -> Void) -> URLSessionDataTask? {
        guard let session = FitbitAPI.sharedInstance.session,
            let url = URL(string: "https://api.fitbit.com/1/user/-/\(resource)/date\(datePath)") else {
                callback(nil)
                return nil
        }
        var request = URLRequest(url: url)
        if let acceptLanguage = acceptLanguage {
            request.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
        }
        let dataTask = session.dataTask(with: request) { (data, response, _) in
            guard let response = response as? HTTPURLResponse, response.statusCode < 300,
                let data = data,
                let dictionary = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: Any],
                let arr = dictionary[responseKey] as? [[String: Any]], !arr.isEmpty else {
                    DispatchQueue.main.async { callback(nil) }
                    return
            }
            var sum = 0.0
            for entry in arr {
                if let n = (entry["value"] as? NSNumber)?.doubleValue {
                    sum += n
                } else if let s = entry["value"] as? String, let v = Double(s) {
                    sum += v
                }
            }
            DispatchQueue.main.async { callback(sum) }
        }
        dataTask.resume()
        return dataTask
    }

    /// `acceptLanguage` pins the profile's unit system (height/weight): nil = Fitbit metric
    /// default (cm/kg), "en_US" = US (in/lb). Pass the app's own metric/US setting so the
    /// fetched measurements match the units the UI labels them with.
    static func fetchUser(for datePath: String, acceptLanguage: String? = nil, callback: @escaping (NSDictionary?, Error?)->Void) -> URLSessionDataTask? {
        guard let session = FitbitAPI.sharedInstance.session,
            let stepURL = URL(string: "https://api.fitbit.com/1/user/-/profile.json") else {
                return nil
        }
        var request = URLRequest(url: stepURL)
        if let acceptLanguage = acceptLanguage {
            request.setValue(acceptLanguage, forHTTPHeaderField: "Accept-Language")
        }
        let dataTask = session.dataTask(with: request) { (data, response, error) in
            guard let response = response as? HTTPURLResponse, response.statusCode < 300 else {
                DispatchQueue.main.async {
                    callback(nil, error)
                }
                return
            }
            
            guard let data = data,
                let dictionary = (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)) as? [String: AnyObject] else {
                    DispatchQueue.main.async {
                        callback(nil, error)
                    }
                    return
            }
            print(dictionary)
            guard let steps = dictionary["user"] as? [String: AnyObject] else { return }
            let stats = steps as NSDictionary?
            DispatchQueue.main.async {
                callback(stats as! NSDictionary,nil)
            }
        }
        dataTask.resume()
        return dataTask
    }
}

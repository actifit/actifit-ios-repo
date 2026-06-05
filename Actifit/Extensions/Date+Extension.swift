//
//  Date+Extension.swift
//  Actifit
//
//  Created by Hitender kumar on 31/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import Foundation

extension Date {

  var today: Date {
    return Calendar.current.date(byAdding: .day, value: 0, to: noon)!
  }

  var yesterday: Date {
    return Calendar.current.date(byAdding: .day, value: -1, to: noon)!
  }
  var tomorrow: Date {
    return Calendar.current.date(byAdding: .day, value: 1, to: noon)!
  }
  var noon: Date {
    return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: self)!
  }
  var month: Int {
    return Calendar.current.component(.month,  from: self)
  }
  var isLastDayOfMonth: Bool {
    return tomorrow.month != month
  }
  func dateComponents(components: Set<Calendar.Component> = [.day, .month, .year]) -> DateComponents {
    let calendar = Calendar.current
    return calendar.dateComponents(components, from: self)
  }

  func dateString(withFormat format: String = "yyyy-MM-dd") -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: self)
  }

  func dateTimeString(withFormat format: String = "yyyy-MM-dd hh:mm") -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    return formatter.string(from: self)
  }

  func getTodaysDateWithMonthAndDay() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "E, MMM d, yyyy"
    return dateFormatter.string(from: Date())
  }

  func getTodaysDateYearAndMonthAndDay() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    return dateFormatter.string(from: Date())
  }


  func dayAfter () -> Date {
    let oneDay:Double = 60 * 60 * 24
    return addingTimeInterval(oneDay) as Date
  }
  func dayBefor () -> Date {
    let oneDay:Double = 60 * 60 * 24
    return addingTimeInterval(-(Double(oneDay))) as Date
  }

  public func setTime(hour: Int, min: Int, sec: Int) -> Date? {
    let x: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .second]
    let cal = Calendar.current
    var components = cal.dateComponents(x, from: self)

    //components.timeZone = NSTimeZone.local //TimeZone(abbreviation: timeZoneAbbrev)
    components.hour = hour
    components.minute = min
    components.second = sec

    return cal.date(from: components)
  }

  func currentDay() -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd"

    return dateFormatter.string(from: self)
  }

  static func convertServerDateString(_ dateString: String) -> String? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"

    if let date = dateFormatter.date(from: dateString) {
      let outputDateFormatter = DateFormatter()
      outputDateFormatter.dateFormat = "yyyy-MM-dd"
      return outputDateFormatter.string(from: date)
    } else {
      return nil
    }
  }

  func compareDates(dateString1: String, dateString2: String) -> ComparisonResult? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    if let date1 = dateFormatter.date(from: dateString1),
       let date2 = dateFormatter.date(from: dateString2) {
      return date1.compare(date2)
    }

    return nil // Return nil in case of invalid date strings
  }

  func dateDifferenceByNumberOfDates(startDate: String, endDate: String, dateFormat: String? = nil) -> Int? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat ?? "yyyy-MM-dd"

    if let startDate = dateFormatter.date(from: startDate),
       let endDate = dateFormatter.date(from: endDate) {
      let calendar = Calendar.current
      let components = calendar.dateComponents([.day], from: startDate, to: endDate)
      return components.day
    }

    return nil  // Return nil if date parsing fails
  }

//
  func timeDifference(from dateString: String, dateFromat: String? = nil) -> String? {
    let formatter = DateFormatter()
    formatter.dateFormat = dateFromat ?? "yyyy-MM-dd'T'HH:mmm:ss"
    formatter.timeZone = TimeZone(abbreviation: "UTC")
    guard var date = formatter.date(from: dateString) else {
      return nil
    }
    date = Calendar.current.date(byAdding: .hour, value: 0, to: date)!
    let calendar = Calendar.current
    let now = Date()
    let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)
    if let years = components.year, years > 0 {
      return "\(years) year\(years > 1 ? "s" : "") ago"
    } else if let months = components.month, months > 0 {
      return "\(months) month\(months > 1 ? "s" : "") ago"
    } else if let weeks = components.weekOfYear, weeks > 0 {
      return "\(weeks) week\(weeks > 1 ? "s" : "") ago"
    } else if let days = components.day, days > 0 {
      return "\(days) day\(days > 1 ? "s" : "") ago"
    } else if let hours = components.hour, hours > 0 {
      return "\(hours) hour\(hours > 1 ? "s" : "") ago"
    } else if let minutes = components.minute, minutes > 0 {
      return "\(minutes) minute\(minutes > 1 ? "s" : "") ago"
    } else {
      return "Just now"
    }

  }

  func converToServerDate() -> String {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyyMMddHHmmssSSS'Z'"
      dateFormatter.timeZone = TimeZone(identifier: "UTC")
      let dateString = dateFormatter.string(from: Date())
      return dateString
  }

  func timeDifferenceForVideoDate(from dateString: String, dateFormat: String? = "yyyy-MM-dd'T'HH:mm:ss.SSSZ") -> String? {
      let formatter = DateFormatter()
      formatter.dateFormat = dateFormat
      formatter.locale = Locale(identifier: "en_US_POSIX")
      formatter.timeZone = TimeZone(secondsFromGMT: 0)

      guard let date = formatter.date(from: dateString) else {
          return nil
      }

      let calendar = Calendar.current
      let now = Date()
      let components = calendar.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)

      if let years = components.year, years > 0 {
          return "\(years) year\(years > 1 ? "s" : "") ago"
      } else if let months = components.month, months > 0 {
          return "\(months) month\(months > 1 ? "s" : "") ago"
      } else if let weeks = components.weekOfYear, weeks > 0 {
          return "\(weeks) week\(weeks > 1 ? "s" : "") ago"
      } else if let days = components.day, days > 0 {
          return "\(days) day\(days > 1 ? "s" : "") ago"
      } else if let hours = components.hour, hours > 0 {
          return "\(hours) hour\(hours > 1 ? "s" : "") ago"
      } else if let minutes = components.minute, minutes > 0 {
          return "\(minutes) minute\(minutes > 1 ? "s" : "") ago"
      } else {
          return "Just now"
      }
  }


  func areDatesEqual(dateString1: String, format1: String, dateString2: String, format2: String) -> Bool {
      // DateFormatter for the first date format
      let formatter1 = DateFormatter()
      formatter1.dateFormat = format1


      // DateFormatter for the second date format
      let formatter2 = DateFormatter()
      formatter2.dateFormat = format2

      // Parse the dates
      if let date1 = formatter1.date(from: dateString1),
         let date2 = formatter2.date(from: dateString2) {

          // Extract day, month, and year components
          let calendar = Calendar.current
          let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
          let components2 = calendar.dateComponents([.year, .month, .day], from: date2)

          // Compare the components
          return components1.day == components2.day && components1.month == components2.month
      } else {
          // Return false if either date could not be parsed
          return false
      }
  }

}


//extension Date {
//  var ticks: UInt64 {
//    return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
//  }
//}
//
extension Date {
  var ticks: UInt64 {
    return UInt64((self.timeIntervalSince1970 + 62_135_596_800) * 10_000_000)
  }
}
//
//extension Digest {
//  var bytes: [UInt8] { Array(makeIterator()) }
//  var data: Data { Data(bytes) }
//
//  var hexStr: String {
//    bytes.map { String(format: "%02X", $0) }.joined()
//  }
//}

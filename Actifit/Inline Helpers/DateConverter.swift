//
//  DateConverter.swift
//  Actifit
//
//  Created by Ali Jaber on 26/07/2023.
//

import Foundation
import Foundation
class DateConverter {
    func compareDates(dateString: String) -> String? {
        // Create a DateFormatter to parse the input date string
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        // Parse the input date string into a Date object
        if let date = dateFormatter.date(from: dateString) {
            // Get the current date and time
            let currentDate = Date()
            
            // Calculate the time difference between the input date and the current date
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month, .weekOfMonth, .day, .hour], from: currentDate, to: date)
            
            // Extract the difference in years, months, weeks, days, and hours
            if let years = components.year, abs(years) > 0 {
                return "\(abs(years)) year\(abs(years) > 1 ? "s" : "") \(years > 0 ? "ago" : "")"
            } else if let months = components.month, abs(months) > 0 {
                return "\(abs(months)) month\(abs(months) > 1 ? "s" : "") \(months > 0 ? "ago" : "")"
            } else if let weeks = components.weekOfMonth, abs(weeks) > 0 {
                return "\(abs(weeks)) week\(abs(weeks) > 1 ? "s" : "") \(weeks > 0 ? "ago" : "")"
            } else if let days = components.day, abs(days) > 0 {
                return "\(abs(days)) day\(abs(days) > 1 ? "s" : "") \(days > 0 ? "ago" : "")"
            } else if let hours = components.hour, abs(hours) > 0 {
                return "\(abs(hours)) hour\(abs(hours) > 1 ? "s" : "") \(hours > 0 ? "ago" : "")"
            }
            
            return "Just now" // If the difference is less than an hour, return "Just now"
        }
        
        // Return nil if there was an error parsing the date or calculating the difference
        return nil
    }
}

//
//  SurveyModel.swift
//  Actifit
//
//  Created by Ali Jaber on 28/09/2023.
//

import Foundation
struct SurveyModel: Codable {
    let id: String?
    let imageURL: String?
    let title: String?
    let url: String?
    let startDate: String?
    let endDate: String?
    let enabled: Bool?
    let surveyReward: Int?
    let surveyOptions: [String]?
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case imageURL = "image"
        case title,url,endDate,enabled
        case startDate = "date"
        case surveyReward = "survey_reward"
        case surveyOptions = "survey_options"
    }
    
    
    func isValidSurvey() -> Bool {
           let dateFormatter = DateFormatter()
           dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
           
        if let endDateDate = dateFormatter.date(from: endDate ?? "") {
               let currentDate = Date()
               return (endDateDate > currentDate) && (startDate != "" || startDate != nil)
           }
           
           return false
       }
}


struct PollChoiceModel {
    let questionCount: Int?
    let choiceName: String?
    var isSelected: Bool = false
    init(questionCount: Int, choiceName: String?, isSelected: Bool) {
        self.questionCount = questionCount
        self.choiceName = choiceName
    }
    
    mutating func changeSelectionValue(isSelected: Bool) {
        self.isSelected = isSelected
    }
    
    
}

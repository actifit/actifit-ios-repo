//
//  PollDisplayViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 28/09/2023.
//

import Foundation
import Combine
class PollDisplayViewModel {
    var numberOfRows: Int {
        if surveyModel.surveyOptions == nil {
            return 0
        }
        return surveyModel.surveyOptions!.count + 3
    }
    var pollChoices: [PollChoiceModel]  = []
    private let refreshSubject = PassthroughSubject<Bool, Never>()
    var refreshPublisher : AnyPublisher<Bool, Never> {
        return refreshSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    private let didVoteSuccessfullySubject = PassthroughSubject<Bool, Never>()
    var didVoteSuccessfullyPublisher : AnyPublisher<Bool, Never> {
        return didVoteSuccessfullySubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    var surveyModel: SurveyModel!
    init(survey: SurveyModel) {
        self.surveyModel = survey
        generatePollChoices()
        refreshSubject.send(true)
    }
    
    func getPollModelByIndex(index: Int) -> PollChoiceModel {
        let realIndex = index - 3
        return pollChoices[realIndex]
    }
    
    private func generatePollChoices() {
      if let options = surveyModel.surveyOptions {
        for index in 0 ... options.count - 1 {
          pollChoices.append(PollChoiceModel(questionCount: index, choiceName: surveyModel.surveyOptions?[index], isSelected: false))
        }
      }
    }
    
    func updateChoiceSelection(index: Int, newStatus: Bool) {
        for index in 0 ... pollChoices.count - 1 {
            pollChoices[index].changeSelectionValue(isSelected: false)
        }
        pollChoices[index - 3].changeSelectionValue(isSelected: newStatus)
        refreshSubject.send(true)
    }
    
    func getPollParticipationText() -> String {
        let participationText = NSLocalizedString("survey_poll_participation", comment: "")
        let formattedString = String(format: participationText, "\(surveyModel.surveyReward ?? 0)")
        return formattedString
    }
    
    func castVoteAPI() {
        if let selectedObject = pollChoices.filter({$0.isSelected == true}).first,
        let choiceIndex = pollChoices.firstIndex(where: {$0.choiceName == selectedObject.choiceName}) {
            if let userName = User.current()?.steemit_username, let surveyId = surveyModel.id {
                API().castSurveyVoice(userName: userName, surveyId: surveyId, option: String(choiceIndex + 1)) { info, statusCode in
                    if statusCode == 200 {
                        self.didVoteSuccessfullySubject.send(true)
                    } else {
                        self.didVoteSuccessfullySubject.send(false)
                    }
                } failure: { error in
                    self.didVoteSuccessfullySubject.send(false)
                }

            }
        }
    }
    
}

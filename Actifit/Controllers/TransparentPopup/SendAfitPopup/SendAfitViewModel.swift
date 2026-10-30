//
//  SendAfitViewModel.swift
//  Actifit
//
//  Created by Ali Jaber on 16/11/2023.
//

import Foundation
import Combine
class SendAfitViewModel {
    var cancellables = Set<AnyCancellable>()
    private let showToastSubject =  PassthroughSubject<String, Never>()
    var showToastPublisher: AnyPublisher<String, Never> {
        return showToastSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    private let showLoaderSubject =  PassthroughSubject<Bool, Never>()
    var showLoaderPublisher: AnyPublisher<Bool, Never> {
        return showLoaderSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    
    private let dismissScreenSubject =  PassthroughSubject<Bool, Never>()
    var dismissScreenPublisher: AnyPublisher<Bool, Never> {
        return dismissScreenSubject.receive(on: DispatchQueue.main).eraseToAnyPublisher()
    }
    init() {}
    
    /// Sending AFIT went through /tipAccount with the funds password; the backend has paused the
    /// route and retired the password after the October 2026 security incident.
    func sendAmountAPI(targetUser: String, amount: String, note: String, userAfitAmount: Double) {
        showToastSubject.send(Copy.text("send_afit_paused", "Sending AFIT is paused for now while Actifit completes a security upgrade."))
    }
}



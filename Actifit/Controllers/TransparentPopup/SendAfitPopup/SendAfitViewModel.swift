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
    
    func sendAmountAPI(targetUser: String, amount: String, note: String, userAfitAmount: Double) {
        guard let userName = User.current()?.steemit_username else { return }
         let fundPassword = UserDefaults.standard.fundPassword
        guard fundPassword != "" else {
            self.showToastSubject.send("Please make sure to set your funds password under settings")
            return
            
        }
       
        if Int(amount) ?? 0 > 10000  || Int(amount) == 0  || amount == "" {
            self.showToastSubject.send("Please provide a proper AFIT amount within range (0-10,000)")
            return
        }
        else if(Double(amount) ?? 0.0 > userAfitAmount) {
            self.showToastSubject.send("Cannot send more than your current balance")
            return
        } else if Double(amount) ?? 0.0 < 0 {
            self.showToastSubject.send("Please provide a proper positive amount within balance")
            return
        }
        if targetUser == userName {
            self.showToastSubject.send("Cannot send funds to self")
            return
        }
        showLoaderSubject.send(true)
            //TODO: get fundPass from the settings after integrating it
            API().sendAfitAmount(username: userName, targetUser: targetUser, amount: amount, fundPass: fundPassword, note: note) { info, statusCode in
             
                if let response = info as? String {
                    let data = response.utf8Data()
                    let decoder = JSONDecoder()
                    do {
                        let transactionTipResponse  = try decoder.decode(TipResponse.self, from: data)
                        if transactionTipResponse.status == "Success" {
                            self.broadCastAmountSent(targetUser: targetUser, amount: amount, note: note)
                        }
                    }
                    catch {
                        print("Error decoding JSON: \(error.localizedDescription)")
                    }
                }
                
            } failure: { error in
                print(error.localizedDescription)
            }
        }
    
    
    
    

    
    
    func broadCastAmountSent(targetUser: String, amount: String, note: String) {
        guard let userName = User.current()?.steemit_username else { return }
        API().broadCasrtAfitAmountSent(username: userName, targetUser: targetUser, amount: amount, note: note) { info, statusCode in
            self.showLoaderSubject.send(false)
            self.dismissScreenSubject.send(true)
            if let response = info as? String {
                let data = response.utf8Data()
                let decoder = JSONDecoder()
                do {
                    let myData = try decoder.decode(BroadCastAPIResponse.self, from: data)
                }
                catch {
                    print("Error decoding JSON: \(error.localizedDescription)")
                }
            }
        } failure: { error in
            print(error.localizedDescription)
        }

    }
}



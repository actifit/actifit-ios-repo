//
//  SednAfitViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 16/11/2023.
//

import UIKit

class SendAfitViewController: UIViewController {
    @IBOutlet weak var recipientTextField: UITextField!
    
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    
    @IBOutlet weak var sendBtn: UIButton!
    @IBOutlet weak var cancelBtn: UIButton!
    var viewModel = SendAfitViewModel()
    var afitAmount: Double?
    var onCompleteTransaction: (() -> ())?
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()

        // Do any additional setup after loading the view.
    }
    private func setUI() {
        backView.layer.cornerRadius = 5
        backView.clipsToBounds = true
        cancelBtn.layer.cornerRadius = 5
        cancelBtn.clipsToBounds = true
        sendBtn.layer.cornerRadius = 5
        sendBtn.clipsToBounds = true
        setBinding()
    }
    
    private func setBinding() {
        viewModel.showToastPublisher.receive(on: DispatchQueue.main).sink { message in
            self.showToast(message: message)
        }.store(in: &viewModel.cancellables)
        
        viewModel.showLoaderPublisher.receive(on: DispatchQueue.main).sink { showLoader in
            self.showLoader(isShowing: showLoader)
        }.store(in: &viewModel.cancellables)
        
        viewModel.dismissScreenPublisher.receive(on: DispatchQueue.main).sink { dismiss in
            self.dismissScreen()
        }.store(in: &viewModel.cancellables)
        
    }
    
    func dismissScreen() {
        DispatchQueue.main.async {
            self.showAlertWithOkCompletion(title: "", message: "Transaction Completed Successfully!") { finished in
                self.onCompleteTransaction?()
                self.dismiss(animated: true)
            }
        }
    }
    
    private func showLoader(isShowing: Bool) {
        if isShowing == true {
            ActifitLoader.show(title: "Loading...", animated: true)
        } else {
            ActifitLoader.hide()
        }
    }
    
    static func create(afit: Double,  completeTransaction: (() -> ())?) -> SendAfitViewController {
        let vc = UIStoryboard(name: "SendAfit", bundle: nil).instantiateViewController(withIdentifier: "SendAfitViewController") as! SendAfitViewController
        vc.afitAmount = afit
        vc.modalPresentationStyle = .overFullScreen
        vc.onCompleteTransaction = completeTransaction
        return vc
    }
    

    @IBAction func cancelBtnTapped(_ sender: Any) {
      
            dismiss(animated: true)
        
//        viewModel.broadCastAmountSent()
    }
    
    @IBAction func sendBtnTapped(_ sender: Any) {
        if let reciepient = recipientTextField.text, reciepient != "", let amount = amountTextField.text {
            viewModel.sendAmountAPI(targetUser: reciepient, amount: amount, note: noteTextField.text ?? "", userAfitAmount: afitAmount ?? 0.0)
        } else {
            self.showToast(message: "Recipient cannot be empty")
        }
    }
    
}

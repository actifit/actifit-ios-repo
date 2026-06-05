//
//  SendHiveViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 23/11/2023.
//

import UIKit

class SendHiveViewController: UIViewController {
    @IBOutlet weak var tokenTypeView: UIView!
    
    @IBOutlet weak var tokenTypeLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var receiverTextField: UITextField!
    @IBOutlet weak var memoTextField: UITextField!
    @IBOutlet weak var amountTypeLabel: UILabel!
    @IBOutlet weak var numberOfTokensTextfield: UITextField!
    @IBOutlet weak var maxBtn: UIButton!
    @IBOutlet weak var backView: UIView!
    @IBOutlet weak var cancelBtn: UIButton!
    var selectedBlockChain:TokenType = .hive
    @IBOutlet weak var sendBtn: UIButton!
    var hive: String!
    var hbd: String!
    var onCompleteTransaction: (() -> ())?
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()

        // Do any additional setup after loading the view.
    }
    
    private func setUI() {
        tokenTypeView.layer.cornerRadius = 5
        tokenTypeView.clipsToBounds = true
        backView.layer.cornerRadius = 5
        backView.clipsToBounds = true
        maxBtn.layer.cornerRadius = 5
        maxBtn.clipsToBounds = true
        pickerView.backgroundColor = .white
        pickerView.isHidden = true
        backView.layer.cornerRadius = 5
        backView.clipsToBounds = true
        cancelBtn.layer.cornerRadius = 5
        cancelBtn.clipsToBounds = true
        sendBtn.layer.cornerRadius = 5
        sendBtn.clipsToBounds = true
        let gesture = UITapGestureRecognizer(target: self, action: #selector(showPicker))
        tokenTypeView.addGestureRecognizer(gesture)
        amountTypeLabel.text = selectedBlockChain == .hive ? "\(self.hive!) HIVE" : "\(self.hbd!) HBD"
        
        
    }
    
    private func showLoader(isShowing: Bool) {
        if isShowing == true {
            ActifitLoader.show(title: "Loading...", animated: true)
        } else {
            ActifitLoader.hide()
        }
    }
    
    @objc func showPicker() {
        view.endEditing(true)
        pickerView.isHidden = false
    }
    
    static func create (hive: String, hbd: String, completeTransaction: (() -> ())?) -> SendHiveViewController {
        let vc = UIStoryboard(name: "SendHivePopup", bundle: nil).instantiateViewController(withIdentifier: "SendHiveViewController") as! SendHiveViewController
        vc.modalPresentationStyle = .overFullScreen
        vc.hbd = hbd
        vc.hive = hive
        vc.onCompleteTransaction = completeTransaction
        return vc
    }
    
    @IBAction func maxBtnTapped(_ sender: Any) {
        numberOfTokensTextfield.text = selectedBlockChain == .hive ? hive : hbd
    }
    
    @IBAction func cancelBtnTapped(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func sendBtnTapped(_ sender: Any) {
        let activeKey = UserDefaults.standard.activeKey
       guard activeKey != "" else {
           self.showToast(message: "Please make sure to set your active key under settings")
           return
       }
        if let tokens =  numberOfTokensTextfield.text, let receiver = receiverTextField.text{
            guard let username = User.current()?.steemit_username else { return }
            if username == receiver {
                self.showToast(message: "Cannot send funds to self")
                return
            }
            if receiver == "" {
                self.showToast(message: " Recipient cannot be empty")
                return
               
            }
            if tokens == "" {
                self.showToast(message: "Please provide a proper positive amount within balance")
                return
            }
            if selectedBlockChain == .hbd {
                if Double(tokens) ?? 0.0 > Double(self.hbd) ?? 0.0 {
                    self.showToast(message: "Cannot send more than your current balance")
                    return
                }
            } else {
                if Double(tokens) ?? 0.0 > Double(self.hive) ?? 0.0 {
                    self.showToast(message: "Cannot send more than your current balance")
                    return
                }
            }
            if Double(tokens) ?? 0.0 <= 0 {
                self.showToast(message: "Please provide a proper positive amount within balance")
                return
            }
            showLoader(isShowing: true)
            API().sendHiveOrHBDAPI(from: username, to: receiver, amount: (tokens.formatToThreeDecimalPlaces() ?? "") + " " + selectedBlockChain.rawValue, memo: memoTextField.text, completion: { info, statusCode in
                self.showLoader(isShowing: false)
                if let response = info as? String {
                    let data = response.utf8Data()
                    do {
                           // Deserialize JSON
                           if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                               // Extract the "success" value
                               if let success = json["success"] as? Bool, success == true {
                                   self.dismissScreen()
                               } else {
                                   DispatchQueue.main.async {
                                       self.showToast(message: "Error, please try again")
                                   }
                                   
                               }
                           }
                       } catch {
                           DispatchQueue.main.async {
                               self.showToast(message: "Error, please try again")
                           }
                           print("Error deserializing JSON: \(error)")
                       }
                    
                    
                }
            }, failure: { error in
                
            }, blockChain: selectedBlockChain.rawValue, activeKey: activeKey)
            
        } else {
            self.showToast(message: "Please provide a proper amount")
        }
    }
    
    func dismissScreen() {
        DispatchQueue.main.async {
            self.showLoader(isShowing: false)
            self.showAlertWithOkCompletion(title: "", message: "Transaction Completed Successfully!") { finished in
                self.onCompleteTransaction?()
                self.dismiss(animated: true)
                   
                
            }
        }
    }
    
}

enum TokenType: String {
    case hive = "HIVE"
    case hbd = "HBD"
}


extension SendHiveViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch row {
        case 0: return TokenType.hive.rawValue
        case 1: return TokenType.hbd.rawValue
        default: return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedBlockChain = row == 0 ? TokenType.hive : TokenType.hbd
        amountTypeLabel.text = selectedBlockChain == .hive ? "\(hive ?? "") HIVE" : "\(hbd ?? "")HBD"
        tokenTypeLabel.text = selectedBlockChain == .hive ? "\(hive ?? "") HIVE" : "\(hbd ?? "")HBD"
        numberOfTokensTextfield.text = ""
        pickerView.isHidden = true
    }
    

    
    
}

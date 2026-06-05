//
//  LoginViewController.swift
//  Actifit
//
//  Created by Ali Jaber on 03/07/2023.
//

import UIKit
import Combine
import IQKeyboardManagerSwift
import SafariServices
class LoginViewController: UIViewController {

    @IBOutlet weak var loginTitleLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var createAccountLabel: UILabel!
    @IBOutlet weak var biometricIdBtn: UIButton!
    @IBOutlet weak var privatePostingKeyLabel: UILabel!
    @IBOutlet weak var proceedButton: UIButton!
    @IBOutlet weak var skipButton: UIButton!
    @IBOutlet weak var privatePostingKeyTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var helpMeFindKeyLabel: UILabel!
    
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    private var loginViewModel = LoginViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var cancellable: AnyCancellable?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBinding()
        setUI()

    }
    
    private func setupBinding() {
        loginViewModel.$loginEnabled.receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                //enable//disable proceed button
            }
            .store(in: &cancellables)
        
        cancellable = loginViewModel.imagePublisher()
            .sink {[weak self] image in
                self?.imageView.image = image
                
            }
        
        loginViewModel.successProcessPublisher.sink {[weak self ] success in
            success == true ? self?.goToActivities() : self?.showAlertWith(title: "", message: "You have provided incorrect credentials.\nPlease check and try to login again")
        }
        .store(in: &cancellables)
        
        loginViewModel.loaderVisibilityPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] showLoader in
                showLoader ?  ActifitLoader.show(title: Messages.validatingCredentials, animated: true) : ActifitLoader.hide()
            }
            .store(in: &cancellables)
        
        loginViewModel.imageLoaderVisibiltyPublisher.receive(on: DispatchQueue.main)
            .sink {[weak self] showImageLoader in
                showImageLoader ? self?.imageView.showLoader() : self?.imageView.hideLoader()
            }.store(in: &cancellables)
        
        loginViewModel.isUserBiometricAuthorizedPublisher.receive(on: DispatchQueue.main).sink {[weak self] isAuthorized in
            if isAuthorized {
                if let user = try? Keychain.getObject(castTo: UserModel.self, with: KeychainKeys.user.rawValue) {
                    self?.usernameTextField.text = user.username
                    self?.privatePostingKeyTextField.text = user.privatePostingKey
                    self?.fireLoginAPI()
                }
            }
            
        }.store(in: &cancellables)
        
    }
    
    @IBAction func biometricIdBtnTapped(_ sender: Any) {
        loginViewModel.authorizeUser()
       
        
    }
    
    
    private func setUI() {
        imageView.showLoader()
        imageHeightConstraint.constant = view.frame.height / 2.2
        usernameLabel.text = "steem_username_lbl".localized()
        createAccountLabel.text = "create_account".localized()
        privatePostingKeyLabel.text = "private_posting_key".localized()
        helpMeFindKeyLabel.text = "help_me_find_posting_key".localized()
        helpMeFindKeyLabel.textColor = loginViewModel.labelRedColor
        helpMeFindKeyLabel.underLine()
        loginTitleLabel.textColor = loginViewModel.labelRedColor
        loginTitleLabel.font = UIFont.boldFont(ofSize: 16)
        usernameLabel.font = UIFont.boldFont(ofSize: 16)
        privatePostingKeyLabel.font = UIFont.boldFont(ofSize: 16)
        usernameLabel.textColor = loginViewModel.labelRedColor
        createAccountLabel.textColor = loginViewModel.labelRedColor
        createAccountLabel.underLine()
        usernameTextField.delegate = self
        privatePostingKeyLabel.textColor = loginViewModel.labelRedColor
        privatePostingKeyTextField.delegate = self
        
        usernameTextField.layer.borderWidth = 2
        usernameTextField.layer.borderColor = loginViewModel.labelRedColor.cgColor
        usernameTextField.clipsToBounds = true
        usernameTextField.layer.cornerRadius = 5
        
        privatePostingKeyTextField.layer.borderWidth = 2
        privatePostingKeyTextField.layer.borderColor = loginViewModel.labelRedColor.cgColor
        privatePostingKeyTextField.clipsToBounds = true
        privatePostingKeyTextField.layer.cornerRadius = 5
        
        skipButton.setTitle("skip".localized(), for: .normal)
        proceedButton.setTitle("proceed".localized(), for: .normal)
        biometricIdBtn.setTitle("proceed_by_biometric".localized(), for: .normal)
        biometricIdBtn.backgroundColor = loginViewModel.labelRedColor
        biometricIdBtn.setTitleColor(.white, for: .normal)
        
        proceedButton.backgroundColor = loginViewModel.labelRedColor
        proceedButton.setTitleColor(.white, for: .normal)
        proceedButton.layer.cornerRadius = 5
        proceedButton.clipsToBounds = true
        skipButton.setTitleColor(loginViewModel.labelRedColor, for: .normal)
        
        let helpMegesture = UITapGestureRecognizer(target: self, action: #selector(onHelpMeFindKeyTapped(_:)))
        helpMeFindKeyLabel.isUserInteractionEnabled = true
        helpMeFindKeyLabel.addGestureRecognizer(helpMegesture)
        
        
        let createAccountGesture = UITapGestureRecognizer(target: self, action: #selector(onCreateAccountTapped(_:)))
        createAccountLabel.isUserInteractionEnabled = true
        createAccountLabel.addGestureRecognizer(createAccountGesture)
        usernameTextField.returnKeyType = .continue
        privatePostingKeyTextField.returnKeyType = .done
        
    }
    
//    private func goToActivities() {
//        DispatchQueue.main.async {
//            let storyboard = UIStoryboard(name: "Tabbar", bundle: nil)
//            let tabbarController = storyboard.instantiateViewController(withIdentifier: "TabbarController") as! TabbarController
//
//            navigationController.modalPresentationStyle = .fullScreen // Customize presentation style if needed
//
//            self.present(navigationController, animated: true, completion: nil)
//        }
//    }

    private func goToActivities() {
        if let appDelegate = UIApplication.shared.delegate as? AFAppDelegate {
//                guard let delegate = scene.delegate as? SceneDelegate else {
//                    print("Scene delegate not found.")
//                    return
//                }



                let storyboard = UIStoryboard(name: "Tabbar", bundle: nil)
                let tabbarController = storyboard.instantiateViewController(withIdentifier: "TabbarController") as! TabbarController
                let navigationController = UINavigationController(rootViewController: tabbarController)
               // delegate.window?.rootViewController = navigationController
            appDelegate.window?.rootViewController = navigationController
                     appDelegate.window?.makeKeyAndVisible()
//                UIView.transition(with: delegate.window!,
//                                  duration: 0.5,
//                                  options: .transitionFlipFromRight,
//                                  animations: {
//                                      delegate.window?.makeKeyAndVisible()
//                                  }, completion: nil)
            }
//        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
//            guard let delegate = scene.delegate as? SceneDelegate else {
//                print("Scene delegate not found.")
//                return
//            }
//
//
//
//            let storyboard = UIStoryboard(name: "Tabbar", bundle: nil)
//            let tabbarController = storyboard.instantiateViewController(withIdentifier: "TabbarController") as! TabbarController
//            let navigationController = UINavigationController(rootViewController: tabbarController)
//            delegate.window?.rootViewController = navigationController
//
//            UIView.transition(with: delegate.window!,
//                              duration: 0.5,
//                              options: .transitionFlipFromRight,
//                              animations: {
//                                  delegate.window?.makeKeyAndVisible()
//                              }, completion: nil)
//        }
    }

    @IBAction func onSkipTapped(_ sender: Any) {
        goToActivities()
       
    }
    
    @IBAction func onProceedTapped(_ sender: Any) {
       fireLoginAPI()
      
    }
    
    func fireLoginAPI() {
        loginViewModel.proceedTapped(username: usernameTextField.text ?? "", privatePostingKey: privatePostingKeyTextField.text ?? "")
    }
    
    @objc private func onCreateAccountTapped(_ gesture: UITapGestureRecognizer) {
        openSafari(url: AppConstants.createAccountURL)
    }
    
    private func openSafari(url: URL) {
        let controller = SFSafariViewController(url: url)
        present(controller, animated: true, completion: nil)
    }
    
    @objc private func onHelpMeFindKeyTapped(_ gesture: UITapGestureRecognizer) {
        openSafari(url: AppConstants.findPrivatePostingKeyURL)
    }
    
}

extension LoginViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameTextField {
               privatePostingKeyTextField.becomeFirstResponder()
        } else if textField == privatePostingKeyTextField {
            textField.resignFirstResponder()
            if let username = usernameTextField.text, !username.isEmpty, let postingKey = privatePostingKeyTextField.text, !postingKey.isEmpty {
                fireLoginAPI()
            }
        }
           // Return false to indicate that the text field should not process the Return key
           return true
    }

}
//hive.guy
//5JsDjHm59mojuhKEDk3ffDm9NBemmL98SQBzzELbpELs1EnCSy5

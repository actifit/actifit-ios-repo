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
import AVFoundation
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
    private var loginGradient: CAGradientLayer?
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBinding()
        setupRevampedLogin()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        loginGradient?.frame = view.bounds
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
    
    
    // MARK: - Revamped login (Android parity: card over a darkened hero)

    private let loginRed = UIColor.primaryRedColor()
    private let loginSeparator = UIColor(red: 224/255, green: 224/255, blue: 224/255, alpha: 1)
    private let loginTextSecondary = UIColor(red: 117/255, green: 117/255, blue: 117/255, alpha: 1)

    private func setupRevampedLogin() {
        // Hide the legacy storyboard content; the revamp is built programmatically on top.
        view.subviews.forEach { $0.isHidden = true }
        view.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)

        // 135° gradient base (#F5F5F5 -> #FFFFFF)
        let gradient = CAGradientLayer()
        gradient.colors = [UIColor(white: 0.96, alpha: 1).cgColor, UIColor.white.cgColor]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = view.bounds
        view.layer.insertSublayer(gradient, at: 0)
        loginGradient = gradient

        // Dynamic hero background (re-point the imageView outlet so the VM's image
        // publisher keeps filling it) + dark overlay for contrast.
        let hero = UIImageView()
        hero.contentMode = .scaleAspectFill
        hero.clipsToBounds = true
        hero.alpha = 0.3
        hero.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hero)
        pinToView(hero)
        self.imageView = hero

        let overlay = UIView()
        overlay.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlay)
        pinToView(overlay)

        // Scrollable, centered content
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.keyboardDismissMode = .interactive
        scroll.showsVerticalScrollIndicator = false
        view.addSubview(scroll)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = UIEdgeInsets(top: 60, left: 24, bottom: 40, right: 24)
        content.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(content)
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(greaterThanOrEqualTo: scroll.contentLayoutGuide.topAnchor),
            content.bottomAnchor.constraint(lessThanOrEqualTo: scroll.contentLayoutGuide.bottomAnchor),
            content.centerYAnchor.constraint(equalTo: scroll.contentLayoutGuide.centerYAnchor),
            content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
            content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor)
        ])

        // Branding: logo + wordmark + tagline
        let logo = UIImageView(image: UIImage(named: "circular_logo") ?? UIImage(named: "logo"))
        logo.contentMode = .scaleAspectFit
        logo.translatesAutoresizingMaskIntoConstraints = false
        logo.heightAnchor.constraint(equalToConstant: 100).isActive = true

        let wordmark = UILabel()
        wordmark.attributedText = NSAttributedString(string: "ACTIFIT", attributes: [
            .font: UIFont.systemFont(ofSize: 32, weight: .bold),
            .foregroundColor: loginRed,
            .kern: 3.0
        ])
        wordmark.textAlignment = .center

        let tagline = UILabel()
        tagline.text = "Move. Earn. Thrive."
        tagline.font = .systemFont(ofSize: 16, weight: .bold)
        tagline.textColor = .white
        tagline.textAlignment = .center
        tagline.layer.shadowColor = UIColor.black.cgColor
        tagline.layer.shadowOpacity = 0.5
        tagline.layer.shadowRadius = 3
        tagline.layer.shadowOffset = CGSize(width: 0, height: 1)
        tagline.layer.masksToBounds = false

        content.addArrangedSubview(logo)
        content.addArrangedSubview(wordmark)
        content.addArrangedSubview(tagline)
        content.setCustomSpacing(8, after: logo)
        content.setCustomSpacing(24, after: tagline)

        // Card
        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 14
        card.isLayoutMarginsRelativeArrangement = true
        card.layoutMargins = UIEdgeInsets(top: 20, left: 18, bottom: 20, right: 18)
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOpacity = 0.12
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 3)

        // Username
        let username = UITextField()
        styleLoginField(username, placeholder: "Username", icon: "person")
        username.returnKeyType = .continue
        username.autocapitalizationType = .none
        username.autocorrectionType = .no
        self.usernameTextField = username

        // Posting key + QR
        let key = PasswordTextField()
        styleLoginField(key, placeholder: "Private Posting Key", icon: "lock")
        key.returnKeyType = .done
        key.autocapitalizationType = .none
        key.autocorrectionType = .no
        self.privatePostingKeyTextField = key

        let qrButton = UIButton(type: .system)
        qrButton.setImage(UIImage(systemName: "qrcode.viewfinder"), for: .normal)
        qrButton.tintColor = .white
        qrButton.backgroundColor = loginRed
        qrButton.layer.cornerRadius = 12
        qrButton.translatesAutoresizingMaskIntoConstraints = false
        qrButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        qrButton.addTarget(self, action: #selector(qrScanTapped), for: .touchUpInside)
        let keyRow = UIStackView(arrangedSubviews: [key, qrButton])
        keyRow.axis = .horizontal
        keyRow.spacing = 10
        keyRow.alignment = .fill

        // Login button
        let login = UIButton(type: .system)
        login.setTitle("Login", for: .normal)
        login.setTitleColor(.white, for: .normal)
        login.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        login.backgroundColor = loginRed
        login.layer.cornerRadius = 12
        login.translatesAutoresizingMaskIntoConstraints = false
        login.heightAnchor.constraint(equalToConstant: 50).isActive = true
        login.addTarget(self, action: #selector(onProceedTapped(_:)), for: .touchUpInside)
        self.proceedButton = login

        // Guest (outlined)
        let guest = UIButton(type: .system)
        guest.setTitle("Continue as Guest", for: .normal)
        guest.setTitleColor(loginRed, for: .normal)
        guest.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        guest.layer.borderColor = loginRed.cgColor
        guest.layer.borderWidth = 1.5
        guest.layer.cornerRadius = 12
        guest.translatesAutoresizingMaskIntoConstraints = false
        guest.heightAnchor.constraint(equalToConstant: 48).isActive = true
        guest.addTarget(self, action: #selector(onSkipTapped(_:)), for: .touchUpInside)
        self.skipButton = guest

        card.addArrangedSubview(username)
        card.addArrangedSubview(keyRow)
        card.addArrangedSubview(login)
        card.addArrangedSubview(makeOrDivider())
        card.addArrangedSubview(guest)
        content.addArrangedSubview(card)

        // Optional Face ID (iOS-only bonus) — only when creds are stored in the Keychain.
        if (try? Keychain.getObject(castTo: UserModel.self, with: KeychainKeys.user.rawValue)) != nil {
            let faceID = UIButton(type: .system)
            faceID.setImage(UIImage(systemName: "faceid"), for: .normal)
            faceID.setTitle("  Log in with Face ID", for: .normal)
            faceID.tintColor = .white
            faceID.setTitleColor(.white, for: .normal)
            faceID.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
            faceID.addTarget(self, action: #selector(biometricIdBtnTapped(_:)), for: .touchUpInside)
            content.addArrangedSubview(faceID)
            self.biometricIdBtn = faceID
        }

        // Helper links (semi-white, over the dark hero)
        content.addArrangedSubview(makeLinkLabel("Create an account", action: #selector(onCreateAccountTapped(_:))))
        content.addArrangedSubview(makeLinkLabel("Help me find my Private Posting Key", action: #selector(onHelpMeFindKeyTapped(_:))))

        imageView.showLoader()
    }

    private func pinToView(_ v: UIView) {
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: view.topAnchor),
            v.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            v.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func styleLoginField(_ tf: UITextField, placeholder: String, icon: String) {
        tf.placeholder = placeholder
        tf.textColor = UIColor(white: 0.13, alpha: 1)
        tf.font = .systemFont(ofSize: 16)
        tf.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        tf.layer.cornerRadius = 12
        tf.layer.borderWidth = 1
        tf.layer.borderColor = loginSeparator.cgColor
        tf.clipsToBounds = true
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.heightAnchor.constraint(equalToConstant: 50).isActive = true
        tf.delegate = self
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = loginTextSecondary
        iconView.frame = CGRect(x: 14, y: 15, width: 20, height: 20)
        let leftContainer = UIView(frame: CGRect(x: 0, y: 0, width: 46, height: 50))
        leftContainer.addSubview(iconView)
        tf.leftView = leftContainer
        tf.leftViewMode = .always
    }

    private func makeOrDivider() -> UIView {
        func line() -> UIView {
            let v = UIView(); v.backgroundColor = loginSeparator
            v.translatesAutoresizingMaskIntoConstraints = false
            v.heightAnchor.constraint(equalToConstant: 1).isActive = true
            return v
        }
        let or = UILabel(); or.text = "or"; or.textColor = loginTextSecondary; or.font = .systemFont(ofSize: 13)
        or.setContentHuggingPriority(.required, for: .horizontal)
        let row = UIStackView(arrangedSubviews: [line(), or, line()])
        row.axis = .horizontal; row.spacing = 10; row.alignment = .center; row.distribution = .fill
        return row
    }

    private func makeLinkLabel(_ text: String, action: Selector) -> UILabel {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: text, attributes: [
            .underlineStyle: NSUnderlineStyle.styleSingle.rawValue,
            .foregroundColor: UIColor.white.withAlphaComponent(0.8),
            .font: UIFont.systemFont(ofSize: 14)
        ])
        label.textAlignment = .center
        label.isUserInteractionEnabled = true
        label.addGestureRecognizer(UITapGestureRecognizer(target: self, action: action))
        return label
    }

    @objc private func qrScanTapped() {
        let scanner = QRScannerViewController()
        scanner.onScanned = { [weak self] value in
            self?.privatePostingKeyTextField.text = value
        }
        scanner.modalPresentationStyle = .fullScreen
        present(scanner, animated: true)
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

// MARK: - QR scanner (fills the Private Posting Key from a scanned QR code)

final class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    var onScanned: ((String) -> Void)?
    private let session = AVCaptureSession()
    private var preview: AVCaptureVideoPreviewLayer?
    private var didScan = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupOverlay()
    }

    private func setupCamera() {
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else { showUnavailable(); return }
        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        guard session.canAddOutput(output) else { showUnavailable(); return }
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.videoGravity = .resizeAspectFill
        preview.frame = view.layer.bounds
        view.layer.addSublayer(preview)
        self.preview = preview
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in self?.session.startRunning() }
    }

    private func setupOverlay() {
        let close = UIButton(type: .system)
        close.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        close.tintColor = .white
        close.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        close.layer.cornerRadius = 18
        close.translatesAutoresizingMaskIntoConstraints = false
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        view.addSubview(close)

        let prompt = UILabel()
        prompt.text = "Scan your Private Posting Key QR code"
        prompt.textColor = .white
        prompt.textAlignment = .center
        prompt.numberOfLines = 0
        prompt.font = .systemFont(ofSize: 16, weight: .semibold)
        prompt.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(prompt)

        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            close.widthAnchor.constraint(equalToConstant: 36),
            close.heightAnchor.constraint(equalToConstant: 36),
            prompt.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            prompt.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            prompt.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        preview?.frame = view.layer.bounds
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didScan,
              let obj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              obj.type == .qr, let value = obj.stringValue else { return }
        didScan = true
        session.stopRunning()
        dismiss(animated: true) { [weak self] in self?.onScanned?(value) }
    }

    private func showUnavailable() {
        let label = UILabel()
        label.text = "Camera not available"
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func closeTapped() {
        session.stopRunning()
        dismiss(animated: true)
    }
}
//hive.guy
//5JsDjHm59mojuhKEDk3ffDm9NBemmL98SQBzzELbpELs1EnCSy5

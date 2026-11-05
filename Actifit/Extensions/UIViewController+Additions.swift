//
//  UIViewController+Additions.swift
//  Actifit
//
//  Created by Hitender kumar on 15/08/18.
//  Copyright © 2018 actifit.io. All rights reserved.
//

import Foundation
import UIKit

typealias OkClickedCompletion = ((_ finished : Bool) -> ())?
typealias CancelClickedCompletion = ((_ finished : Bool) -> ())?
typealias CameraClickedCompletion = ((_ finished : Bool) -> ())?
typealias ChoosePhotoClickedCompletion = ((_ finished : Bool) -> ())?

extension UIViewController {
    
    //MARK: Show/Hide Keyboard
    
    func autoHideKeybordOnTappingAnyWhere() {
        
        let tap = UITapGestureRecognizer.init(target: self, action: #selector(dismissKeyboard))
        tap.delegate = self as? UIGestureRecognizerDelegate
        tap.numberOfTapsRequired = 1
        self.view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    //MARK: Alerts
    
    func showAlertWith(title : String?, message : String?) {
        
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.default) { (alertAction) in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        okAction.setValue(UIColor.black, forKey: "titleTextColor")
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWithOkCompletion(title : String?, message : String?, okClickedCompletion : OkClickedCompletion) {
        
        let alertController = UIAlertController.init(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction.init(title: "Ok", style: UIAlertActionStyle.default) { (alertAction) in
            alertController.dismiss(animated: true, completion: nil)
            if okClickedCompletion != nil{
                okClickedCompletion!(true)
            }
        }
        
        okAction.setValue(UIColor.black, forKey: "titleTextColor")
        
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWith(title : String?, message : String?, okActionTitle : String?, cancelActionTitle : String?, okClickedCompletion : OkClickedCompletion,  cancelClickedCompletion : CancelClickedCompletion) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction.init(title: okActionTitle, style: UIAlertActionStyle.default, handler: { (okAlert) in
            if okClickedCompletion != nil{
                okClickedCompletion!(true)
            }
        })
        
        okAction.setValue(UIColor.black, forKey: "titleTextColor")
        
        alertController.addAction(okAction)
        
        let cancelAction = UIAlertAction.init(title: cancelActionTitle, style: UIAlertActionStyle.default, handler: { (okAlert) in
            if cancelClickedCompletion != nil{
                cancelClickedCompletion!(true)
            }
        })
        
        cancelAction.setValue(UIColor.black, forKey: "titleTextColor")

        if cancelActionTitle != nil {
            alertController.addAction(cancelAction)
        }
        
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    func showActionSheetForPhotosAccessWith(sourceRect : CGRect, showDeleteButton : Bool, title : String?, message : String?, cancelActionTitle : String?,  cameraClickedCompletion : ((_ finished : Bool) -> ())?, deletePhotoCompletion : ((_ finished : Bool) -> ())?, choosePhotoClickedCompletion : ((_ finished : Bool) -> ())?,  cancelClickedCompletion : ((_ finished : Bool) -> ())?) -> UIAlertController? {
        
        let actionSheetController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
        
        //titleTextColor
        
        if showDeleteButton {
            let deletePhotoAction = UIAlertAction.init(title: "Delete Photo", style: .default) { (deleteAlertAction) in
                if deletePhotoCompletion != nil{
                    deletePhotoCompletion!(true)
                }
            }
            deletePhotoAction.setValue(UIColor.black, forKey: "titleTextColor")
            actionSheetController.addAction(deletePhotoAction)
        }
        
        let takePhotoAction = UIAlertAction.init(title: "Take Photo", style: .default) { (takePhotoAlertAction) in
            if cameraClickedCompletion != nil{
                cameraClickedCompletion!(true)
            }
        }
        takePhotoAction.setValue(UIColor.black, forKey: "titleTextColor")
        
        let choosePhotoAction = UIAlertAction.init(title: "Choose Photo", style: .default) { (choosePhotoAlertAction) in
            if choosePhotoClickedCompletion != nil{
                choosePhotoClickedCompletion!(true)
            }
        }
        choosePhotoAction.setValue(UIColor.black, forKey: "titleTextColor")
        
        let cancelAction = UIAlertAction.init(title: cancelActionTitle, style: .cancel) { (cancelAlertAction) in
            if cancelClickedCompletion != nil{
                cancelClickedCompletion!(true)
            }
        }
        cancelAction.setValue(UIColor.primaryRedColor, forKey: "titleTextColor")
        
        actionSheetController.addAction(takePhotoAction)
        actionSheetController.addAction(choosePhotoAction)
        actionSheetController.addAction(cancelAction)
        
        DispatchQueue.main.async {
            if IsPad {
                actionSheetController.popoverPresentationController?.sourceView = self.view
                actionSheetController.popoverPresentationController?.sourceRect = sourceRect
            }
            self.present(actionSheetController, animated: true, completion: nil)
        }
        return actionSheetController
    }
   // extension UIViewController{

   
}


import UIKit

extension UIViewController {
    func showProgressIndicator() {
      let progressView = UIActivityIndicatorView(activityIndicatorStyle: .large)
        progressView.color = .gray
        progressView.startAnimating()

        let containerView = UIView(frame: view.bounds)
        containerView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        containerView.addSubview(progressView)
        progressView.center = containerView.center
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideProgressIndicator))
             containerView.addGestureRecognizer(tapGestureRecognizer)


        view.addSubview(containerView)
    }

  @objc func hideProgressIndicator() {
        if let containerView = view.subviews.first(where: { $0.backgroundColor?.cgColor.alpha == 0.3 }) {
            containerView.removeFromSuperview()
        }
    }


  func showSyncOptionsAlert(
     fitbitHandler: @escaping () -> Void,
     watchHandler: @escaping () -> Void,
     dismissHandler: (() -> Void)? = nil,
     completion: (() -> Void)? = nil
   ) {
     let alert = UIAlertController(title: "Sync your data from", message: "Please Select an Option", preferredStyle: .actionSheet)

     alert.addAction(UIAlertAction(title: "Fitbit", style: .default, handler: { _ in
       print("User clicked Fitbit button")
       fitbitHandler()
     }))

     alert.addAction(UIAlertAction(title: "Watch/Health App", style: .default, handler: { _ in
       print("User clicked Watch button")
       watchHandler()
     }))

     alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { _ in
       print("User clicked Dismiss button")
       dismissHandler?()
     }))

     self.present(alert, animated: true, completion: {
       print("Completion block")
       completion?()
     })
   }
}


// MARK: - Fitbit retired

/// Google turned off the legacy Fitbit Web API (Oct 30 2026), so the in-app Fitbit login can no
/// longer work. The Google Health (Fitbit) app syncs Fitbit data into Apple Health (v5.05+), so we
/// point Fitbit users there instead of starting the dead login.
enum FitbitRetired {
  static let title = "Get your Fitbit steps through Apple Health"
  static let message = """
    Actifit can no longer connect to Fitbit directly, but your Fitbit steps can still reach Actifit through Apple Health. It takes about a minute:

    1. Update the Google Health app (the new name of the Fitbit app).
    2. In Google Health, tap Connections → Apps and services → Apple Health, and turn on Steps.
    3. Come back here, tap Use Apple Health, and allow Steps.

    New steps can take a few minutes to appear. Open Google Health first to sync your Fitbit.
    """
  static let useAppleHealth = "Use Apple Health"
  static let showMeHow = "Show me how"
  static let helpTitle = "Fitbit setup help"
  static let helpMessage = """
    Can't find Connections or Apple Health?
    Update Google Health from the App Store. Apple Health sync needs version 5.05 or newer.

    Steps not showing in Actifit?
    Open the iPhone Health app → Sharing → Apps → Actifit and turn on Steps. Check Google Health there too, and allow it to write Steps.

    Steps counted twice?
    In the Health app, open Steps → Data Sources & Access → Edit, and drag Google Health to the top.

    Open Google Health now and then so your Fitbit keeps syncing.
    """

  /// show the dashboard reminder once per app launch
  static var shownThisLaunch = false
}

extension UIViewController {
  /// - Parameter onUseAppleHealth: switches to Apple Health.
  /// - Returns: false when the alert could not be presented right now.
  @discardableResult
  func showFitbitRetiredAlert(onUseAppleHealth: @escaping () -> Void) -> Bool {
    // UIKit drops a present() made while another controller is showing or before the view is on screen
    guard view.window != nil, presentedViewController == nil else { return false }
    let alert = UIAlertController(title: FitbitRetired.title, message: FitbitRetired.message,
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: FitbitRetired.useAppleHealth, style: .default) { _ in
      onUseAppleHealth()
    })
    alert.addAction(UIAlertAction(title: FitbitRetired.showMeHow, style: .default) { [weak self] _ in
      // wait for this alert to finish closing, or the next present() is dropped
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
        self?.showFitbitHelpAlert(onUseAppleHealth: onUseAppleHealth)
      }
    })
    alert.addAction(UIAlertAction(title: "Later", style: .cancel))
    present(alert, animated: true)
    return true
  }

  private func showFitbitHelpAlert(onUseAppleHealth: @escaping () -> Void) {
    guard view.window != nil, presentedViewController == nil else { return }
    let alert = UIAlertController(title: FitbitRetired.helpTitle, message: FitbitRetired.helpMessage,
                                  preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: FitbitRetired.useAppleHealth, style: .default) { _ in
      onUseAppleHealth()
    })
    alert.addAction(UIAlertAction(title: "Close", style: .cancel))
    present(alert, animated: true)
  }
}

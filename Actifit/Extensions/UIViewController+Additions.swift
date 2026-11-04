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
  static let title = "Fitbit now syncs through Apple Health"
  static let message = """
    Google retired Fitbit's old connection for partner apps like Actifit on October 30, 2026.

    To keep earning from your Fitbit steps:
    1. In the Google Health (Fitbit) app, open Connections → Apps and services and add Apple Health.
    2. In Actifit, use Apple Health as your tracking source.
    """
  static let useAppleHealth = "Use Apple Health"

  /// show the dashboard reminder once per app launch
  static var shownThisLaunch = false
}

extension UIViewController {
  /// - Parameter onUseAppleHealth: switches to Apple Health; nil when no switch is needed
  ///   (then the alert only has OK).
  /// - Returns: false when the alert could not be presented right now.
  @discardableResult
  func showFitbitRetiredAlert(onUseAppleHealth: (() -> Void)? = nil) -> Bool {
    // UIKit drops a present() made while another controller is showing or before the view is on screen
    guard view.window != nil, presentedViewController == nil else { return false }
    let alert = UIAlertController(title: FitbitRetired.title, message: FitbitRetired.message,
                                  preferredStyle: .alert)
    if let onUseAppleHealth = onUseAppleHealth {
      alert.addAction(UIAlertAction(title: FitbitRetired.useAppleHealth, style: .default) { _ in
        onUseAppleHealth()
      })
      alert.addAction(UIAlertAction(title: "Later", style: .cancel))
    } else {
      alert.addAction(UIAlertAction(title: "OK", style: .cancel))
    }
    present(alert, animated: true)
    return true
  }
}

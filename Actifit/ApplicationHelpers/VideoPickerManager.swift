//
//  VideoPickerManager.swift
//  Actifit
//
//  Created by Ali Jaber on 09/05/2024.
//

import Foundation
import UIKit
import MobileCoreServices
import TUSKit
import UniformTypeIdentifiers
protocol VideoPickerDelegate: AnyObject {
    func didSelect(videoUrl: URL)
    func didCancel()
}

class VideoPickerManager: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    weak var delegate: VideoPickerDelegate?

    func presentVideoPicker(in viewController: UIViewController) {
      showVideoLibrary(in: viewController)
    }

     func showVideoLibrary(in viewController: UIViewController) {
      
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.delegate = self
        picker.videoQuality = .typeMedium
        picker.videoMaximumDuration = TimeInterval(30)

        viewController.present(picker, animated: true)
    }

     func recordVideo(in viewController: UIViewController) {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera is not available")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.mediaTypes = [kUTTypeMovie as String]
        picker.delegate = self
        picker.videoQuality = .typeMedium

        viewController.present(picker, animated: true)
    }

    // MARK: - UIImagePickerControllerDelegate

  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    if let videoURL = info[UIImagePickerControllerMediaURL] as? URL {
                 print("Here is the URL: \(videoURL)")
            delegate?.didSelect(videoUrl: videoURL)
            picker.dismiss(animated: true)
             }
    //
  }


    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        delegate?.didCancel()
        picker.dismiss(animated: true)
    }
}

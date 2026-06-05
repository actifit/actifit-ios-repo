//
//  ImagePicker.swift
//  Actifit
//
//  Created by Ali Jaber on 21/04/2024.
//

import Foundation
import UIKit

protocol ImagePickerDelegate: AnyObject {
    func didSelect(image: UIImage?)
}

class ImagePicker: NSObject {

    weak var presentationController: UIViewController?
    weak var delegate: ImagePickerDelegate?

    init(presentationController: UIViewController) {
        super.init()
        self.presentationController = presentationController
    }

    func present() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let takePhotoAction = UIAlertAction(title: "Camera", style: .default) { _ in
            self.presentImagePicker(sourceType: .camera)
        }
        alertController.addAction(takePhotoAction)

        let choosePhotoAction = UIAlertAction(title: "Choose from Photos", style: .default) { _ in
            self.presentImagePicker(sourceType: .photoLibrary)
        }
        alertController.addAction(choosePhotoAction)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        presentationController?.present(alertController, animated: true, completion: nil)
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = sourceType
        presentationController?.present(picker, animated: true, completion: nil)
    }
}

extension ImagePicker: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
     if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
       delegate?.didSelect(image: image)
     }

    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

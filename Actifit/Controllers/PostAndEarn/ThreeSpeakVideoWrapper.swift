//
//  ThreeSpeakVideoWrapper.swift
//  Actifit
//
//  Created by Ali Jaber on 19/07/2024.
//

import SwiftUI
import UIKit

struct ThreeSpeakVideoView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var video: Video? // Replace `Video` with your actual video object type

    func makeUIViewController(context: Context) -> UIViewController {
      let viewController = ThreeSpeakVideoViewController.create(hideAddPostBtn: false)
        viewController.delegate = context.coordinator
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if !isPresented {
            uiViewController.dismiss(animated: true, completion: nil)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, ThreeSpeakVideoViewControllerDelegate {
        var parent: ThreeSpeakVideoView

        init(_ parent: ThreeSpeakVideoView) {
            self.parent = parent
        }

        func videoViewController(_ controller: ThreeSpeakVideoViewController, didPickVideo video: Video) {
            parent.video = video
            parent.isPresented = false
        }

        func videoViewControllerDidCancel(_ controller: ThreeSpeakVideoViewController) {
            parent.isPresented = false
        }
    }
}

protocol ThreeSpeakVideoViewControllerDelegate: AnyObject {
    func videoViewController(_ controller: ThreeSpeakVideoViewController, didPickVideo video: Video)
    func videoViewControllerDidCancel(_ controller: ThreeSpeakVideoViewController)
}


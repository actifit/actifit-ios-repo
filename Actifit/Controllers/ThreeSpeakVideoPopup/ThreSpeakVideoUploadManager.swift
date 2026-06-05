//
//  ThreSpeakVideoUploadManager.swift
//  Actifit
//
//  Created by Ali Jaber on 15/05/2024.
//

import Foundation
import AVFoundation
import UIKit
import TUSKit
import Combine
final class ThreeSpeakVideoUploadManager {
  private var hasSentImageURL = false
  private var hasSentVideoURL = false
  var imageProgressSubject = CurrentValueSubject<Double, Never>(0)
  var videoProgressSubject = CurrentValueSubject<Double, Never>(0)
  var uploadedVideoURLSubject = CurrentValueSubject<URL?, Never>(nil)
  var uploadedImageURLSubject = CurrentValueSubject<URL?, Never>(nil)
  var tusClient: TUSClient?
  var uploadType: UploadType? = nil
  init() {
    setupTUSClient()
  }

  deinit {
       // Perform cleanup
       tusClient?.stopAndCancelAll()
       print("ThreeSpeakVideoUploadManager deinitialized")
   }

  private func setupTUSClient() {
    let endpoint = URL(string: "https://uploads.3speak.tv/files")!
    let sessionIdentifier = "3speaker"

    do {//.background(withIdentifier: sessionIdentifier)
      tusClient = try TUSClient(server: endpoint, sessionIdentifier: sessionIdentifier, sessionConfiguration: .default , chunkSize: 100*1024 )//
      tusClient?.delegate = self

    } catch {
      print("Failed to initialize TUSClient: \(error.localizedDescription)")
    }
  }
  func generateThumbnail(from videoURL: URL) -> UIImage? {// gets an image for the video
    do {
      let asset = AVAsset(url: videoURL)
      let imageGenerator = AVAssetImageGenerator(asset: asset)
      imageGenerator.appliesPreferredTrackTransform = true
      let thumbnailTime = CMTime(seconds: asset.duration.seconds / 4, preferredTimescale: 60)
      let cgImage = try imageGenerator.copyCGImage(at: thumbnailTime, actualTime: nil)
      return UIImage(cgImage: cgImage)
    } catch {
      print("Error generating thumbnail: \(error)")
      return nil
    }
  }

  func getFinalVideoName(from filePath: URL) -> String? {
    return filePath.lastPathComponent
  }

  func getVidSize(for videoURL: URL) -> Double? {
      do {
          // Get the file attributes for the video file
          let attributes = try FileManager.default.attributesOfItem(atPath: videoURL.path)

          // Extract the file size from the attributes
          if let fileSize = attributes[.size] as? Int64 {
              // Convert the file size to megabytes
              let fileSizeInMB = Double(fileSize) / 1_048_576
              return fileSizeInMB
          } else {
              print("File size attribute not found")
              return nil
          }
      } catch {
          print("Error getting file attributes: \(error)")
          return nil
      }
  }

  func getVidDuration(for videoURL: URL) -> Double? {
        let asset = AVAsset(url: videoURL)
        let duration = asset.duration


      return CMTimeGetSeconds(duration)
    }

  func getBitmapFileUrl(from image: UIImage) throws -> URL {
   
    let tempDirectory = FileManager.default.temporaryDirectory
    let fileUrl = tempDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg")
    guard let imageData = UIImageJPEGRepresentation(image, 1.0) else {
      throw NSError(domain: "Error converting image to JPEG", code: 1, userInfo: nil)
    }
    try imageData.write(to: fileUrl)
    return fileUrl
  }

  func uploadVideoOrImage(videoURL: URL, uploadType: UploadType) {
    let url = videoURL
      self.uploadType = uploadType
    if uploadType == .image {
      hasSentImageURL = false
    } else {
      hasSentVideoURL = false
    }
      guard let tusClient = tusClient else {
          print("TUSClient is not initialized")

          return
      }
      do {
          tusClient.start()
          try tusClient.uploadFileAt(filePath: videoURL)

      } catch let error {
          print("Upload failed to start: \(error.localizedDescription)")
      }
  }
}

extension ThreeSpeakVideoUploadManager: TUSClientDelegate {
  func progressFor(id: UUID, context: [String : String]?, bytesUploaded: Int, totalBytes: Int, client: TUSKit.TUSClient) {
    print(bytesUploaded)
    print(totalBytes)

  }

  func didStartUpload(id: UUID, context: [String : String]?, client: TUSKit.TUSClient) {
    print("TUSClient started upload, id is \(id)")
    print("TUSClient remaining is \(client.remainingUploads)")
  }

  func didFinishUpload(id: UUID, url: URL, context: [String : String]?, client: TUSKit.TUSClient) {
    //TODO: return URL
    print("TUSClient finished upload, id is \(id) url is \(url)")
    print("TUSClient remaining is \(client.remainingUploads)")
    if client.remainingUploads == 0 {
      print("Finished uploading")
      if uploadType == .image {
        if !hasSentImageURL {
          uploadedImageURLSubject.send(url)
          imageProgressSubject.send(100)
          hasSentImageURL = true
        }
      } else {
        if !hasSentVideoURL {
          uploadedVideoURLSubject.send(url)
          videoProgressSubject.send(100)
          hasSentVideoURL = true
        }
      }
    }
  }

  func uploadFailed(id: UUID, error: any Error, context: [String : String]?, client: TUSKit.TUSClient) {
    print("TUSClient upload failed for \(id) error \(error)")
    //TODO: try again
  }


  func fileError(error: TUSClientError, client: TUSClient) {
    print("TUSClient File error \(error)")
  }

  func totalProgress(bytesUploaded: Int, totalBytes: Int, client: TUSClient) {
    sendTotalPercentageLeft(bytesUploaded: bytesUploaded, totalBytes: totalBytes)
  }

  func sendTotalPercentageLeft(bytesUploaded: Int, totalBytes: Int) {
    guard totalBytes > 0 else {
      print("Total bytes must be greater than zero.")
      return
    }

    let progress = (Double(bytesUploaded) / Double(totalBytes)) * 100
    if uploadType == .image {
      if !hasSentImageURL {
        imageProgressSubject.send(progress)
      }
    } else {
      if !hasSentVideoURL {
        videoProgressSubject.send(progress)
      }
    }

  }

}
enum UploadType {
  case image
  case video
}

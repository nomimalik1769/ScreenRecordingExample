//
//  ViewController.swift
//  ScreenRecordingExample
//
//  Created by MNouman on 28/03/2024.
//

import UIKit
import AVFoundation
import AVKit
import PhotosUI
import ReplayKit

class ViewController: UIViewController {

    @IBOutlet weak var containerView : UIView!
    var systemBroadcastPicker :RPSystemBroadcastPickerView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        systemBroadcastPicker = RPSystemBroadcastPickerView(frame: .init(x: 0, y: 0, width: 50, height: 50))
        containerView.addSubview(systemBroadcastPicker)
        systemBroadcastPicker.autoresizingMask = [.flexibleTopMargin, .flexibleRightMargin]
        systemBroadcastPicker.showsMicrophoneButton = false
        systemBroadcastPicker.preferredExtension = "com.app.ScreenRecordingExample.ScreenRecordingExampleExtension"
        NotificationCenter.default.addObserver(forName: NSNotification.Name("broadCaststop"), object: nil, queue: .main) { noti in
            self.read()
        }
        
    }
    
    @IBAction func onRecordAction(_ sender:UIButton){
        
        self.read()
    
    }
    private func read() {
        let fileManager = FileManager.default
        var mediaURLs: [URL] = []
        if let container = fileManager
                .containerURL(
                    forSecurityApplicationGroupIdentifier: "group.screenrecordtest"
                )?.appendingPathComponent("Library/Documents/") {

            let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
            do {
                let contents = try fileManager.contentsOfDirectory(atPath: container.path)
                for path in contents {
                    guard !path.hasSuffix(".plist") else {
                        print("file at path \(path) is plist, exiting")
                        return
                    }
                    let fileURL = container.appendingPathComponent(path)
                    var isDirectory: ObjCBool = false
                    guard fileManager.fileExists(atPath: fileURL.path, isDirectory: &isDirectory) else {
                        return
                    }
                    guard !isDirectory.boolValue else {
                        return
                    }
                    let destinationURL = documentsDirectory.appendingPathComponent(path)
                    do {
                        try fileManager.copyItem(at: fileURL, to: destinationURL)
                        print("Successfully copied \(fileURL)", "to: ", destinationURL)
                    } catch {
                        print("error copying \(fileURL) to \(destinationURL)", error)
                    }
                    mediaURLs.append(destinationURL)
                }
            } catch {
                print("contents, \(error)")
            }
        }
        if mediaURLs.count > 0{
            if let firstUrl = mediaURLs.first{
                saveVideoToAlbum(firstUrl) { error in
                    if let error{
                        print("Error Saving Video: ",error)
                    }
                    self.removeAllVideos(path: firstUrl.path(percentEncoded: false))
                }
            }
        }

    }
    private func removeAllVideos(path:String){
        do{
            if let container =  FileManager.default.containerURL(
                forSecurityApplicationGroupIdentifier: "group.screenrecordtest"
            )?.appendingPathComponent("Library/Documents/"){
                try FileManager.default.removeItem(at: container)
            }
            if FileManager.default.fileExists(atPath: path){
                try FileManager.default.removeItem(atPath: path)
            }else{
                print("File not exist at path: ",path)
            }
            
        } catch let error {
            print("Removing error: ",error)
        }
    }
    func requestAuthorization(completion: @escaping ()->Void) {
            if PHPhotoLibrary.authorizationStatus() == .notDetermined {
                PHPhotoLibrary.requestAuthorization { (status) in
                    DispatchQueue.main.async {
                        completion()
                    }
                }
            } else if PHPhotoLibrary.authorizationStatus() == .authorized{
                completion()
            }
        }



    func saveVideoToAlbum(_ outputURL: URL, _ completion: ((Error?) -> Void)?) {
            requestAuthorization {
                PHPhotoLibrary.shared().performChanges({
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .video, fileURL: outputURL, options: nil)
                }) { (result, error) in
                    DispatchQueue.main.async {
                        if let error = error {
                            print(error.localizedDescription)
                        } else {
                            print("Saved successfully")
                        }
                        completion?(error)
                    }
                }
            }
        }
}


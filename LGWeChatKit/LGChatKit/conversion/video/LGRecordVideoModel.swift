//
//  LGRecordVideo.swift
//  record
//
//  Created by jamy on 11/6/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import Foundation
import AVFoundation
import Photos
import UIKit


private let needSaveToPHlibrary = false

class LGRecordVideoModel: NSObject, AVCaptureFileOutputRecordingDelegate {
    
    var captureSession: AVCaptureSession!
    var captureDeviceInput: AVCaptureDeviceInput!
    var captureMovieFileOutput: AVCaptureMovieFileOutput!
    var backgroundTaskIdentifier: UIBackgroundTaskIdentifier!
    
    var filePath: NSURL?
    var fileName: String!
    
    var complectionClosure: ((NSURL) -> Void)?
    var cancelClosure: (() -> Void)?
    
    override init() {
        super.init()
        captureSession = AVCaptureSession()
        let captureDevice = getCameraDevice(position: .back)
        if captureDevice == nil {
            return
        }
        let audioCaptureDevice = AVCaptureDevice.devices(for: AVMediaType.audio).first as! AVCaptureDevice
        
        var audioCaptureDeviceInput: AVCaptureDeviceInput?
        do {
            try audioCaptureDeviceInput = AVCaptureDeviceInput(device: audioCaptureDevice)
        } catch let error as NSError {
            NSLog("%@", error)
            return
        }
        
        do {
            try captureDeviceInput = AVCaptureDeviceInput(device: captureDevice!)
        } catch let error as NSError {
            NSLog("%@", error)
            return
        }
        
        captureSession.beginConfiguration()
        captureMovieFileOutput = AVCaptureMovieFileOutput()
        
        if captureSession.canAddInput(captureDeviceInput) {
            captureSession.addInput(captureDeviceInput)
            captureSession.addInput(audioCaptureDeviceInput!)
        }
        
        if captureSession.canAddOutput(captureMovieFileOutput) {
            captureSession.addOutput(captureMovieFileOutput)
            let connection = captureMovieFileOutput.connection(with: AVMediaType.video)
            if (connection?.isVideoStabilizationSupported ?? false) {
                connection!.preferredVideoStabilizationMode = .auto
            }
        }
        captureSession.commitConfiguration()
        
        addNotificationToDevice(newCaptureDevice: captureDevice!)
    }
 
    deinit {
        captureSession.removeInput(captureDeviceInput)
        captureSession.removeInput(captureDeviceInput)
        captureSession.removeOutput(captureMovieFileOutput)
        removeNotification()
    }
    
    func getCameraDevice(position: AVCaptureDevice.Position) -> (AVCaptureDevice?) {
        let devices = AVCaptureDevice.devices(for: AVMediaType.video)
        for device in devices {
            let device = device as! AVCaptureDevice
            if device.position == position {
                return device
            }
        }
        return nil
    }
    
    func start() {
        captureSession.startRunning()
    }
    
    func stop() {
        captureSession.stopRunning()
    }
    
    func addNotificationToDevice(newCaptureDevice: AVCaptureDevice) {
        let captureDevice = captureDeviceInput.device
        do {
            try captureDevice.lockForConfiguration()
        } catch let error as NSError {
            NSLog("%@", error)
            return
        }
        captureDevice.isSubjectAreaChangeMonitoringEnabled = true
        captureDevice.unlockForConfiguration()
        
        NotificationCenter.default.addObserver(self, selector: Selector("notificateAreChanged:"), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: newCaptureDevice)
        
        NotificationCenter.default.addObserver(self, selector: "notificateSessionError:", name: NSNotification.Name.AVCaptureSessionRuntimeError, object: captureSession)
        NotificationCenter.default.addObserver(self, selector: "sessionWasInterrupted:", name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: captureSession)
        NotificationCenter.default.addObserver(self, selector: "sessionInterruptEnd:", name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: captureSession)
    }
    
    func removeNotificationFromDevice(oldCaptureDevice: AVCaptureDevice) {
        NotificationCenter.default.removeObserver(oldCaptureDevice)
    }
    
    func removeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
    
    func notificateAreChanged(notification: NSNotification) {
        
    }
    
    func sessionWasInterrupted(notification: NSNotification) {
        NSLog("------sessionWasInterrupted---------")
    }
    
    func sessionInterruptEnd(notification: NSNotification) {
         NSLog("------sessionInterruptEnd---------")
    }
    
    func notificateSessionError(notification: NSNotification) {
        NSLog("notificateSessionError")
    }
    
    func beginRecord() {
        if !captureMovieFileOutput.isRecording {
            if UIDevice.current.isMultitaskingSupported {
                backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(expirationHandler: nil)
            }
            
            var fileName = String(arc4random_uniform(1000))
            fileName = fileName + ".m4v"
            let filePath = NSString(string: NSTemporaryDirectory()).appendingPathComponent(fileName)
            let fileUrl = NSURL(fileURLWithPath: filePath)
            
            self.fileName = fileName
            self.filePath = fileUrl
            
            captureMovieFileOutput.startRecording(to: fileUrl as URL, recordingDelegate: self)
        } else {
            captureMovieFileOutput.stopRecording()
        }
    }
    
    func complectionRecord() {
        if captureMovieFileOutput.isRecording {
            captureMovieFileOutput.stopRecording()
        }
    }
    
    func cancelRecord() {
        if captureMovieFileOutput.isRecording {
            captureMovieFileOutput.stopRecording()
        }
        if filePath != nil {
            do {
                try FileManager.default.removeItem(at: filePath! as URL)
            } catch let error as NSError {
                NSLog("remove file error: %@", error)
            }
        }
        
        if let cancelOperation = cancelClosure {
            cancelOperation()
        }
    }
    
    func changeCameraPosition() {
        let currentDevice = captureDeviceInput.device
        let currentPosition = currentDevice.position
        removeNotificationFromDevice(oldCaptureDevice: currentDevice)
        
        var changePosition: AVCaptureDevice.Position = .front
        if currentPosition == .unspecified || currentPosition == .front {
            changePosition = .back
        }
        
        if let changeDevice = getCameraDevice(position: changePosition) {
            addNotificationToDevice(newCaptureDevice: changeDevice)
            var changeDeviceInput: AVCaptureDeviceInput!
            do {
                changeDeviceInput = try AVCaptureDeviceInput(device: changeDevice)
            } catch let error as NSError {
                NSLog("changeCamera: %@", error)
                return
            }
            
            captureSession.beginConfiguration()
            captureSession.removeInput(captureDeviceInput)
            if captureSession.canAddInput(changeDeviceInput) {
                captureSession.addInput(changeDeviceInput)
                captureDeviceInput = changeDeviceInput
            }
            captureSession.commitConfiguration()
        }
    }
    
    func setFlashMode(flashMode: AVCaptureDevice.FlashMode) {
        let captureDevice = captureDeviceInput.device
        do {
            try captureDevice.lockForConfiguration()
        } catch let error as NSError {
            NSLog("%@", error)
            return
        }
        if captureDevice.isFlashModeSupported(flashMode) {
            captureDevice.flashMode = flashMode
        }
        captureDevice.unlockForConfiguration()
    }
    
    
    func setFocusMode(focusMode: AVCaptureDevice.FocusMode) {
        let captureDevice = captureDeviceInput.device
        do {
            try captureDevice.lockForConfiguration()
        } catch let error as NSError {
            NSLog("%@", error)
            return
        }
        if captureDevice.isFocusModeSupported(focusMode) {
            captureDevice.focusMode = focusMode
        }
        captureDevice.unlockForConfiguration()
    }
    
    func setFocusExposureMode(focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, point: CGPoint) {
        let captureDevice = captureDeviceInput.device
        do {
            try captureDevice.lockForConfiguration()
        } catch let error as NSError {
            NSLog("%@", error)
            return
        }
        
        if captureDevice.isFocusModeSupported(focusMode) {
            captureDevice.focusMode = focusMode
        }
        if captureDevice.isFocusPointOfInterestSupported {
            captureDevice.focusPointOfInterest = point
        }
        
        if captureDevice.isExposureModeSupported(exposureMode) {
            captureDevice.exposureMode = exposureMode
        }
        if captureDevice.isExposurePointOfInterestSupported {
            captureDevice.exposurePointOfInterest = point
        }
        
        captureDevice.unlockForConfiguration()
    }
 
    // MARK: delegate
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        NSLog("begin record")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        
        NSLog("record finish")
        if error == nil {
            
            let lastBackgroundTaskIdentifier = backgroundTaskIdentifier
            self.backgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
            if let complection = complectionClosure {
                complection(filePath!)
            }
            
            if needSaveToPHlibrary {
                PHPhotoLibrary.shared().performChanges({ () -> Void in
                    PHAssetCreationRequest.forAsset().addResource(with: .video, fileURL: outputFileURL as URL, options: nil)
                    }) { (finish, errors) -> Void in
                        if errors == nil {
                            NSLog("保存成功")
                        } else {
                            print("保存失败：%@", errors!)
                        }
                        if lastBackgroundTaskIdentifier != UIBackgroundTaskIdentifier.invalid {
                            UIApplication.shared.endBackgroundTask(lastBackgroundTaskIdentifier!)
                        }
                }
            }
        } else {
            print("record error:%@", error)
        }
    }
    
}

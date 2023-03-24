//
//  LGAudioRecorder.swift
//  LGChatViewController
//
//  Created by jamy on 10/13/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import UIKit
import AVFoundation

protocol LGAudioRecorderDelegate {
    func audioRecorderUpdateMetra(metra: Float)
}


let soundPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!

let audioSettings: [String: AnyObject] = [AVLinearPCMIsFloatKey: NSNumber(value: false),
                                      AVLinearPCMIsBigEndianKey: NSNumber(value: false),
                                         AVLinearPCMBitDepthKey: NSNumber(value: 16),
                                                  AVFormatIDKey: NSNumber(value: kAudioFormatLinearPCM),
                                          AVNumberOfChannelsKey: NSNumber(value: 1), AVSampleRateKey: NSNumber(value: 16000),
                                       AVEncoderAudioQualityKey: NSNumber(value: AVAudioQuality.medium.rawValue)]


class LGAudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    var audioData: NSData!
    var operationQueue: OperationQueue!
    var recorder: AVAudioRecorder!
    
    var startTime: Double!
    var endTimer: Double!
    var timeInterval: NSNumber!
    
    var delegate: LGAudioRecorderDelegate?
    
    convenience init(fileName: String) {
        self.init()
        
        let filePath = NSURL(fileURLWithPath: (soundPath as NSString).appendingPathComponent(fileName))
        
        recorder = try! AVAudioRecorder(url: filePath as URL, settings: audioSettings)
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        
    }
    
    override init() {
        operationQueue = OperationQueue()
        super.init()
    }
    
    func startRecord() {
        startTime = NSDate().timeIntervalSince1970
        perform("readyStartRecord", with: self, afterDelay: 0.5)
    }
    
    func readyStartRecord() {
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSession.Category.record)
        } catch {
            NSLog("setCategory fail")
            return
        }
        
        do {
            try audioSession.setActive(true)
        } catch {
            NSLog("setActive fail")
            return
        }
        recorder.record()
        let operation = BlockOperation()
        operation.addExecutionBlock(updateMeters)
        operationQueue.addOperation(operation)
    }
    
    
    func stopRecord() {
        endTimer = NSDate().timeIntervalSince1970
        timeInterval = nil
        if (endTimer - startTime) < 0.5 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: "readyStartRecord", object: self)
        } else {
            timeInterval = NSNumber(value: Int32(NSNumber(value: recorder.currentTime).intValue))
            if timeInterval.intValue < 1 {
                perform("readyStopRecord", with: self, afterDelay: 0.4)
            } else {
                readyStopRecord()
            }
        }
        operationQueue.cancelAllOperations()
    }
    
    
    func readyStopRecord() {
        recorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            // no-op
        }
        audioData = NSData(contentsOf: recorder.url)
    }
    
    func updateMeters() {
        repeat {
            recorder.updateMeters()
            timeInterval = NSNumber(value: NSNumber(value: recorder.currentTime).floatValue)
            let averagePower = recorder.averagePower(forChannel: 0)
           // let pearPower = recorder.peakPowerForChannel(0)
          //  NSLog("%@   %f  %f", timeInterval, averagePower, pearPower)
            delegate?.audioRecorderUpdateMetra(metra: averagePower)
            Thread.sleep(forTimeInterval: 0.2)
        } while(recorder.isRecording)
    }
    
    // MARK: audio delegate
    func audioRecorderEncodeErrorDidOccur(recorder: AVAudioRecorder, error: NSError?) {
        NSLog("%@", (error?.localizedDescription)!)
    }
}

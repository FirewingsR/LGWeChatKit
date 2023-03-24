//
//  LGRecordView.swift
//  record
//
//  Created by jamy on 11/6/15.
//  Copyright © 2015 jamy. All rights reserved.
//  该模块未使用autolayout

import UIKit
import AVFoundation


private let buttonW: CGFloat = 60
class LGRecordVideoView: UIView {
    
    var videoView: UIView!
    var indicatorView: UILabel!
    var recordButton: UIButton!
    var progressView: UIProgressView!
    var progressView2: UIProgressView!
    var recordVideoModel: LGRecordVideoModel!
    var preViewLayer: AVCaptureVideoPreviewLayer!
    
    var recordTimer: Timer!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customInit()
    }
    
    func customInit() {
        backgroundColor = UIColor.black
        
        if TARGET_IPHONE_SIMULATOR == 1 {
            NSLog("simulator can't do this!!!")
        } else {
            recordVideoModel = LGRecordVideoModel()
            
            videoView = UIView(frame: CGRectMake(0, 0, bounds.width, bounds.height * 0.7))
            videoView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            addSubview(videoView)
            
            preViewLayer = AVCaptureVideoPreviewLayer(session: recordVideoModel.captureSession)
            preViewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
            preViewLayer.frame = videoView.bounds
            videoView.layer.insertSublayer(preViewLayer, at: 0)
            
            recordButton = UIButton(type: .custom)
            recordButton.setTitleColor(UIColor.orange, for: .normal)
            recordButton.layer.cornerRadius = buttonW / 2
            recordButton.layer.borderWidth = 1.5
            recordButton.layer.borderColor = UIColor.orange.cgColor
            recordButton.setTitle("按住拍", for: .normal)
            recordButton.addTarget(self, action: "buttonTouchDown", for: .touchDown)
            recordButton.addTarget(self, action: "buttonDragOutside", for: .touchDragOutside)
            recordButton.addTarget(self, action: "buttonCancel", for: .touchUpOutside)
            recordButton.addTarget(self, action: "buttonTouchUp", for: .touchUpInside)
            addSubview(recordButton)
            
            progressView = UIProgressView(frame: CGRectZero)
            progressView.progressTintColor = UIColor.black
            progressView.trackTintColor = UIColor.orange
            progressView.isHidden = true
            addSubview(progressView)
            
            progressView2 = UIProgressView(frame: CGRectZero)
            progressView2.progressTintColor = UIColor.black
            progressView2.trackTintColor = UIColor.orange
            progressView2.isHidden = true
            addSubview(progressView2)
            progressView2.transform = CGAffineTransformMakeRotation(CGFloat(Double.pi))
            
            indicatorView = UILabel()
            indicatorView.textColor = UIColor.white
            indicatorView.font = UIFont.systemFont(ofSize: 12.0)
            indicatorView.backgroundColor = UIColor.red
            indicatorView.isHidden = true
            addSubview(indicatorView)
            
            recordButton.bounds = CGRectMake(0, 0, buttonW, buttonW)
            recordButton.center = CGPointMake(center.x, videoView.frame.height + buttonW)
            
            progressView.frame = CGRectMake(0, videoView.frame.height, bounds.width / 2, 2)
            progressView2.frame = CGRectMake(bounds.width / 2 - 1, videoView.frame.height, bounds.width / 2 + 1, 2)
            
            indicatorView.center = CGPointMake(center.x, videoView.frame.height - 20)
            indicatorView.bounds = CGRectMake(0, 0, 50, 20)
        }
    }
    
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if TARGET_IPHONE_SIMULATOR == 0 {
            recordVideoModel.start()
        }
    }
    
    func buttonTouchDown() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.recordButton.transform = CGAffineTransformMakeScale(1.5, 1.5)
            }) { (finish) -> Void in
                self.recordButton.isHidden = true
        }
        
        recordVideoModel.beginRecord()
        stopTimer()
        self.progressView.isHidden = false
        self.progressView2.isHidden = false
        indicatorView.isHidden = false
        indicatorView.text = "上移取消"
        recordTimer = Timer(timeInterval: 1.0, target: self, selector: "recordTimerUpdate", userInfo: nil, repeats: true)
        RunLoop.main.add(recordTimer, forMode: RunLoop.Mode.common)
    }
    
    func buttonDragOutside() {
        indicatorView.isHidden = false
        indicatorView.text = "松手取消"
    }
    
    func buttonCancel() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.recordButton.isHidden = false
            self.recordButton.transform = CGAffineTransformIdentity
            }) { (finish) -> Void in
                self.indicatorView.isHidden = true
                self.progressView.isHidden = true
                self.progressView.progress = 0
                self.progressView2.isHidden = true
                self.progressView2.progress = 0
                self.stopTimer()
        }
        recordVideoModel.cancelRecord()
    }
    
    func buttonTouchUp() {
        UIView.animate(withDuration: 0.2, animations: { () -> Void in
            self.recordButton.isHidden = false
            self.recordButton.transform = CGAffineTransformIdentity
            }) { (finish) -> Void in
                self.indicatorView.isHidden = true
                self.progressView.isHidden = true
                self.progressView.progress = 0
                self.progressView2.isHidden = true
                self.progressView2.progress = 0
                self.stopTimer()
        }
        recordVideoModel.complectionRecord()
    }
    
    func stopTimer() {
        if recordTimer != nil {
            recordTimer.invalidate()
            recordTimer = nil
        }
    }
    
    func recordTimerUpdate() {
        if progressView.progress == 1 {
            buttonTouchUp()
        } else {
            progressView.progress += 0.1
            progressView2.progress += 0.1
        }
    }
}


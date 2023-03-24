//
//  LGVideoController.swift
//  LGWeChatKit
//
//  Created by jamy on 11/4/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import UIKit
import AVFoundation

class LGVideoController: UIViewController {

    var totalTimer: String!
    var playItem: AVPlayerItem!
    var playView: LGAVPlayView!
    var timerObserver: AnyObject?
    
     init() {
        super.init(nibName: nil, bundle: nil)
        playView = LGAVPlayView(frame: view.bounds)
         view.addSubview(playView)
         playView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapView:"))
    }
    
    func tapView(gesture: UITapGestureRecognizer) {
        removeConfigure()
        dismiss(animated: true) { () -> Void in
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    deinit {
        removeConfigure()
    }
    
    func removeConfigure() {
        NotificationCenter.default.removeObserver(self)
        playItem.removeObserver(self, forKeyPath: "status", context: nil)
        if let observer = timerObserver {
            let layer = playView.layer as! AVPlayerLayer
            layer.player?.removeTimeObserver(observer)
        }
        playView.removeFromSuperview()
        playView = nil
    }
    
    // MARK: - 初始化配置
    
    func setPlayUrl(url: NSURL) {
        playItem = AVPlayerItem(url: url as URL)
        configurationItem()
    }
    
    func setPlayAsset(asset: AVAsset) {
        playItem = AVPlayerItem(asset: asset)
        configurationItem()
    }
    
    func configurationItem() {
        let play = AVPlayer(playerItem: playItem)
        let layer = playView.layer as! AVPlayerLayer
        layer.player = play
        
        playItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        NotificationCenter.default.addObserver(self, selector: "videoPlayDidEnd:", name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if playItem.status == .readyToPlay {
                let dutation = playItem.duration
                let totalSecond = CGFloat(playItem.duration.value) / CGFloat(playItem.duration.timescale)
                totalTimer = converTimer(time: totalSecond)
                configureSlider(duration: dutation)
                monitoringPlayback(item: self.playItem)
                
                let layer = playView.layer as! AVPlayerLayer
                layer.player?.play()
            }
        }
    }
    
    func videoPlayDidEnd(notifation: NSNotification) {
        playItem.seek(to: CMTimeMake(value: 0, timescale: 1))
        let layer = playView.layer as! AVPlayerLayer
        layer.player?.play()
    }

    // MARK: operation
    
    func converTimer(time: CGFloat) -> String {
        let date = NSDate(timeIntervalSince1970: Double(time))
        let dateFormat = DateFormatter()
        if time / 3600 >= 1 {
            dateFormat.dateFormat = "HH:mm:ss"
        } else {
            dateFormat.dateFormat = "mm:ss"
        }
        let formatTime = dateFormat.string(from: date as Date)
        
        return formatTime
    }
    
    
    func configureSlider(duration: CMTime) {
        playView.slider.maximumValue = Float(CMTimeGetSeconds(duration))
    }
    
    func monitoringPlayback(item: AVPlayerItem) {
        let layer = playView.layer as! AVPlayerLayer
        timerObserver = layer.player!.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 1), queue: nil, using: { (time) -> Void in
            let currentSecond = item.currentTime().value / Int64(item.currentTime().timescale)
            self.playView.slider.setValue(Float(currentSecond), animated: true)
            let timeStr = self.converTimer(time: CGFloat(currentSecond))
            self.playView.timerIndicator.text = "\(timeStr)/\(self.totalTimer)"
        }) as AnyObject
    }
}

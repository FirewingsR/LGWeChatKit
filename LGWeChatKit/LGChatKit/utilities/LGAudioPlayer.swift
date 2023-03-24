//
//  LGAudioPlayer.swift
//  LGChatViewController
//
//  Created by jamy on 10/13/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import UIKit
import AVFoundation

class LGAudioPlayer: NSObject, AVAudioPlayerDelegate {
    
    var audioPlayer: AVAudioPlayer!
    
    override init() {
        
    }
    
    func startPlaying(message: voiceMessage) {
        if (audioPlayer != nil && audioPlayer.isPlaying) {
            stopPlaying()
        }
     
        let voiceData = NSData(contentsOf: message.voicePath as URL)
    
        do {
            try audioPlayer = AVAudioPlayer(data: voiceData! as Data)
        } catch{
            return
        }
        audioPlayer.delegate = self
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
        } catch {
            // no-op
        }
        
        audioPlayer.play()
    }
    
    
    func stopPlaying() {
        audioPlayer.stop()
    }
}

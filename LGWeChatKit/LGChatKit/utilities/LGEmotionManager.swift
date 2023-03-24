//
//  LGEmotionManager.swift
//  LGChatViewController
//
//  Created by jamy on 10/16/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import UIKit

class LGEmotionManager: NSObject {
    
    var emotionArray: NSArray!
    
    var emotionDict: [String: NSArray]!
    
    /// dispatch_once
    static let shareInstance: LGEmotionManager = {
        return LGEmotionManager()
    }()
    
    
    override init() {
        super.init()
        if let fileName = Bundle.main.path(forResource: "emoji_config", ofType: "json") {
            emotionArray = try! JSONSerialization.jsonObject(with: NSData(contentsOfFile: fileName)! as Data, options: JSONSerialization.ReadingOptions.allowFragments) as! NSArray
            
            if emotionArray.count > 0 {
                emotionArray.enumerateObjects { objc, index, stop in
                    let emotionData = objc as! NSArray
                    self.emotionDict = [(emotionData[1] as! String): [emotionData[0], emotionData[2]]]
                }
            }
        }
    }
}

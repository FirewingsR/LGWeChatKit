//
//  LGMoreView.swift
//  LGChatViewController
//
//  Created by jamy on 10/16/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import UIKit


enum shareMoreType: Int {
    case picture = 1, video, location, record, timeSpeak, hongbao, personCard, store
    
    func imageForType() -> (UIImage, String) {
        var image = UIImage()
        var title = ""
        switch self {
        case .picture:
            image = UIImage(named: "sharemore_pic")!
            title = "照片"
        case .video:
            image = UIImage(named: "sharemore_videovoip")!
            title = "拍摄"
        case .location:
            image = UIImage(named: "sharemore_location")!
            title = "位置"
        case .record:
            image = UIImage(named: "sharemore_sight")!
            title = "小视频"
        case .timeSpeak:
            image = UIImage(named: "sharemore_wxtalk")!
            title = "语音输入"
        case .hongbao:
            image = UIImage(named: "sharemorePay")!
            title = "红包"
        case .personCard:
            image = UIImage(named: "sharemore_friendcard")!
            title = "个人名片"
        case .store:
            image = UIImage(named: "sharemore_myfav")!
            title = "收藏"
        }
        return (image, title)
    }
}


class LGShareMoreView: UIView {

    let shareCount = 8

    let marginW = 30
    let marginH = 20
    let buttonH: CGFloat = 59
    
    
    convenience init(frame: CGRect, selector: Selector, target: AnyObject) {
        self.init(frame: frame)
        backgroundColor = UIColor(hexString: "F4F4F6")
        
        let marginX = (bounds.width - CGFloat(2 * marginW) - CGFloat(4 * buttonH)) / 3
        for i in 0...shareCount - 1 {
            let row = i / 4
            let column = i % 4
            
            let button = UIButton(type: .custom)
            button.tag = i + 1
            button.addTarget(target, action: selector, for: .touchUpInside)
            
            let image = shareMoreType(rawValue: i + 1)?.imageForType().0
            let title = shareMoreType(rawValue: i + 1)?.imageForType().1
            
            button.setImage(image, for: .normal)
            button.setTitleColor(UIColor.black, for: .normal)
            button.setTitle(title, for: .normal)
            
//            button.titleEdgeInsets = UIEdgeInsetsMake(53, -59, 0, 0)
//            button.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 21, 0)
            
            button.setBackgroundImage(UIImage(named: "sharemore_otherDown"), for: .normal)
            button.setBackgroundImage(UIImage(named: "sharemore_otherDownHL"), for: .highlighted)
            
            let buttonX = CGFloat(marginW) + (buttonH + marginX) * CGFloat(column)
            let buttonY = CGFloat(marginH) + (buttonH + CGFloat(marginH)) * CGFloat(row)
            button.frame = CGRectMake(buttonX, buttonY, buttonH, buttonH)
            addSubview(button)
        }

    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}


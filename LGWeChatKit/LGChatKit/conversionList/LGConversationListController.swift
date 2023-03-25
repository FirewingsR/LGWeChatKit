//
//  LGMessageListController.swift
//  LGChatViewController
//
//  Created by gujianming on 15/10/8.
//  Copyright © 2015年 jamy. All rights reserved.
//

import UIKit

class LGConversationListController: UITableViewController, LGConversionListBaseCellDelegate {
    
    
    override func viewDidLoad() {
        self.tableView.rowHeight = 60.0
        self.title = "消息"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "messageListCell") as? LGConversionListCell
        if cell == nil {
            let leftButtons = [UIButton.createButton(title: "取消关注", backGroundColor: UIColor.purple)]
            let rightButtons = [UIButton.createButton(title: "标记已读", backGroundColor: UIColor.gray), UIButton.createButton(title: "删除", backGroundColor: UIColor.red)]
            
            cell = LGConversionListCell(style: .subtitle, reuseIdentifier: "messageListCell")
            cell?.delegate = self
            cell?.viewModel = updateCell()
            
            cell?.setLeftButtons(buttons: leftButtons)
            cell?.setRightButtons(buttons: rightButtons)
        }
        
        return cell!
    }
    
    // just for test message
    
    let image = ["icon1", "icon2", "icon3", "icon4", "icon0"]
    let name = ["招商银行信用卡中心", "微信运动", "just for IOS", "jamy", "腾讯新闻"]
    let time = ["13:14", "23:45", "昨天", "星期五", "15/10/19"]
    let message = ["iPhone 6s 和 iPhone 6s Plus 可使用中国移动、中国联通或中国电信的网络", "如果你从 apple.com 购买 iPhone，则此 iPhone 为无合约 iPhone。你可以直接联系运营商，了解适用于 iPhone 的服务套餐。", "http://www.apple.com/cn/iphone-6s/", "你是我的眼", "do you know who I am"]
    
    func updateCell() -> LGConversionListCellModel{
        
        let viewModel = LGConversionListCellModel()
        
        viewModel.iconName.value = image[Int(arc4random()) % 5]
        viewModel.userName.value = name[Int(arc4random()) % 5]
        viewModel.timer.value = time[Int(arc4random()) % 5]
        viewModel.lastMessage.value = message[Int(arc4random()) % 5]
        
        return viewModel
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        navigationController?.pushViewController(LGConversationViewController(), animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    
    // MARK: - cell delegate
    
    func didSelectedLeftButton(index: Int) {
        let actionSheet = UIAlertController(title: "取消关注", message: "确定要取消关注?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "取消", style: .cancel, handler: { (alertAction) -> Void in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "确定", style: .default, handler: { (alertAction) -> Void in
            
        }))
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    func didSelectedRightButton(index: Int) {
        NSLog("click")
    }
    
}

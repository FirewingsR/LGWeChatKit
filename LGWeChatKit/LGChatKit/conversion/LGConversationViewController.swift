//
//  LGConversationViewController.swift
//  LGChatViewController
//
//  Created by jamy on 10/9/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import UIKit
import AVFoundation


let toolBarMinHeight: CGFloat = 44.0
let indicatorViewH: CGFloat = 120

let messageOutSound: SystemSoundID = {
    var soundID: SystemSoundID = 10120
    let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "MessageOutgoing" as CFString, "aiff" as CFString, nil)
    AudioServicesCreateSystemSoundID(soundUrl!, &soundID)
    return soundID
}()


let messageInSound: SystemSoundID = {
    var soundID: SystemSoundID = 10121
    let soundUrl = CFBundleCopyResourceURL(CFBundleGetMainBundle(), "MessageIncoming" as CFString, "aiff" as CFString, nil)
    AudioServicesCreateSystemSoundID(soundUrl!, &soundID)
    return soundID
}()


class LGConversationViewController: UIViewController, UITableViewDataSource, UITableViewDelegate , UITextViewDelegate {
    
    var tableView: UITableView!
    var toolBarView: LGToolBarView!
    var emojiView: LGEmotionView!
    var shareView: LGShareMoreView!
    var recordIndicatorView: LGRecordIndicatorView!
    var videoController: LGVideoController!
    
    var recorder: LGAudioRecorder!
    var player: LGAudioPlayer!
    var videoRecordBakgoundView: UIView!
    var videoRecordView: LGRecordVideoView!
    
    var messageList = [Message]()
    var toolBarConstranit: NSLayoutConstraint!
    
    // MARK: - lifecycle
    init(){
        super.init(nibName: nil, bundle: nil)
        hidesBottomBarWhenPushed = true
        title = "jamy"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor(patternImage: UIImage(named: "bg3")!)
        
        tableView = UITableView()
        tableView.backgroundColor = UIColor.clear
        tableView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        tableView.delegate = self
        tableView.dataSource  = self
        tableView.estimatedRowHeight = 44.0
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: toolBarMinHeight / 2, right: 0)
        tableView.separatorStyle = .none
        
        tableView.register(LGChatImageCell.self, forCellReuseIdentifier: NSStringFromClass(LGChatImageCell.self))
        tableView.register(LGChatTextCell.self, forCellReuseIdentifier: NSStringFromClass(LGChatTextCell.self))
        tableView.register(LGChatVoiceCell.self, forCellReuseIdentifier: NSStringFromClass(LGChatVoiceCell.self))
        tableView.register(LGChatVideoCell.self, forCellReuseIdentifier: NSStringFromClass(LGChatVideoCell.self))
        
        view.addSubview(tableView)
        
        recordIndicatorView = LGRecordIndicatorView(frame: CGRectMake(self.view.center.x - indicatorViewH / 2, self.view.center.y - indicatorViewH / 3, indicatorViewH, indicatorViewH))
 
        emojiView = LGEmotionView(frame: CGRectMake(0, 0, view.bounds.width, 196))
        emojiView.delegate = self
        
        shareView = LGShareMoreView(frame: CGRectMake(0, 0, view.bounds.width, 196), selector: "shareMoreClick:", target: self)
        
        toolBarView = LGToolBarView(taget: self, voiceSelector: "voiceClick:", recordSelector: "recordClick:", emotionSelector: "emotionClick:", moreSelector: "moreClick:")
        toolBarView.textView.delegate = self
        view.addSubview(toolBarView)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        toolBarView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addConstraint(NSLayoutConstraint(item: toolBarView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: toolBarView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: toolBarView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: toolBarMinHeight))
        toolBarConstranit = NSLayoutConstraint(item: toolBarView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(toolBarConstranit)
        
        view.addConstraint(NSLayoutConstraint(item: tableView, attribute: .left, relatedBy: .equal, toItem: view, attribute: .left, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: tableView, attribute: .right, relatedBy: .equal, toItem: view, attribute: .right, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: toolBarView, attribute: .top, multiplier: 1, constant: 0))
        
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapTableView:"))
        NotificationCenter.default.addObserver(self, selector: "keyboardChange:", name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: "hiddenMenuController:", name: UIMenuController.willHideMenuNotification, object: nil)
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if player != nil {
            if player.audioPlayer.isPlaying {
                player.stopPlaying()
            }
        }
    }
    
    // show menuController
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    // MARK: - tableView dataSource/Delegate
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: LGChatBaseCell
        
        let message = messageList[indexPath.row]
        
        switch message.messageType {
        case .Text:
            cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LGChatTextCell.self), for: indexPath) as! LGChatTextCell
        case .Image:
            cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LGChatImageCell.self), for: indexPath) as! LGChatImageCell
        case .Voice:
            cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LGChatVoiceCell.self), for: indexPath) as! LGChatVoiceCell
        case .Video:
            cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LGChatVideoCell.self), for: indexPath) as! LGChatVideoCell
        }
        
        // add gustureRecognizer to show menu items
        let action: Selector = "showMenuAction:"
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: action)
        doubleTapGesture.numberOfTapsRequired = 2
        cell.backgroundImageView.addGestureRecognizer(doubleTapGesture)
        cell.backgroundImageView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: action))
        cell.backgroundImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "clickCellAction:"))
        
        if indexPath.row > 0 {
            let preMessage = messageList[indexPath.row - 1]
            if preMessage.dataString == message.dataString {
                cell.timeLabel.isHidden = true
            } else {
                cell.timeLabel.isHidden = false
            }
        }

        cell.setMessage(message: message)
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, willSelectRowAtindexPath: IndexPath) -> IndexPath? {
        return nil
    }
    
    func scrollToBottom() {
        let numberOfRows = tableView.numberOfRows(inSection: 0)
        if numberOfRows > 0 {
            tableView.scrollToRow(at: IndexPath(row: numberOfRows - 1, section: 0), at: .bottom, animated: true)
        }
    }
    
    func reloadTableView() {
        let count = messageList.count
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: count - 1, section: 0)], with: .top)
        tableView.endUpdates()
       scrollToBottom()
    }
    
    // MARK: scrollview delegate
    func scrollViewWillEndDragging(scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.y > 2.0 {
            scrollToBottom()
            self.toolBarView.textView.becomeFirstResponder()
        } else if velocity.y < -0.1 {
            self.toolBarView.textView.resignFirstResponder()
        }
    }
    
    // MARK: - keyBoard notification
    func keyboardChange(notification: NSNotification) {
        let userInfo = notification.userInfo as! NSDictionary
        let newFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        let animationTimer = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        
        view.layoutIfNeeded()
        if newFrame.origin.y == UIScreen.main.bounds.size.height {
            UIView.animate(withDuration: animationTimer, animations: { () -> Void in
                self.toolBarConstranit.constant = 0
                self.view.layoutIfNeeded()
            })
        } else {
            UIView.animate(withDuration: animationTimer, animations: { () -> Void in
               self.toolBarConstranit.constant = -newFrame.size.height
                self.scrollToBottom()
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: - menu actions
    
    func showMenuAction(gestureRecognizer: UITapGestureRecognizer) {
        let twoTaps = (gestureRecognizer.numberOfTapsRequired == 2)
        let doubleTap = (twoTaps && gestureRecognizer.state == .ended)
        let longPress = (!twoTaps && gestureRecognizer.state == .began)
        
        if doubleTap || longPress {
            let pressIndexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView))!
            tableView.selectRow(at: pressIndexPath, animated: false, scrollPosition: .none)
            
            let menuController = UIMenuController.shared
            let localImageView = gestureRecognizer.view!
            
            menuController.setTargetRect(localImageView.frame, in: localImageView.superview!)
            menuController.menuItems = [UIMenuItem(title: "复制", action: "copyAction:"), UIMenuItem(title: "转发", action: "transtionAction:"), UIMenuItem(title: "删除", action: "deleteAction:"), UIMenuItem(title: "更多", action: "moreAciton:")]
           
            menuController.setMenuVisible(true, animated: true)
        }
    }
    
    func copyAction(menuController: UIMenuController) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            if let message = messageList[selectedIndexPath.row] as? textMessage {
                UIPasteboard.general.string = message.text
            }
        }
    }
    
    func transtionAction(menuController: UIMenuController) {
        NSLog("转发")
    }
    
    func deleteAction(menuController: UIMenuController) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow {
            messageList.remove(at: selectedIndexPath.row)
            tableView.reloadData()
        }
    }
    
    func moreAciton(menuController: UIMenuController) {
        NSLog("click more")
    }
    
    func hiddenMenuController(notifiacation: NSNotification) {
        if let selectedIndexpath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedIndexpath, animated: false)
        }
        (notifiacation.object as! UIMenuController).menuItems = nil
    }
    
    // MARK: - gestureRecognizer
    func tapTableView(gestureRecognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
        toolBarConstranit.constant = 0
        toolBarView.showEmotion(show: false)
        toolBarView.showMore(show: false)
    }
    
    func clickCellAction(gestureRecognizer: UITapGestureRecognizer) {
        let pressIndexPath = tableView.indexPathForRow(at: gestureRecognizer.location(in: tableView))!
        let pressCell = tableView.cellForRow(at: pressIndexPath)
        let message = messageList[pressIndexPath.row]
        
        if message.messageType == .Voice {
            let message = message as! voiceMessage
            let cell = pressCell as! LGChatVoiceCell
            let play = LGAudioPlayer()
            player = play
            player.startPlaying(message: message)
            cell.beginAnimation()
            
            let time = Int64(message.voiceTime.intValue) * 1000 * 1000 * 1000
            
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(Int(time)), execute: {
                cell.stopAnimation()
            })
            
        } else if message.messageType == .Video {
            let message = message as! videoMessage
            if videoController != nil {
                videoController = nil
            }
            videoController = LGVideoController()
            videoController.setPlayUrl(url: message.url)
            present(videoController, animated: true, completion: nil)
        }
    }
}

// MARK: extension for toobar action

extension LGConversationViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, LGAudioRecorderDelegate, LGEmotionViewDelegate, LGImagePickControllerDelegate, LGMapViewControllerDelegate {

    func voiceClick(button: UIButton) {
        if toolBarView.recordButton.isHidden == false {
            toolBarView.showRecord(show: false)
        } else {
            toolBarView.showRecord(show: true)
            self.view.endEditing(true)
        }
    }
    
    func recordClick(button: UIButton) {
        button.setTitle("松开     结束", for: .normal)
        button.addTarget(self, action: "recordComplection:", for: .touchUpInside)
        button.addTarget(self, action: "recordDragOut:", for: .touchDragOutside)
        button.addTarget(self, action: "recordCancel:", for: .touchUpOutside)
        
        let currentTime = NSDate().timeIntervalSinceReferenceDate
        let record = LGAudioRecorder(fileName: "\(currentTime).wav")
        record.delegate = self
        recorder = record
        recorder.startRecord()
        
        recordIndicatorView = LGRecordIndicatorView(frame: CGRectMake(self.view.center.x - indicatorViewH / 2, self.view.center.y - indicatorViewH / 3, indicatorViewH, indicatorViewH))
        view.addSubview(recordIndicatorView)
    }
    
    func recordComplection(button: UIButton) {
        button.setTitle("按住     说话", for: .normal)
        recorder.stopRecord()
        recorder.delegate = nil
        recordIndicatorView.removeFromSuperview()
        recordIndicatorView = nil
        
        if recorder.timeInterval != nil {
            let message = voiceMessage(incoming: false, sentDate: NSDate(), iconName: "", voicePath: recorder.recorder.url as NSURL, voiceTime: recorder.timeInterval)
            let receiveMessage = voiceMessage(incoming: true, sentDate: NSDate(), iconName: "", voicePath: recorder.recorder.url as NSURL, voiceTime: recorder.timeInterval)
            
            messageList.append(message)
            reloadTableView()
            messageList.append(receiveMessage)
            reloadTableView()
            AudioServicesPlayAlertSound(messageOutSound)
        }
    }
    
    func recordDragOut(button: UIButton) {
        button.setTitle("按住     说话", for: .normal)
        recordIndicatorView.showText(text: "松开手指,取消发送", textColor: UIColor.red)
    }
    
    
    func recordCancel(button: UIButton) {
        button.setTitle("按住     说话", for: .normal)
        recorder.stopRecord()
        recorder.delegate = nil
        recordIndicatorView.removeFromSuperview()
        recordIndicatorView = nil
    }
    
    func emotionClick(button: UIButton) {
        if toolBarView.emotionButton.tag == 1 {
            toolBarView.showEmotion(show: true)
            toolBarView.textView.inputView = emojiView
        } else {
            toolBarView.showEmotion(show: false)
            toolBarView.textView.inputView = nil
        }
        toolBarView.textView.becomeFirstResponder()
        toolBarView.textView.reloadInputViews()
    }
    
    func moreClick(button: UIButton) {
        if toolBarView.moreButton.tag == 2 {
            toolBarView.showMore(show: true)
            toolBarView.textView.inputView = shareView
        } else {
            toolBarView.showMore(show: false)
            toolBarView.textView.inputView = nil
        }
        
        toolBarView.textView.becomeFirstResponder()
        toolBarView.textView.reloadInputViews()
    }
    
    // shareMore click
    
    func shareMoreClick(button: UIButton) {
        let shareType = shareMoreType(rawValue: button.tag)!
        
        switch shareType {
        case .picture:
            let imagePick = LGImagePickController()
            imagePick.delegate = self
            let nav = UINavigationController(rootViewController: imagePick)
            self.present(nav, animated: true, completion: nil)
        case .video:
            let url = NSURL(fileURLWithPath: Bundle.main.path(forResource: "test", ofType: "m4v")!)
            let message = videoMessage(incoming: false, sentDate: NSDate(), iconName: "", url: url)
            messageList.append(message)
            reloadTableView()
            AudioServicesPlayAlertSound(messageOutSound)
            toolBarView.showMore(show: false)
            self.view.endEditing(true)
        case .location:
            let mapCtrl = LGMapViewController()
            mapCtrl.delegate = self
            let nav = UINavigationController(rootViewController: mapCtrl)
            self.present(nav, animated: true, completion: nil)
        case .record:
            beginVideoRecord()
        default:
            break
        }
    }
    
    func beginVideoRecord() {
        videoRecordView = LGRecordVideoView(frame: CGRectMake(0, view.bounds.height * 0.4, view.bounds.width, view.bounds.height * 0.6))
        videoRecordBakgoundView = UIView(frame: view.bounds)
        videoRecordBakgoundView.backgroundColor = UIColor.black
        videoRecordBakgoundView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "videoBackgroundViewClick:"))
        videoRecordBakgoundView.alpha = 0.6
        videoRecordView.alpha = 1.0
        
        UIView.animate(withDuration: 0.35, animations: { () -> Void in
            self.view.endEditing(true)
            self.toolBarConstranit.constant = self.videoRecordView.bounds.height
            self.scrollToBottom()
            self.view.layoutIfNeeded()
            }) { (finish) -> Void in
                self.view.addSubview(self.videoRecordBakgoundView)
                self.view.addSubview(self.videoRecordView)
        }
        
        videoRecordView.recordVideoModel.complectionClosure = { (url: NSURL) -> Void in
            let message = videoMessage(incoming: false, sentDate: NSDate(), iconName: "", url: url)
            self.messageList.append(message)
            self.reloadTableView()
            AudioServicesPlayAlertSound(messageOutSound)
            self.toolBarView.showMore(show: false)
            self.videoRecordComplection()
        }
        
        videoRecordView.recordVideoModel.cancelClosure = {
            self.videoRecordComplection()
        }
    }
    
    func videoBackgroundViewClick(gestureReconizer: UITapGestureRecognizer) {
        videoRecordComplection()
    }
    
    func videoRecordComplection() {
        view.layoutIfNeeded()
        UIView.animate(withDuration: 0.35, animations: { () -> Void in
            self.videoRecordBakgoundView.bounds.y = self.view.bounds.height
            self.videoRecordView.bounds.y = self.view.bounds.height
            }) { (_) -> Void in
                self.videoRecordView.removeFromSuperview()
                self.videoRecordBakgoundView.removeFromSuperview()
                self.videoRecordBakgoundView = nil
                self.videoRecordView = nil
                self.toolBarConstranit.constant = 0
                self.view.layoutIfNeeded()
        }
        toolBarView.showMore(show: false)
    }
    
    func sendImage(image: UIImage) {
        let message = imageMessage(incoming: false, sentDate: NSDate(), iconName: "", image: image)
        messageList.append(message)
        AudioServicesPlayAlertSound(messageOutSound)
        reloadTableView()
    }
    
    // MARK: - UIImagePick delegate
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        toolBarView.showMore(show: false)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        toolBarView.showMore(show: false)
        picker.dismiss(animated: true, completion: nil)
        
    }
    
    // MARK: - mapview delegate
    
    func mapViewController(controller: LGMapViewController, didSelectLocationSnapeShort image: UIImage) {
        toolBarView.showMore(show: false)
        sendImage(image: image)
    }
    
    func mapViewController(controller: LGMapViewController, didCancel error: NSError?) {
        toolBarView.showMore(show: false)
    }
    
    // MARK: - imagePick delegate
    func imagePickerController(picker: LGImagePickController, didFinishPickingImages images: [UIImage]) {
        toolBarView.showMore(show: false)
        for image in images {
            sendImage(image: image)
        }
    }
    
    func imagePickerControllerCanceled(picker: LGImagePickController) {
        toolBarView.showMore(show: false)
    }
    
    // MARK: - emojiDelegate
    func selectEmoji(code: String, description: String, delete: Bool) {
        if delete {
            let range: Range = toolBarView.textView.text.index(toolBarView.textView.text.endIndex, offsetBy: -1) ..< toolBarView.textView.text.endIndex
            toolBarView.textView.text.removeSubrange(range)
        } else {
            toolBarView.textView.text.append(contentsOf: code)
        }
    }
    
    // MARK: - textViewDelegate
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let messageStr = textView.text.trimmingCharacters(in: NSCharacterSet.whitespaces)
            if messageStr.lengthOfBytes(using: String.Encoding(rawValue: NSUTF8StringEncoding)) == 0 {
                return true
            }
            
            let message = textMessage(incoming: false, sentDate: NSDate(), iconName: "", text: messageStr)
            let receiveMessage = textMessage(incoming: true, sentDate: NSDate(), iconName: "", text: messageStr)
            
            messageList.append(message)
            reloadTableView()
            messageList.append(receiveMessage)
            reloadTableView()
            AudioServicesPlayAlertSound(messageOutSound)
            textView.text = ""
            return false
        }
        return true
    }
    
    // MARK: -LGrecordDelegate
    func audioRecorderUpdateMetra(metra: Float) {
        if recordIndicatorView != nil {
            recordIndicatorView.updateLevelMetra(levelMetra: metra)
        }
    }
}

//  LGConversionListBaseCell.swift
//  LGChatViewController
//
//  Created by jamy on 10/19/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import UIKit

public enum LGCellStatus: Int {
    case center = 1, left, right
}


protocol LGConversionListBaseCellDelegate {
    func didSelectedLeftButton(index: Int)
    func didSelectedRightButton(index: Int)
}

class LGCellScrollView: UIScrollView, UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.panGestureRecognizer {
            let gesture = gestureRecognizer as! UIPanGestureRecognizer
            let translation = gesture.translation(in: gestureRecognizer.view)
            return fabs(translation.y) <= fabs(translation.x)
        } else {
            return true
        }
    }
   
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer.isKind(of: UIPanGestureRecognizer.self) {
            let gesture = gestureRecognizer as! UIPanGestureRecognizer
            let velocity = gesture.velocity(in: gestureRecognizer.view).y
            
            return fabs(velocity) <= 0.20
        }
        return true
    }
    
}

@IBDesignable
class LGConversionListBaseCell: UITableViewCell {
    weak var containingTableView: UITableView! {
        willSet {
            if newValue != nil {
                removeOldTableViewPanObserver()
                tableViewpPanGesture = newValue.panGestureRecognizer
                newValue.isDirectionalLockEnabled = true
                tapGesture.require(toFail: newValue.panGestureRecognizer)
            }
        }
        didSet {
            tapGesture.addObserver(self, forKeyPath: tableViewKeyPath, options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        }
    }
    
    override var frame: CGRect {
        willSet {
         layoutUpdating = true
         let change = self.frame.size.width != newValue.size.width
         super.frame = newValue
            if change {
                self.layoutIfNeeded()
            }
        }
        didSet {
            
            layoutUpdating = false
        }
    }
    
    var delegate: LGConversionListBaseCellDelegate?
    
    var tableViewpPanGesture: UIPanGestureRecognizer!
    var cellStatus: LGCellStatus = .center
    var cellScrollView: LGCellScrollView!
    var containtCellView: UIView!
    
    var leftButtonView: LGButtonView!
    var rightButtonView: LGButtonView!
    var leftButtonContainView: UIView!
    var rightButtonContainView: UIView!
    
    var layoutUpdating = false
    var leftConstraint: NSLayoutConstraint!
    var rightConstraint: NSLayoutConstraint!
    
    var longPressGesture: UILongPressGestureRecognizer!
    var tapGesture: UITapGestureRecognizer!
    
    
    // MARK: - lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        cellScrollView = LGCellScrollView()
        cellScrollView.delegate = self
        cellScrollView.isScrollEnabled = true
        cellScrollView.scrollsToTop = false
        cellScrollView.showsHorizontalScrollIndicator = false
        cellScrollView.translatesAutoresizingMaskIntoConstraints = false
        containtCellView = UIView()
        cellScrollView.addSubview(containtCellView)
        containtCellView.tag = 10010
        let cellSubViews = subviews
        insertSubview(cellScrollView, at: 0)
        for subView in cellSubViews {
            containtCellView.addSubview(subView)
        }
        
        addConstraints([NSLayoutConstraint(item: cellScrollView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: cellScrollView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: cellScrollView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
            NSLayoutConstraint(item: cellScrollView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)])
        
        tapGesture = UITapGestureRecognizer(target: self, action: "scrollViewTapped:")
        tapGesture.delegate = self
        tapGesture.cancelsTouchesInView = false
        cellScrollView.addGestureRecognizer(tapGesture)
        
        longPressGesture = UILongPressGestureRecognizer(target: self, action: "scrollViewPress:")
        longPressGesture.delegate = self
        longPressGesture.cancelsTouchesInView = false
        longPressGesture.minimumPressDuration = 0.15
        cellScrollView.addGestureRecognizer(longPressGesture)
        
        leftButtonContainView = UIView()
        leftButtonContainView.tag = 10030
        leftConstraint = NSLayoutConstraint(item: leftButtonContainView, attribute: .right, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: 0)
        leftButtonView = LGButtonView(buttons: [UIButton](), parentCell: self, buttonSelector: Selector("leftButtonHandle:"))
    
        rightButtonContainView = UIView(frame: bounds)
        rightButtonContainView.tag = 10020
        rightConstraint = NSLayoutConstraint(item: rightButtonContainView, attribute: .left, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: 0)
        rightButtonView = LGButtonView(buttons: [UIButton](), parentCell: self, buttonSelector: Selector("rightButtonHandler:"))
        
        let containViews = [rightButtonContainView, leftButtonContainView]
        let containLayout = [rightConstraint, leftConstraint]
        let buttonViews = [rightButtonView, leftButtonView]
        let layoutAttributes = [NSLayoutConstraint.Attribute.right, NSLayoutConstraint.Attribute.left]
        
        for i in 0...1 {
            let clipView = containViews[i]
            let clipConstraint: NSLayoutConstraint = containLayout[i]!
            let buttonView = buttonViews[i]
            let layoutAttribute = layoutAttributes[i]
            
            clipConstraint.priority = UILayoutPriority.defaultHigh
            clipView?.translatesAutoresizingMaskIntoConstraints = false
            clipView?.clipsToBounds = true
            
            cellScrollView.addSubview(clipView!)
            addConstraints([NSLayoutConstraint(item: clipView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: clipView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: clipView, attribute: layoutAttribute, relatedBy: .equal, toItem: self, attribute: layoutAttribute, multiplier: 1, constant: 0), clipConstraint])
            
            clipView?.addSubview(buttonView!)
            addConstraints([NSLayoutConstraint(item: buttonView, attribute: .top, relatedBy: .equal, toItem: clipView, attribute: .top, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: buttonView, attribute: .bottom, relatedBy: .equal, toItem: clipView, attribute: .bottom, multiplier: 1, constant: 0),
                NSLayoutConstraint(item: buttonView, attribute: layoutAttribute, relatedBy: .equal, toItem: clipView, attribute: layoutAttribute, multiplier: 1, constant: 0),
                            NSLayoutConstraint(item: buttonView, attribute: .width, relatedBy: .lessThanOrEqual, toItem: self.contentView, attribute: .width, multiplier: 1, constant: -90)])
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        cellScrollView.delegate = nil
        removeOldTableViewPanObserver()
    }
    
    // MARK: - observer
    
    let tableViewKeyPath = "state"
    
    func removeOldTableViewPanObserver() {
        if tableViewpPanGesture == nil {
            return
        }
        tableViewpPanGesture.removeObserver(self, forKeyPath: tableViewKeyPath)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let path = keyPath {
            if path == tableViewKeyPath {
                if object as AnyObject === tableViewpPanGesture {
                    let locationTableView = tableViewpPanGesture.location(in: containingTableView)
                    let currentCell = CGRectContainsPoint(self.frame, locationTableView)
                    
                    if !currentCell && cellStatus != .center {
                        hiddenButtonsAnimated(animated: true)
                    }
                }
            }
        }
    }
    
    func setLeftButtons(buttons: [UIButton], width: CGFloat = 90) {
        leftButtonView.setupButton(buttons: buttons, buttonWidth: width)
        leftButtonView.layoutIfNeeded()
        layoutIfNeeded()
    }
    
    func setRightButtons(buttons: [UIButton], width: CGFloat = 90) {
        rightButtonView.setupButton(buttons: buttons, buttonWidth: width)
        rightButtonView.layoutIfNeeded()
        layoutIfNeeded()
    }
    
    // MARK: - uitableView overrides
    
    override func didMoveToSuperview() {
        containingTableView = nil
        var view = self.superview
        repeat {
            if view!.isKind(of: UITableView.self) {
                containingTableView = view as! UITableView
                break
            }
            view = view?.superview
        } while (view != nil)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        var frame = contentView.frame
        frame.x = leftButtonsWidth()
        contentView.frame = frame
        
        cellScrollView.contentSize = CGSizeMake(CGRectGetWidth(self.frame) + totalButtonsWidth(), CGRectGetHeight(self.frame))
        
        if !cellScrollView.isTracking && !cellScrollView.isDecelerating {
            cellScrollView.contentOffset = contentOffsetForCellStatus(status: cellStatus)
        }
        
        updateCellStatus()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.hiddenButtonsAnimated(animated: true)
    }
    
    override func didTransition(to state: UITableViewCell.StateMask) {
        super.didTransition(to: state)
        
        print(state)
        
//        if state == UITableViewCell.StateMask.DefaultMask {
//            layoutSubviews()
//        }
    }
    
    // MARK: - selection handle
    
    func shouldHighlight() -> Bool {
        var shouldHighlight = true
        if containingTableView.delegate!.responds(to: "tableView:shouldHighlightRowAt:") {
            let cellIndexPath = containingTableView.indexPath(for: self)
            shouldHighlight = (containingTableView.delegate?.tableView!(containingTableView, shouldHighlightRowAt: cellIndexPath!))!
        }
        
        return shouldHighlight
    }
    
    func scrollViewPress(gestureRecognizer: UIGestureRecognizer) {
        hiddenOtherCells()
        if gestureRecognizer.state == .began && !self.isHighlighted && self.shouldHighlight() {
            setHighlighted(true, animated: false)
        } else if gestureRecognizer.state == .ended {
            setHighlighted(false, animated: false)
            scrollViewTapped(gestureRecognizer: gestureRecognizer)
        } else if gestureRecognizer.state == .cancelled {
            setHighlighted(false, animated: false)
        }
    }
    
    func scrollViewTapped(gestureRecognizer: UIGestureRecognizer) {
        
        for cell in containingTableView.visibleCells {
            let newCell = cell as! LGConversionListBaseCell
            if newCell != self && newCell.isKind(of: LGConversionListBaseCell.self) {
                if newCell.cellStatus != .center {
                    newCell.hiddenButtonsAnimated(animated: true)
                    break
                }
            }
        }
        
        if cellStatus == .center {
            if self.isSelected {
                deselectCell()
            } else if shouldHighlight() && !containingTableView.isTracking && !containingTableView.isDecelerating {
                selectCell()
            }
        } else {
            hiddenButtonsAnimated(animated: true)
        }
    }
    
    func selectCell() {
        if cellStatus == .center {
            var cellIndexPath = containingTableView.indexPath(for: self)
            if containingTableView.delegate!.responds(to: "tableView:willSelectRowAt:") {
                cellIndexPath = containingTableView.delegate?.tableView!(containingTableView, willSelectRowAt: cellIndexPath!)
            }
            if cellIndexPath != nil {
                containingTableView.selectRow(at: cellIndexPath, animated: false, scrollPosition: .none)
                if containingTableView.delegate!.responds(to: "tableView:didSelectRowAt:") {
                    containingTableView.delegate?.tableView!(containingTableView, didSelectRowAt: cellIndexPath!)
                }
            }
        }
    }
    
    func deselectCell() {
        if cellStatus == .center {
            var cellIndexPath = containingTableView.indexPath(for: self)
            if containingTableView.delegate!.responds(to: "tableView:willDeselectRowAt:") {
                cellIndexPath = containingTableView.delegate?.tableView!(containingTableView, willDeselectRowAt: cellIndexPath!)
            }
            
            if cellIndexPath != nil {
                containingTableView.deselectRow(at: cellIndexPath!, animated: false)
                
                if containingTableView.delegate!.responds(to: "tableView:didDeselectRowAt:") {
                    containingTableView.delegate?.tableView!(containingTableView, didDeselectRowAt: cellIndexPath!)
                }
            }
        }
    }
    
    // MARK: - buttons handling
    func rightButtonHandler(gestureRecognizer: LGButtonTapGestureRecognizer) {
        delegate?.didSelectedRightButton(index: gestureRecognizer.buttonIndex)
        hiddenButtonsAnimated(animated: true)
    }
    
    func leftButtonHandle(gestureRecognizer: LGButtonTapGestureRecognizer) {
        delegate?.didSelectedLeftButton(index: gestureRecognizer.buttonIndex)
        hiddenButtonsAnimated(animated: true)
    }
    
    func hiddenButtonsAnimated(animated: Bool) {
        if cellStatus != .center {
            cellScrollView.setContentOffset(contentOffsetForCellStatus(status: .center), animated: animated)
        }
    }
    
    func showLeftButtonsAnimated(animated: Bool) {
        if cellStatus != .left {
            cellScrollView.setContentOffset(contentOffsetForCellStatus(status: .left), animated: animated)
        }
    }
    
    
    func showRightButtonsAnimated(animated: Bool) {
        if cellStatus != .right {
            cellScrollView.setContentOffset(contentOffsetForCellStatus(status: .right), animated: animated)
        }
    }
    
    
    func hiddenOtherCells() {
            for cell in containingTableView.visibleCells {
                let newCell = cell as! LGConversionListBaseCell
                if newCell != self && newCell.isKind(of: LGConversionListBaseCell.self) {
                    newCell.hiddenButtonsAnimated(animated: true)
                }
        }
    }
    
    func isButtonsHidden() -> Bool {
        return cellStatus == .center
    }
    
    // MARK: - help
    
    func leftButtonsWidth() -> CGFloat {
        return round(CGRectGetWidth(leftButtonView.frame))
    }
    
    func rightButtonsWidth() -> CGFloat {
        return round(CGRectGetWidth(rightButtonView.frame))
    }
    
    func totalButtonsWidth() -> CGFloat {
        return round(leftButtonsWidth() + rightButtonsWidth())
    }
    
    func contentOffsetForCellStatus(status: LGCellStatus) -> CGPoint {
        var tempPoint = CGPointZero
        
        switch status {
        case .center:
            tempPoint.x = leftButtonsWidth()
        case .right:
            tempPoint.x = totalButtonsWidth()
        case .left:
            tempPoint.x = 0
        }
        return tempPoint
    }
    
    
    func updateCellStatus() {
        if layoutUpdating {
            return
        }
        
        for newStatus in [LGCellStatus.center, LGCellStatus.left, LGCellStatus.right] {
            if CGPointEqualToPoint(cellScrollView.contentOffset, contentOffsetForCellStatus(status: newStatus)) {
                cellStatus = newStatus
                break
            }
        }
        
        var frame = contentView.superview?.convert(contentView.frame, to: self)
        frame?.width = CGRectGetWidth(self.frame)
        
        leftConstraint.constant = max(0, CGRectGetMinX(frame!) - CGRectGetMinX(self.frame))
        rightConstraint.constant = min(0, CGRectGetMaxX(frame!) - CGRectGetMaxX(self.frame))
        
        if self.isEditing {
            leftConstraint.constant = 0
            cellScrollView.contentOffset = CGPointMake(leftButtonsWidth(), 0)
            cellStatus = .center
        }
        
        leftButtonContainView.isHidden = (leftConstraint.constant == 0)
        rightButtonContainView.isHidden = (rightConstraint.constant == 0)
        
        if self.accessoryType != .none && !self.isEditing {
            let accesory = cellScrollView.superview?.subviews.last
            var accessoryFrame = accesory?.frame
            accessoryFrame!.x = CGRectGetWidth(frame!) - CGRectGetWidth(accessoryFrame!) - CGFloat(15) + CGRectGetMinX(frame!)
            accesory?.frame = accessoryFrame!
        }
        
        if !cellScrollView.isDragging && !cellScrollView.isDecelerating {
            tapGesture.isEnabled = true
            longPressGesture.isEnabled = (cellStatus == .center)
        } else {
            tapGesture.isEnabled = false
            longPressGesture.isEnabled = false
        }
        cellScrollView.isScrollEnabled = !self.isEditing
    }
    
}

extension LGConversionListBaseCell: UIScrollViewDelegate {
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if velocity.x >= 0.5 {
            if cellStatus == .left || rightButtonsWidth() == 0 {
                cellStatus = .center
            } else {
                cellStatus = .right
            }
        } else if velocity.x <= -0.5 {
            if cellStatus == .right || leftButtonsWidth() == 0 {
                cellStatus = .center
            } else {
                cellStatus = .left
            }
        } else {
            let leftThreshold = contentOffsetForCellStatus(status: .left).x + leftButtonsWidth() * 0.8
            let rightThreshold = contentOffsetForCellStatus(status: .right).x - rightButtonsWidth() * 0.8
            
            if targetContentOffset.pointee.x > rightThreshold {
                cellStatus = .right
            } else if targetContentOffset.pointee.x < leftThreshold {
                cellStatus = .left
            } else {
                cellStatus = .center
            }
        }
        
        if cellStatus != .center {
            hiddenOtherCells()
        }
        
        targetContentOffset.pointee = contentOffsetForCellStatus(status: cellStatus)
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        if scrollView.contentOffset.x > leftButtonsWidth() {
            if self.rightButtonsWidth() > 0 {
               // scrollView.contentOffset = CGPointMake(leftButtonsWidth(), 0)
            } else {
                scrollView.contentOffset = CGPointMake(leftButtonsWidth(), 0)
                tapGesture.isEnabled = true
            }
        } else {
            if leftButtonsWidth() > 0 {
              //  scrollView.contentOffset = CGPointMake(leftButtonsWidth(), 0)
            } else {
                scrollView.contentOffset = CGPointZero
                tapGesture.isEnabled = true
            }
        }
        updateCellStatus()
    }
    
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        updateCellStatus()
        
    }
    
    func scrollViewDidEndScrollingAnimation(scrollView: UIScrollView) {
        updateCellStatus()
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            tapGesture.isEnabled = true
        }
    }
}


extension LGConversionListBaseCell {
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == containingTableView.panGestureRecognizer && otherGestureRecognizer == longPressGesture) || (gestureRecognizer == longPressGesture && otherGestureRecognizer == containingTableView.panGestureRecognizer) {
            return true
        } else {
            return false
        }
    }
    
    
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !(touch.view!.isKind(of: UIControl.self))
    }
}



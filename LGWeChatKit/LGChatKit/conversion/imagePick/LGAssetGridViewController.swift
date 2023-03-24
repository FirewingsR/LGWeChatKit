//
//  LGAssetGridViewController.swift
//  LGChatViewController
//
//  Created by jamy on 10/22/15.
//  Copyright © 2015 jamy. All rights reserved.
//

import UIKit
import Photos

private let reuseIdentifier = "girdCell"
private let itemMargin: CGFloat = 5
private let durationTime = 0.3
private let itemSize: CGFloat = 80

class LGAssetGridViewController: UICollectionViewController, UIViewControllerTransitioningDelegate {
    
    let presentController = LGPresentAnimationController()
    let dismissController = LGDismissAnimationController()
    
    var assetsFetchResults: PHFetchResult<AnyObject>! {
        willSet {
            for i in 0...newValue.count - 1 {
                let asset = newValue[i] as! PHAsset
                let assetModel = LGAssetModel(asset: asset, select: false)
                self.assetModels.append(assetModel)
            }
        }
    }
    
    var toolBar: LGAssetToolView!
    var assetViewCtrl: LGAssetViewController!
    var assetModels = [LGAssetModel]()
    var selectedInfo: NSMutableArray?
    var previousPreRect: CGRect!
    
    lazy var imageManager: PHCachingImageManager = {
            return PHCachingImageManager()
        }()
    
    
    init() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSizeMake(itemSize, itemSize)
        layout.minimumInteritemSpacing = itemMargin
        layout.minimumLineSpacing = itemMargin
        layout.sectionInset = UIEdgeInsets(top: itemMargin, left: itemMargin, bottom: itemMargin, right: itemMargin)
        super.init(collectionViewLayout: layout)
        self.collectionView?.collectionViewLayout = layout
        collectionView?.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
    }
    
    override init(collectionViewLayout layout: UICollectionViewLayout) {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView!.backgroundColor = UIColor.white
        // Register cell classes
        self.collectionView!.register(LGAssertGridViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        previousPreRect = CGRectZero
        toolBar = LGAssetToolView(leftTitle: "预览", leftSelector: "preView", rightSelector: "send", parent: self)
        toolBar.frame = CGRectMake(0, view.bounds.height - 50, view.bounds.width, 50)
        view.addSubview(toolBar)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        toolBar.selectCount = 0
 
        for assetModel in assetModels {
            if assetModel.select {
                toolBar.addSelectCount = 1
            }
        }
        collectionView?.reloadData()
    }
    
    func preView() {
        let assetCtrl = LGAssetViewController()
        assetCtrl.assetModels = assetModels
        self.navigationController?.pushViewController(assetCtrl, animated: true)
    }
    
    func send() {
        navigationController?.viewControllers[0].dismiss(animated: true, completion: nil)
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.selectedIndexPath = assetViewCtrl.currentIndex
        return dismissController
    }
    
    func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return presentController
    }
}

extension LGAssetGridViewController {
    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return assetModels.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! LGAssertGridViewCell
        
        let asset = assetModels[indexPath.row].asset
        cell.assetModel = assetModels[indexPath.row]
        cell.assetIdentifier = asset.localIdentifier
    
        cell.selectIndicator.tag = indexPath.row
        if assetModels[indexPath.row].select {
            cell.buttonSelect = true
        } else {
            cell.buttonSelect = false
        }
        cell.selectIndicator.addTarget(self, action: "selectButton:", for: .touchUpInside)
        
        let scale = UIScreen.main.scale
        imageManager.requestImage(for: asset, targetSize: CGSizeMake(itemSize * scale, itemSize * scale), contentMode: .aspectFill, options: nil) { (image, _:[AnyHashable : Any]?) -> Void in
            if cell.assetIdentifier == asset.localIdentifier {
                cell.imageView.image = image
            }
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let assetCtrl = LGAssetViewController()
        self.selectedIndexPath = indexPath
        assetCtrl.assetModels = assetModels
        assetCtrl.selectedInfo = selectedInfo
        assetCtrl.selectIndex = indexPath.row
        self.assetViewCtrl = assetCtrl
        let nav = UINavigationController(rootViewController: assetCtrl)
        nav.transitioningDelegate = self
        self.present(nav, animated: true, completion: nil)
    }
    
    // MARK: cell button selector
    
    func selectButton(button: UIButton) {
        let assetModel = assetModels[button.tag]
        let cell: LGAssertGridViewCell = collectionView?.cellForItem(at: IndexPath(item: button.tag, section: 0)) as! LGAssertGridViewCell
        if button.isSelected == false {
            assetModel.setSelect(isSelect: true)
            toolBar.addSelectCount = 1
            button.isSelected = true
            button.addAnimation(durationTime: durationTime)
            selectedInfo?.add(cell.imageView.image!)
            button.setImage(UIImage(named: "CellBlueSelected"), for: .normal)
        } else {
            button.isSelected = false
            assetModel.setSelect(isSelect: false)
            toolBar.addSelectCount = -1
            selectedInfo?.remove(cell.imageView.image!)
            button.setImage(UIImage(named: "CellGreySelected"), for: .normal)
        }
    }
    
    
    // MARK: update chache asset
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateAssetChache()
    }
    
    func updateAssetChache() {
        let isViewVisible = self.isViewLoaded && self.view.window != nil
        if !isViewVisible {
            return
        }
        
        var preRect = (self.collectionView?.bounds)!
        preRect = CGRectInset(preRect, 0, -0.5 * CGRectGetHeight(preRect))
        
        let delta = abs(preRect.midY - previousPreRect.midY)
        if delta > (collectionView?.bounds.height)! / 3 {
            var addIndexPaths = [IndexPath]()
            var remoeIndexPaths = [IndexPath]()
            
            differentBetweenRect(oldRect: previousPreRect, newRect: preRect, removeHandler: { (removeRect) -> Void in
                remoeIndexPaths.append(contentsOf: self.indexPathInRect(rect: removeRect))
                }, addHandler: { (addRect) -> Void in
                    addIndexPaths.append(contentsOf: self.indexPathInRect(rect: addRect))
            })
            
            imageManager.startCachingImages(for: assetAtIndexPath(indexPaths: addIndexPaths), targetSize: CGSizeMake(itemSize, itemSize), contentMode: .aspectFill, options: nil)
            imageManager.stopCachingImages(for: assetAtIndexPath(indexPaths: remoeIndexPaths), targetSize: CGSizeMake(itemSize, itemSize), contentMode: .aspectFill, options: nil)
        }
    }
    
    func assetAtIndexPath(indexPaths: [IndexPath]) -> [PHAsset] {
        if indexPaths.count == 0 {
            return []
        }
        var assets = [PHAsset]()
        for indexPath in indexPaths {
            assets.append(assetsFetchResults[indexPath.row] as! PHAsset)
        }
        
        return assets
    }
    
    
    func indexPathInRect(rect: CGRect) -> [IndexPath] {
        let allAttributes = collectionView?.collectionViewLayout.layoutAttributesForElements(in: rect)
        if allAttributes?.count == 0 {
            return []
        }
        var indexPaths = [IndexPath]()
        for layoutAttribute in allAttributes! {
            indexPaths.append(layoutAttribute.indexPath)
        }
        
        return indexPaths
    }
    
    func differentBetweenRect(oldRect: CGRect, newRect: CGRect, removeHandler: (CGRect)->Void, addHandler:(CGRect)->Void) {
        if CGRectIntersectsRect(newRect, oldRect) {
            let oldMaxY = CGRectGetMaxY(oldRect)
            let oldMinY = CGRectGetMinY(oldRect)
            let newMaxY = CGRectGetMaxY(newRect)
            let newMinY = CGRectGetMinY(newRect)
            
            if newMaxY > oldMaxY {
                let rectToAdd = CGRectMake(newRect.x, oldMaxY, newRect.width, newMaxY - oldMaxY)
                addHandler(rectToAdd)
            }
            
            if oldMinY > newMinY {
                let rectToAdd = CGRectMake(newRect.x, newMinY, newRect.width, oldMinY - newMinY)
                addHandler(rectToAdd)
            }
            
            if newMaxY < oldMaxY {
                let rectToMove = CGRectMake(newRect.x, newMaxY, newRect.width, oldMaxY - newMaxY)
                removeHandler(rectToMove)
            }
            
            if oldMinY < newMinY {
                let rectToMove = CGRectMake(newRect.x, oldMinY, newRect.width, newMinY - oldMinY)
                removeHandler(rectToMove)
            }
        } else {
            addHandler(newRect)
            removeHandler(oldRect)
        }
    }
}


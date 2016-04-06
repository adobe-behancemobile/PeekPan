/******************************************************************************
 *
 * ADOBE CONFIDENTIAL
 * ___________________
 *
 * Copyright 2016 Adobe Systems Incorporated
 * All Rights Reserved.
 *
 * This file is licensed to you under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License. You may obtain a copy
 * of the License at http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 * OF ANY KIND, either express or implied. See the License for the specific language
 * governing permissions and limitations under the License.
 ******************************************************************************/

import UIKit

class ContentPreviewCollectionViewController : BaseCollectionViewController, UIViewControllerPreviewingDelegate, PeekPanCoordinatorDataSource {
    var imageTableVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ImageTableViewController") as! ImageTableViewController
    var imageCollectionItems = [ImageCollectionItem]()
    
    var peekPanCoordinator: PeekPanCoordinator!
    
    var demoPeekPanCoordinator: PeekPanCoordinator!
    var pointerView: UIView!
    var rangeView: UIView!
    var valueView: UIView!
    var demoViewContainer: UIView!
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if imageTableVC.view == nil {
            imageTableVC.viewDidLoad()
        }
        setupImages()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        setupDemo()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        demoViewContainer.removeFromSuperview()
        pointerView.removeFromSuperview()
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: collectionView)
                peekPanCoordinator = PeekPanCoordinator(sourceView: collectionView)
                
                peekPanCoordinator.delegate = imageTableVC
                peekPanCoordinator.dataSource = imageTableVC
            }
        }
    }
    
    // MARK: Methods
    
    func setupDemo() {
        demoPeekPanCoordinator = PeekPanCoordinator(sourceView: collectionView)
        demoPeekPanCoordinator.delegate = self
        demoPeekPanCoordinator.dataSource = self
        
        demoViewContainer = UIView(frame: CGRectMake(PeekPanCoordinator.DefaultHorizontalMargin, 0.0, demoPeekPanCoordinator.maximumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin, CGRectGetHeight(view.bounds)))
        demoViewContainer.clipsToBounds = true
        demoViewContainer.userInteractionEnabled = false
        demoViewContainer.alpha = 0
        
        rangeView = UIView(frame: CGRectMake(0.0, 0.0, 1.0, CGRectGetHeight(view.bounds)))
        rangeView.alpha = 0.2
        rangeView.backgroundColor = .greenColor()
        demoViewContainer.addSubview(rangeView)
        
        valueView = UIView(frame: CGRectMake(0.0, 0.0, 1.0, CGRectGetHeight(view.bounds)))
        valueView.alpha = 0.4
        valueView.backgroundColor = .greenColor()
        demoViewContainer.addSubview(valueView)
        
        pointerView = UIView(frame: CGRectMake(0.0, 0.0, 1.0, CGRectGetHeight(view.bounds)))
        pointerView.backgroundColor = .redColor()
        pointerView.alpha = 0
        
        if let app = UIApplication.sharedApplication().delegate as? AppDelegate, let window = app.window {
            window.addSubview(demoViewContainer)
            window.addSubview(pointerView)
        }
    }
    
    func setupImages() {
        for i in 0..<Int(cellNumStepper.maximumValue) {
            let projectIndex = i%3 + 1
            let projectImage = UIImage(named: "proj" + String(projectIndex))!
            var content = [ImageTableItem]()
            content.append(ImageTableItem(image: projectImage, text: "proj\(i+1)"))
            for j in 1...3 {
                let contentImageName = "cont" + String(projectIndex) + "-" + String(j)
                content.append(ImageTableItem(image: UIImage(named: contentImageName)!, text: "cont\(i+1)-\(j)"))
            }
            thumbnailItems.append(projectImage)
            imageCollectionItems.append(ImageCollectionItem(projId: i, contentItems: content))
        }
    }
    
    override func toggleOverlay(sender: UISwitch) {
        demoViewContainer.hidden = !sender.on
        pointerView.hidden = !sender.on
    }
    
    // MARK: PeekPanCoordinatorDataSource
    
    func maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int {
        return imageTableVC.imageTableItems.count - 1
    }
    
    func shouldStartFromMinimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Bool {
        return true
    }
    
    // MARK: PeekPanCoordinatorDelegate
    
    func peekPanCoordinatorBegan(peekPanCoordinator: PeekPanCoordinator) {
        pointerView.frame = CGRectMake(peekPanCoordinator.currentPoint.x, 0.0, 1.0, CGRectGetHeight(view.bounds))
        
        let minPointInMargins = peekPanCoordinator.minimumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        let maxPointInMargins = peekPanCoordinator.maximumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        
        let segmentWidth = (peekPanCoordinator.maximumPoint.x - peekPanCoordinator.minimumPoint.x) / CGFloat(imageTableVC.imageTableItems.count)
        
        rangeView.frame = CGRectMake(minPointInMargins, 0.0, maxPointInMargins - minPointInMargins, CGRectGetHeight(view.bounds))
        valueView.frame = CGRectMake(minPointInMargins, 0.0, CGFloat(peekPanCoordinator.currentIndex + 1) * segmentWidth, CGRectGetHeight(view.bounds))
        
        demoViewContainer.alpha = 1
        pointerView.alpha = 1
    }
    
    func peekPanCoordinatorEnded(peekPanCoordinator: PeekPanCoordinator) {
        demoViewContainer.alpha = 0
        pointerView.alpha = 0
    }
    
    func peekPanCoordinatorUpdated(peekPanCoordinator: PeekPanCoordinator) {
        pointerView.frame = CGRectMake(peekPanCoordinator.currentPoint.x, 0.0, 1.0, CGRectGetHeight(view.bounds))
        
        let minPointInMargins = peekPanCoordinator.minimumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        let maxPointInMargins = peekPanCoordinator.maximumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        
        let segmentWidth = (peekPanCoordinator.maximumPoint.x - peekPanCoordinator.minimumPoint.x) / CGFloat(imageTableVC.imageTableItems.count)
        
        rangeView.frame = CGRectMake(minPointInMargins, 0.0, maxPointInMargins - minPointInMargins, CGRectGetHeight(view.bounds))
        valueView.frame = CGRectMake(minPointInMargins, 0.0, CGFloat(peekPanCoordinator.currentIndex + 1) * segmentWidth, CGRectGetHeight(view.bounds))
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let item = imageCollectionItems[indexPath.row]
        imageTableVC.imageCollectionItem = item
        navigationController?.showViewController(imageTableVC, sender: self)
    }
    
    // MARK: UIViewControllerPreviewingDelegate
    
    @available (iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItemAtPoint(location) else { return nil }
        guard let cell = collectionView.cellForItemAtIndexPath(indexPath) else { return nil }
        
        previewingContext.sourceRect = cell.frame
        
        let item = imageCollectionItems[indexPath.row]
        imageTableVC.imageCollectionItem = item
        
        peekPanCoordinator.setup(at: 0)
        demoPeekPanCoordinator.setup(at: 0)
        
        return imageTableVC
    }
    
    @available (iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        peekPanCoordinator.end(true)
        demoPeekPanCoordinator.end(true)
        navigationController?.showViewController(imageTableVC, sender: self)
    }
}
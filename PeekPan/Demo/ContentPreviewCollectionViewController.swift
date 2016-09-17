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
    var imageTableVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ImageTableViewController") as! ImageTableViewController
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupDemo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        demoViewContainer.removeFromSuperview()
        pointerView.removeFromSuperview()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: collectionView)
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
        
        demoViewContainer = UIView(frame: CGRect(x: PeekPanCoordinator.DefaultHorizontalMargin, y: 0.0, width: demoPeekPanCoordinator.maximumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin, height: view.bounds.height))
        demoViewContainer.clipsToBounds = true
        demoViewContainer.isUserInteractionEnabled = false
        demoViewContainer.alpha = 0
        
        rangeView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: view.bounds.height))
        rangeView.alpha = 0.2
        rangeView.backgroundColor = .green
        demoViewContainer.addSubview(rangeView)
        
        valueView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: view.bounds.height))
        valueView.alpha = 0.4
        valueView.backgroundColor = .green
        demoViewContainer.addSubview(valueView)
        
        pointerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: view.bounds.height))
        pointerView.backgroundColor = .red
        pointerView.alpha = 0
        
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
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
    
    override func toggleOverlay(_ sender: UISwitch) {
        demoViewContainer.isHidden = !sender.isOn
        pointerView.isHidden = !sender.isOn
    }
    
    // MARK: PeekPanCoordinatorDataSource
    
    func maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int {
        return imageTableVC.imageTableItems.count - 1
    }
    
    func shouldStartFromMinimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Bool {
        return true
    }
    
    // MARK: PeekPanCoordinatorDelegate
    
    func peekPanCoordinatorBegan(_ peekPanCoordinator: PeekPanCoordinator) {
        pointerView.frame = CGRect(x: peekPanCoordinator.currentPoint.x, y: 0.0, width: 1.0, height: view.bounds.height)
        
        let minPointInMargins = peekPanCoordinator.minimumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        let maxPointInMargins = peekPanCoordinator.maximumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        
        let segmentWidth = (peekPanCoordinator.maximumPoint.x - peekPanCoordinator.minimumPoint.x) / CGFloat(imageTableVC.imageTableItems.count)
        
        rangeView.frame = CGRect(x: minPointInMargins, y: 0.0, width: maxPointInMargins - minPointInMargins, height: view.bounds.height)
        valueView.frame = CGRect(x: minPointInMargins, y: 0.0, width: CGFloat(peekPanCoordinator.currentIndex + 1) * segmentWidth, height: view.bounds.height)
        
        demoViewContainer.alpha = 1
        pointerView.alpha = 1
    }
    
    func peekPanCoordinatorEnded(_ peekPanCoordinator: PeekPanCoordinator) {
        demoViewContainer.alpha = 0
        pointerView.alpha = 0
    }
    
    func peekPanCoordinatorUpdated(_ peekPanCoordinator: PeekPanCoordinator) {
        pointerView.frame = CGRect(x: peekPanCoordinator.currentPoint.x, y: 0.0, width: 1.0, height: view.bounds.height)
        
        let minPointInMargins = peekPanCoordinator.minimumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        let maxPointInMargins = peekPanCoordinator.maximumPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        
        let segmentWidth = (peekPanCoordinator.maximumPoint.x - peekPanCoordinator.minimumPoint.x) / CGFloat(imageTableVC.imageTableItems.count)
        
        rangeView.frame = CGRect(x: minPointInMargins, y: 0.0, width: maxPointInMargins - minPointInMargins, height: view.bounds.height)
        valueView.frame = CGRect(x: minPointInMargins, y: 0.0, width: CGFloat(peekPanCoordinator.currentIndex + 1) * segmentWidth, height: view.bounds.height)
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
        let item = imageCollectionItems[(indexPath as NSIndexPath).row]
        imageTableVC.imageCollectionItem = item
        navigationController?.show(imageTableVC, sender: self)
    }
    
    // MARK: UIViewControllerPreviewingDelegate
    
    @available (iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        
        previewingContext.sourceRect = cell.frame
        
        let item = imageCollectionItems[(indexPath as NSIndexPath).row]
        imageTableVC.imageCollectionItem = item
        
        peekPanCoordinator.setup(at: 0)
        demoPeekPanCoordinator.setup(at: 0)
        
        return imageTableVC
    }
    
    @available (iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        peekPanCoordinator.end(true)
        demoPeekPanCoordinator.end(true)
        navigationController?.show(imageTableVC, sender: self)
    }
}

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

class OnScreenCollectionViewController : BaseCollectionViewController, UIViewControllerPreviewingDelegate, PeekPanViewControllerDelegate, PeekPanCoordinatorDataSource {
    var peekPanCoordinator: PeekPanCoordinator!
    let peekPanVC = PeekPanViewController()

    var pointerView: UIView!
    var highlightedView: UIView!
    var leftView: UIView!
    var rightView: UIView!
    var demoViewContainer: UIView!
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for i in 0..<Int(cellNumStepper.maximumValue) {
            thumbnailItems.append(getImage(from: "\(i)" as NSString))
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        demoViewContainer.removeFromSuperview()
        pointerView.removeFromSuperview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        setupDemo()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: collectionView)
                peekPanCoordinator = PeekPanCoordinator(sourceView: collectionView)
                peekPanCoordinator.delegate = peekPanVC
                peekPanCoordinator.dataSource = self
                peekPanVC.delegate = self
            }
        }
    }
    
    // MARK: Methods
    
    func setupDemo() {
        demoViewContainer = UIView(frame: CGRect(x: PeekPanCoordinator.DefaultHorizontalMargin, y: 0.0, width: view.bounds.width - 2*PeekPanCoordinator.DefaultHorizontalMargin, height: view.bounds.height))
        demoViewContainer.clipsToBounds = true
        demoViewContainer.isUserInteractionEnabled = false
        demoViewContainer.alpha = 0
        
        highlightedView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: view.bounds.height))
        highlightedView.alpha = 0.6
        highlightedView.backgroundColor = .green
        demoViewContainer.addSubview(highlightedView)
        
        leftView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: view.bounds.height))
        leftView.alpha = 0.2
        leftView.backgroundColor = .green
        demoViewContainer.addSubview(leftView)
        
        rightView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: view.bounds.height))
        rightView.alpha = 0.2
        rightView.backgroundColor = .green
        demoViewContainer.addSubview(rightView)
        
        pointerView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 1.0, height: view.bounds.height))
        pointerView.backgroundColor = .red
        pointerView.alpha = 0
        
        if let app = UIApplication.shared.delegate as? AppDelegate, let window = app.window {
            window.addSubview(demoViewContainer)
            window.addSubview(pointerView)
        }
    }
    
    override func cellNumChanged(_ sender: UIStepper) {
        super.cellNumChanged(sender)
        peekPanCoordinator.reloadData()
    }
    
    override func toggleOverlay(_ sender: UISwitch) {
        demoViewContainer.isHidden = !sender.isOn
        pointerView.isHidden = !sender.isOn
    }
    
    // MARK: PeekPanCoordinatorDataSource
    
    func maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int {
        return Int(cellNumStepper.value) - 1
    }
    
    func shouldStartFromMinimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Bool {
        return false
    }
    
    // MARK: PeekPanControllerDelegate
    
    func peekPanCoordinatorBegan(_ peekPanCoordinator: PeekPanCoordinator) {
        
        let startingPointInMargins = peekPanCoordinator.startingPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        
        let segmentWidth = demoViewContainer.bounds.width / CGFloat(min(thumbnailItems.count, PeekPanCoordinator.DefaultPeekRange))
        let deltaIndex = peekPanCoordinator.currentIndex - peekPanCoordinator.startingIndex
        if deltaIndex == 0 {
            highlightedView.frame = CGRect(x: startingPointInMargins - segmentWidth/2, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        else if deltaIndex > 0 {
            highlightedView.frame = CGRect(x: startingPointInMargins - segmentWidth/2 + CGFloat(deltaIndex)*segmentWidth, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        else {
            highlightedView.frame = CGRect(x: startingPointInMargins - segmentWidth/2 + CGFloat(deltaIndex)*segmentWidth, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        if peekPanCoordinator.currentIndex != 0 {
            leftView.frame = CGRect(x: highlightedView.frame.minX - segmentWidth, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        else {
            leftView.frame.size.width = 0
        }
        if peekPanCoordinator.currentIndex != peekPanCoordinator.maximumIndex {
            rightView.frame = CGRect(x: highlightedView.frame.maxX, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        else {
            rightView.frame.size.width = 0
        }
        
        demoViewContainer.alpha = 1
        pointerView.alpha = 1
    }
    
    func peekPanCoordinatorEnded(_ peekPanCoordinator: PeekPanCoordinator) {
        demoViewContainer.alpha = 0
        pointerView.alpha = 0
    }
    
    func peekPanCoordinatorUpdated(_ peekPanCoordinator: PeekPanCoordinator) {
        pointerView.frame = CGRect(x: peekPanCoordinator.currentPoint.x, y: 0.0, width: 1.0, height: view.bounds.height)
        
        let startingPointInMargins = peekPanCoordinator.startingPoint.x - PeekPanCoordinator.DefaultHorizontalMargin
        
        let segmentWidth = demoViewContainer.bounds.width / CGFloat(min(Int(cellNumStepper.value), PeekPanCoordinator.DefaultPeekRange))
        let deltaIndex = peekPanCoordinator.currentIndex - peekPanCoordinator.startingIndex
        if deltaIndex == 0 {
            highlightedView.frame = CGRect(x: startingPointInMargins - segmentWidth/2, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        else if deltaIndex > 0 {
            highlightedView.frame = CGRect(x: startingPointInMargins - segmentWidth/2 + CGFloat(deltaIndex)*segmentWidth, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        else {
            highlightedView.frame = CGRect(x: startingPointInMargins - segmentWidth/2 + CGFloat(deltaIndex)*segmentWidth, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        if peekPanCoordinator.currentIndex != 0 {
            leftView.frame = CGRect(x: highlightedView.frame.minX - segmentWidth, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        else {
            leftView.frame.size.width = 0
        }
        if peekPanCoordinator.currentIndex != peekPanCoordinator.maximumIndex {
            rightView.frame = CGRect(x: highlightedView.frame.maxX, y: 0.0, width: segmentWidth, height: view.bounds.height)
        }
        else {
            rightView.frame.size.width = 0
        }
    }
    
    // MARK: PeekPanViewControllerDelegate
    
    func view(for peekPanViewController: PeekPanViewController, atIndex index: Int) -> UIView? {
        return UIImageView(image: thumbnailItems[index])
    }
    
    // MARK: UIViewControllerPreviewingDelegate
    
    @available (iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView.indexPathForItem(at: location) else { return nil }
        guard let cell = collectionView.cellForItem(at: indexPath) else { return nil }
        
        previewingContext.sourceRect = cell.frame
        
        peekPanCoordinator.setup(at: (indexPath as NSIndexPath).item)
        
        return peekPanVC
    }
    
    @available (iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        peekPanCoordinator.end(true)
    }
}

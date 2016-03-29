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
import Foundation

class DemoViewController : UIViewController, UIViewControllerPreviewingDelegate, PeekPanCoordinatorDelegate, PeekPanCoordinatorDataSource {
    var peekPanCoordinator: PeekPanCoordinator!
    
    @IBOutlet var percentageLabel: UILabel!
    
    @IBOutlet var redView: UIView!
    @IBOutlet var greenView: UIView!
    @IBOutlet var yellowView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        redView = UIView(frame: CGRectMake(0.0, 0.0, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds)))
        greenView = UIView(frame: CGRectMake(0.0, 0.0, 0.0, CGRectGetHeight(view.bounds)))
        yellowView = UIView(frame: CGRectMake(0.0, 0.0, 0.0, CGRectGetHeight(view.bounds)))
        
        redView.backgroundColor = .redColor()
        greenView.backgroundColor = .greenColor()
        yellowView.backgroundColor = .yellowColor()
        
        view.addSubview(redView)
        view.addSubview(greenView)
        view.addSubview(yellowView)
        yellowView.addSubview(percentageLabel)
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: view)
                peekPanCoordinator = PeekPanCoordinator(sourceView: view)
                peekPanCoordinator.delegate = self
                peekPanCoordinator.dataSource = self
            }
        }
    }
    
    // MARK: PeekPanCoordinatorDataSource
    
    func maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int {
        return 0
    }
    
    func shouldStartFromMinimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Bool {
        return true
    }
    
    // MARK: PeekPanCoordinatorDelegate
    
    func peekPanCoordinatorBegan(peekPanCoordinator: PeekPanCoordinator) {
        greenView.frame.origin.x = peekPanCoordinator.startingPoint.x
        greenView.frame.size.width = CGRectGetWidth(peekPanCoordinator.sourceView.bounds) - peekPanCoordinator.startingPoint.x
        yellowView.frame.origin.x = peekPanCoordinator.startingPoint.x
    }
    
    func peekPanCoordinatorEnded(peekPanCoordinator: PeekPanCoordinator) {
        greenView.frame.size.width = 0.0
        yellowView.frame.size.width = 0.0
        percentageLabel.text = ""
    }
    
    func peekPanCoordinatorUpdated(peekPanCoordinator: PeekPanCoordinator) {
        greenView.frame.origin.x = peekPanCoordinator.minimumPoint.x
        greenView.frame.size.width = peekPanCoordinator.maximumPoint.x - peekPanCoordinator.minimumPoint.x
        yellowView.frame.origin.x = peekPanCoordinator.minimumPoint.x
        yellowView.frame.size.width = peekPanCoordinator.percentage * (peekPanCoordinator.maximumPoint.x - peekPanCoordinator.minimumPoint.x);
        percentageLabel.text = String(format: "%.2f", Double(peekPanCoordinator.percentage))
        percentageLabel.sizeToFit()
        percentageLabel.frame.origin = CGPointMake(0.0, CGRectGetHeight(yellowView.bounds)/2)
    }
    
    // MARK: UIViewControllerPreviewingDelegate
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        peekPanCoordinator.setup()
        return nil
    }
    
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        peekPanCoordinator.end(true)
    }
}
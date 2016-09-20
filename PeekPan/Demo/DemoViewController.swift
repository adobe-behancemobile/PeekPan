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
        
        redView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: view.bounds.width, height: view.bounds.height))
        greenView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: view.bounds.height))
        yellowView = UIView(frame: CGRect(x: 0.0, y: 0.0, width: 0.0, height: view.bounds.height))
        
        redView.backgroundColor = .red
        greenView.backgroundColor = .green
        yellowView.backgroundColor = .yellow
        
        view.addSubview(redView)
        view.addSubview(greenView)
        view.addSubview(yellowView)
        yellowView.addSubview(percentageLabel)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: view)
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
    
    func peekPanCoordinatorBegan(_ peekPanCoordinator: PeekPanCoordinator) {
        greenView.frame.origin.x = peekPanCoordinator.startingPoint.x
        greenView.frame.size.width = peekPanCoordinator.sourceView.bounds.width - peekPanCoordinator.startingPoint.x
        yellowView.frame.origin.x = peekPanCoordinator.startingPoint.x
    }
    
    func peekPanCoordinatorEnded(_ peekPanCoordinator: PeekPanCoordinator) {
        greenView.frame.size.width = 0.0
        yellowView.frame.size.width = 0.0
        percentageLabel.text = ""
    }
    
    func peekPanCoordinatorUpdated(_ peekPanCoordinator: PeekPanCoordinator) {
        greenView.frame.origin.x = peekPanCoordinator.minimumPoint.x
        greenView.frame.size.width = peekPanCoordinator.maximumPoint.x - peekPanCoordinator.minimumPoint.x
        yellowView.frame.origin.x = peekPanCoordinator.minimumPoint.x
        yellowView.frame.size.width = peekPanCoordinator.percentage * (peekPanCoordinator.maximumPoint.x - peekPanCoordinator.minimumPoint.x);
        percentageLabel.text = String(format: "%.2f", Double(peekPanCoordinator.percentage))
        percentageLabel.sizeToFit()
        percentageLabel.frame.origin = CGPoint(x: 0.0, y: yellowView.bounds.height/2)
    }
    
    // MARK: UIViewControllerPreviewingDelegate
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        peekPanCoordinator.setup()
        return nil
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        peekPanCoordinator.end(true)
    }
}

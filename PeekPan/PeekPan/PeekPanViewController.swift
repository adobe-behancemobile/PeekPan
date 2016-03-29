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

@objc public protocol PeekPanViewControllerDelegate : PeekPanCoordinatorDelegate {
    optional func view(for peekPanViewController: PeekPanViewController, atIndex index: Int) -> UIView?
    optional func view(for peekPanViewController: PeekPanViewController, atPercentage percentage: CGFloat) -> UIView?
}

public class PeekPanViewController : UIViewController, PeekPanCoordinatorDelegate {
    public static var currentViewController: PeekPanViewController?
    
    public weak var delegate: PeekPanViewControllerDelegate?
    public var identifier: String?
    public var contentObject: AnyObject?
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: NSBundle!) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func reset() {
        identifier = nil
        contentObject = nil
    }
    
    public func setup() {
        setup(at: CGSizeZero)
    }
    
    public func setup(at size: CGSize) {
        reset()
        self.dynamicType.currentViewController = self
        updateView(for: size)
    }
    
    public func updateView() {
        updateView(for: CGSizeZero)
    }
    
    public func updateView(for size: CGSize) {
        if size == CGSizeZero {
            view.sizeToFit()
            preferredContentSize = view.bounds.size
        }
        else {
            preferredContentSize = size
        }
    }
    
    // MARK: PeekPanCoordinatorDelegate
    
    public func peekPanCoordinatorBegan(peekPanCoordinator: PeekPanCoordinator) {
        delegate?.peekPanCoordinatorBegan?(peekPanCoordinator)
    }
    
    public func peekPanCoordinatorUpdated(peekPanCoordinator: PeekPanCoordinator) {
        delegate?.peekPanCoordinatorUpdated?(peekPanCoordinator)
        guard let viewAtPercentage = delegate?.view?(for: self, atPercentage: peekPanCoordinator.percentage) else { return }
        view = viewAtPercentage
        view.sizeToFit()
        preferredContentSize = view.bounds.size
    }
    
    public func peekPanCoordinator(peekPanCoordinator: PeekPanCoordinator, movedTo index: Int) {
        delegate?.peekPanCoordinator?(peekPanCoordinator, movedTo: index)
        guard let viewAtIndex = delegate?.view?(for: self, atIndex: index) else { return }
        view = viewAtIndex
        view.sizeToFit()
        preferredContentSize = view.bounds.size
    }
    
    public func peekPanCoordinatorEnded(peekPanCoordinator: PeekPanCoordinator) {
        delegate?.peekPanCoordinatorEnded?(peekPanCoordinator)
        reset()
    }
}

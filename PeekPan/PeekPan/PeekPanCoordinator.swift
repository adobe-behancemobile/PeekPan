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

@objc public protocol PeekPanCoordinatorDelegate {
    optional func peekPanCoordinatorBegan(peekPanCoordinator: PeekPanCoordinator)
    optional func peekPanCoordinatorUpdated(peekPanCoordinator: PeekPanCoordinator)
    optional func peekPanCoordinatorEnded(peekPanCoordinator: PeekPanCoordinator)
    optional func peekPanCoordinator(peekPanCoordinator: PeekPanCoordinator, movedTo index: Int)
}

@objc public protocol PeekPanCoordinatorDataSource {
    /**
     Sets the  maximum index of a range of indices. The maximum index has to be greater than or equal to the minimum index for "peekPanCoordinator:movedTo:" to work. Method is called upon setup.
     
     Returns: Default is 0.
     */
    func maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int
    
    /**
     Have the minimum point begin at the starting point. Method is called upon setup.
     
     Returns: Default is false.
     */
    func shouldStartFromMinimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Bool
    
    /**
     Sets the  minimum index of a range of indices. The maximum index has to be greater than or equal to the minimum index for "peekPanCoordinator:movedTo:" to work. Method is called upon setup.
     
     Returns: Default is 0.
     */
    optional func minimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int
    
    /**
     Fixes the minimum point at a given location. Method is called when the gesture recognizer begins tracking.
     
     Returns: Return CGPointZero to leave unfixed.
     */
    optional func minimumPoint(for peekPanCoordinator: PeekPanCoordinator) -> CGPoint
    
    /**
     Fixes the maximum point at a given location. Method is called when the gesture recognizer begins tracking.
     
     Returns: Return CGPointZero to leave unfixed.
     */
    optional func maximumPoint(for peekPanCoordinator: PeekPanCoordinator) -> CGPoint
    
    /**
     The maximum amount of indices the user can pan through. Method is called upon setup.
     
     Returns: Return an integer less than 1 to set to default. Default is 8.
     */
    optional func maxPeekRange(for peekPanCoordinator: PeekPanCoordinator) -> Int
    
    /**
     The horizontal margins that are inset from the source view's left and right edges. Method is called upon setup.
     
     Returns: Return a float less than 0.0 to set to default. Default is 40.0.
     */
    optional func horizontalMargin(for peekPanCoordinator: PeekPanCoordinator) -> CGFloat
}

/**
 Used to represent the current state of PeekPanCoordinator.
 
 - Initialized:  Has been initialized or reset.
 - Ready:        Finished setup and is ready to start tracking the user's touch location.
 - Peeking:      Tracking user's touch location while the Peek preview is displayed.
 - Popped:       Stopped tracking due to the user committing the previewed view controller.
 - Ended:        Stopped tracking due to the user releasing touch.
 */
@objc public enum PeekPanState : Int {
    case Initialized
    case Ready
    case Peeking
    case Popped
    case Ended
}

public class PeekPanCoordinator : NSObject, UIGestureRecognizerDelegate {
    // MARK: Constants
    
    public static let DefaultPeekRange = 8
    public static let DefaultHorizontalMargin: CGFloat = 40.0
    
    // MARK: Properties
    
    public weak static var currentCoordinator: PeekPanCoordinator?
    
    public private(set) weak var sourceView: UIView!
    public private(set) var state: PeekPanState = .Initialized
    public weak var delegate: PeekPanCoordinatorDelegate?
    public weak var dataSource: PeekPanCoordinatorDataSource?
    private var gestureRecognizer: PeekPanGestureRecognizer!
    
    private var startFromMinimum = false
    private var peekRange = DefaultPeekRange
    private var horizontalMargin = DefaultHorizontalMargin
    private var isUsingDelegateMinPoint = false
    private var isUsingDelegateMaxPoint = false
    
    public private(set) var startingIndex = 0
    public private(set) var previousIndex = 0
    public private(set) var currentIndex = 0
    public private(set) var minimumIndex = 0
    public private(set) var maximumIndex = 0
    
    public private(set) var startingPoint = CGPointZero
    public private(set) var currentPoint = CGPointZero
    public private(set) var minimumPoint = CGPointZero
    public private(set) var maximumPoint = CGPointZero
    
    public var leftMarginPoint: CGPoint {
        return CGPointMake(horizontalMargin, currentPoint.y)
    }
    public var rightMarginPoint: CGPoint {
        return CGPointMake(CGRectGetWidth(sourceView.bounds) - horizontalMargin, currentPoint.y)
    }
    
    /// Value from 0.0 to 1.0
    public var percentage: CGFloat {
        return max(min((currentPoint.x - minimumPoint.x) / (maximumPoint.x - minimumPoint.x), 1.0), 0.0)
    }
    
    // MARK: Init
    
    required public init(sourceView view: UIView!) {
        super.init()
        
        self.sourceView = view
        self.gestureRecognizer = PeekPanGestureRecognizer(target: self, action: #selector(PeekPanCoordinator.handlePeekPanGesture(_:)))
        self.gestureRecognizer.cancelsTouchesInView = false
        self.gestureRecognizer.delegate = self
        sourceView.addGestureRecognizer(self.gestureRecognizer)
        
        reset()
    }
    
    deinit {
        if sourceView != nil {
            sourceView.removeGestureRecognizer(gestureRecognizer)
        }
        gestureRecognizer.delegate = nil
    }
    
    // MARK: Setup
    
    public func setup() {
        setup(at: 0)
    }
    
    public func setup(at index: Int) {
        reset()
        
        minimumIndex = dataSource?.minimumIndex?(for: self) ?? 0
        maximumIndex = dataSource?.maximumIndex(for: self) ?? 0
        startFromMinimum = dataSource?.shouldStartFromMinimumIndex(for: self) ?? false
        
        let numOfIndices = maximumIndex - minimumIndex + 1
        if let delegatePeekRange = dataSource?.maxPeekRange?(for: self)
            where delegatePeekRange > 0 {
            peekRange = max(min(delegatePeekRange, numOfIndices), 1)
        }
        else {
            peekRange = max(min(self.dynamicType.DefaultPeekRange, numOfIndices), 1)
        }
        
        if let delegateHorizontalMargin = dataSource?.horizontalMargin?(for: self)
            where delegateHorizontalMargin >= 0.0 {
            horizontalMargin = delegateHorizontalMargin
        }
        else {
            horizontalMargin = self.dynamicType.DefaultHorizontalMargin
        }
        
        startingIndex = startFromMinimum ? minimumIndex : index
        currentIndex = minimumIndex - 1;
        previousIndex = minimumIndex - 1;
        
        self.dynamicType.currentCoordinator = self
        
        state = .Ready
    }
    
    private func reset() {
        state = .Initialized
        
        startFromMinimum = false
        peekRange = self.dynamicType.DefaultPeekRange
        horizontalMargin = self.dynamicType.DefaultHorizontalMargin
        
        isUsingDelegateMinPoint = false
        isUsingDelegateMaxPoint = false
        
        startingIndex = 0
        previousIndex = 0
        currentIndex = 0
        maximumIndex = 0
        minimumIndex = 0
        
        startingPoint = CGPointZero
        currentPoint = CGPointZero
        minimumPoint = leftMarginPoint
        maximumPoint = rightMarginPoint
    }
    
    // MARK: Gesture Action
    
    @objc private func handlePeekPanGesture(peekPanGestureRecognizer: PeekPanGestureRecognizer) {
        let point = peekPanGestureRecognizer.locationInView(sourceView)
        
        switch peekPanGestureRecognizer.state {
        case .Began, .Changed:
            if state == .Ready {
                state = .Peeking
                begin(at: point)
            }
            else if state == .Peeking {
                update(at: point)
            }
        case .Ended, .Cancelled, .Failed:
            end(false)
        default: break
        }
    }
    
    // MARK: Gesture Action Methods
    
    private func begin(at point: CGPoint) {
        let pointBetweenBoundaries = CGPointMake(max(min(point.x, rightMarginPoint.x), leftMarginPoint.x), point.y)
        
        startingPoint = pointBetweenBoundaries
        currentPoint = pointBetweenBoundaries
        
        setupMinMaxPoints()
        
        updateCurrentIndex(at: pointBetweenBoundaries)
        delegate?.peekPanCoordinatorBegan?(self)
    }
    
    private func update(at point: CGPoint) {
        let pointBetweenBoundaries = CGPointMake(max(min(point.x, rightMarginPoint.x), leftMarginPoint.x), point.y)
        
        currentPoint = pointBetweenBoundaries
        
        // Shift startingPoint if currentPoint is at an index that is out of bounds
        if !startFromMinimum {
            let newIndex = startingIndex + deltaIndex(at: pointBetweenBoundaries)
            if newIndex > maximumIndex {
                startingPoint.x += pointBetweenBoundaries.x - maximumPoint.x
            }
            else if newIndex < minimumIndex {
                startingPoint.x += pointBetweenBoundaries.x - minimumPoint.x
            }
        }
        
        if !isUsingDelegateMinPoint {
            if pointBetweenBoundaries.x < minimumPoint.x {
                minimumPoint.x = pointBetweenBoundaries.x
            }
            if point.y < minimumPoint.y {
                minimumPoint.y = point.y
            }
        }
        if !isUsingDelegateMaxPoint {
            if pointBetweenBoundaries.x > maximumPoint.x {
                maximumPoint.x = pointBetweenBoundaries.x
            }
            if point.y > maximumPoint.y {
                maximumPoint.y = point.y
            }
        }
        
        updateCurrentIndex(at: pointBetweenBoundaries)
        delegate?.peekPanCoordinatorUpdated?(self)
    }
    
    public func end(popped: Bool) {
        state = popped ? .Popped : .Ended
        delegate?.peekPanCoordinatorEnded?(self)
        reset()
        self.dynamicType.currentCoordinator = nil
    }
    
    // Methods
    
    private func updateCurrentIndex(at point: CGPoint) {
        if maximumIndex - minimumIndex >= 0 {
            let newIndex = index(at: point)
            if newIndex != currentIndex {
                previousIndex = currentIndex
                currentIndex = newIndex
                delegate?.peekPanCoordinator?(self, movedTo: currentIndex)
            }
        }
    }
    
    private func setupMinMaxPoints() {
        let pointBetweenBoundaries = CGPointMake(max(min(startingPoint.x, rightMarginPoint.x), leftMarginPoint.x), startingPoint.y)
        
        if let delegateMinPointValue = dataSource?.minimumPoint?(for: self)
            where delegateMinPointValue != CGPointZero {
            isUsingDelegateMinPoint = true
            minimumPoint = delegateMinPointValue
        }
        else if startFromMinimum {
            minimumPoint = pointBetweenBoundaries
        }
        else if startingIndex - peekRange < minimumIndex {
            let segmentWidth = widthOfEachSegment()
            let distanceToMinBoundary = segmentWidth/2 + CGFloat(startingIndex - minimumIndex) * segmentWidth
            minimumPoint.x = max(pointBetweenBoundaries.x - distanceToMinBoundary, leftMarginPoint.x)
        }
        
        if let delegateMaxPointValue = dataSource?.maximumPoint?(for: self)
            where delegateMaxPointValue != CGPointZero {
            isUsingDelegateMaxPoint = true
            maximumPoint = delegateMaxPointValue
        }
        else if !startFromMinimum && startingIndex + peekRange > maximumIndex {
            let segmentWidth = widthOfEachSegment()
            let distanceToMaxBoundary = segmentWidth/2 + CGFloat(maximumIndex - startingIndex) * segmentWidth
            maximumPoint.x = min(pointBetweenBoundaries.x + distanceToMaxBoundary, rightMarginPoint.x)
        }
    }
    
    public func reloadData() {
        minimumIndex = dataSource?.minimumIndex?(for: self) ?? 0
        maximumIndex = dataSource?.maximumIndex(for: self) ?? 0
        startFromMinimum = dataSource?.shouldStartFromMinimumIndex(for: self) ?? false
        
        let numOfIndices = maximumIndex - minimumIndex + 1
        if let delegatePeekRange = dataSource?.maxPeekRange?(for: self)
            where delegatePeekRange > 0 {
            peekRange = max(min(delegatePeekRange, numOfIndices), 1)
        }
        else {
            peekRange = max(min(self.dynamicType.DefaultPeekRange, numOfIndices), 1)
        }
        
        if let delegateHorizontalMargin = dataSource?.horizontalMargin?(for: self)
            where delegateHorizontalMargin >= 0.0 {
            horizontalMargin = delegateHorizontalMargin
        }
        else {
            horizontalMargin = self.dynamicType.DefaultHorizontalMargin
        }
        
        setupMinMaxPoints()
        if state == .Peeking {
            update(at: currentPoint)
        }
    }
    
    // MARK: Helper Methods
    
    public func index(at point: CGPoint) -> Int {
        return max(min(startingIndex + deltaIndex(at: point), maximumIndex), minimumIndex)
    }
    
    private func widthOfEachSegment() -> CGFloat {
        if startFromMinimum {
            return (maximumPoint.x - minimumPoint.x) / CGFloat(peekRange)
        }
        else {
            return (rightMarginPoint.x - leftMarginPoint.x) / CGFloat(peekRange)
        }
    }
    
    private func deltaIndex(at point: CGPoint) -> Int {
        let segmentWidth = widthOfEachSegment()
        let deltaX = point.x - startingPoint.x
        
        if startFromMinimum {
            return Int((point.x - minimumPoint.x) / segmentWidth)
        }
        else {
            if deltaX > segmentWidth/2 {
                return Int((deltaX + segmentWidth/2) / segmentWidth)
            }
            else if deltaX < -segmentWidth/2 {
                return Int((deltaX - segmentWidth/2) / segmentWidth)
            }
            else {
                return 0
            }
        }
    }
    
    // MARK: UIGestureRecognizerDelegate
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == self.gestureRecognizer || otherGestureRecognizer == self.gestureRecognizer
    }
}

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

/// PeekPanCoordinatorDelegate Protocol
@objc public protocol PeekPanCoordinatorDelegate {
    /// Tells the delegate that the gesture recognizer began tracking
    optional func peekPanCoordinatorBegan(peekPanCoordinator: PeekPanCoordinator)
    /// Tells the delegate that the gesture recognizer received an update
    optional func peekPanCoordinatorUpdated(peekPanCoordinator: PeekPanCoordinator)
    /// Tells the delegate that the gesture recognizer ended tracking
    optional func peekPanCoordinatorEnded(peekPanCoordinator: PeekPanCoordinator)
    /// Tells the delegate that the coordinator changed its current index
    optional func peekPanCoordinator(peekPanCoordinator: PeekPanCoordinator, movedTo index: Int)
}

/// PeekPanCoordinatorDataSource Protocol
@objc public protocol PeekPanCoordinatorDataSource {
    /**
     Sets the  maximum index of a range of indices. The maximum index has to be greater than or equal to the minimum index for "peekPanCoordinator:movedTo:" to work. Method is called upon setup and is required.
     
     Returns: Default is 0.
     */
    func maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int
    
    /**
     Have the minimum point begin at the starting point. Method is called upon setup and is required.
     
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

/// Used to represent the current state of PeekPanCoordinator.
@objc public enum PeekPanState : Int {
    /// Has been initialized or reset.
    case Initialized
    /// Finished setup and is ready to start tracking the user's touch location.
    case Ready
    /// Tracking the user's touch location while the Peek preview is displayed.
    case Peeking
    /// Stopped tracking due to the user committing the view controller.
    case Popped
    /// Stopped tracking due to the user's touch being released.
    case Ended
}

/// PeekPanCoordinator uses the data given by its data source to connect an instance of PeekPanGestureRecognizer to a range of indices.
public class PeekPanCoordinator : NSObject, UIGestureRecognizerDelegate {
    
    // MARK: Constants
    
    /// Default number of indices that the user can pan through while Peeking.
    public static let DefaultPeekRange = 8
    /// Default size of the panning area's left and right margins.
    public static let DefaultHorizontalMargin: CGFloat = 40.0
    
    // MARK: Properties
    
    /// A reference to a coordinator that finished setting up.
    public weak static var currentCoordinator: PeekPanCoordinator?
    
    /// The view that PeekPanGestureRecognizer will use to track the user's touch.
    public private(set) weak var sourceView: UIView!
    /// The PeekPanState that the coordinator is in.
    public private(set) var state: PeekPanState
    /// PeekPanCoordinatorDelegate reference.
    public weak var delegate: PeekPanCoordinatorDelegate?
    /// PeekPanDataSource reference.
    public weak var dataSource: PeekPanCoordinatorDataSource?
    private var gestureRecognizer: PeekPanGestureRecognizer!
    
    private var startFromMinimum: Bool
    private var peekRange: Int
    private var horizontalMargin: CGFloat
    private var isUsingDelegateMinPoint: Bool
    private var isUsingDelegateMaxPoint: Bool
    
    /// The index that the coordinator starts at.
    public private(set) var startingIndex: Int
    /// The index that the coordinator was previously at.
    public private(set) var previousIndex: Int
    /// The index that the coordinator is currently at.
    public private(set) var currentIndex: Int
    /// The minimum index that the coordinator can reach.
    public private(set) var minimumIndex: Int
    /// The maximum index that the coordinator can reach.
    public private(set) var maximumIndex: Int
    
    /// The point that the coordinator starts at.
    public private(set) var startingPoint: CGPoint
    /// The point that the coordinator is currently at.
    public private(set) var currentPoint: CGPoint
    /// The minimum point that correlates with the minimum index.
    public private(set) var minimumPoint: CGPoint
    /// The maximum point that correlates with the maximum index.
    public private(set) var maximumPoint: CGPoint
    
    /// The leftmost point that the coordinator will track.
    public var leftMarginPoint: CGPoint {
        return CGPointMake(horizontalMargin, currentPoint.y)
    }
    /// The rightmost point that the coordinator will track.
    public var rightMarginPoint: CGPoint {
        return CGPointMake(CGRectGetWidth(sourceView.bounds) - horizontalMargin, currentPoint.y)
    }
    
    /// The difference between the current point and the minimum point in relation to the size of the panning area. Value from 0.0 to 1.0.
    public var percentage: CGFloat {
        return max(min((currentPoint.x - minimumPoint.x) / (maximumPoint.x - minimumPoint.x), 1.0), 0.0)
    }
    
    // MARK: Init
    
    /// Required init that takes in the source view.
    required public init(sourceView view: UIView!) {
        state = .Initialized
        
        startFromMinimum = false
        peekRange = self.dynamicType.DefaultPeekRange
        horizontalMargin = self.dynamicType.DefaultHorizontalMargin
        isUsingDelegateMinPoint = false
        isUsingDelegateMaxPoint = false
        
        startingIndex = 0
        previousIndex = 0
        currentIndex = 0
        minimumIndex = 0
        maximumIndex = 0
        
        startingPoint = CGPointZero
        currentPoint = CGPointZero
        minimumPoint = CGPointZero
        maximumPoint = CGPointZero
        
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
    
    /// Gather data needed to start the coordinator. Required to track the user's touch.
    public func setup() {
        setup(at: 0)
    }
    
    /// Gather data needed to start the coordinator at a specified index. Required to track the user's touch.
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
    
    /// Called to end tracking the user's touch. Parameter is used to identify whether the coordinator is ending due to a committed view controller or not. Will reset the coordinator's data and set currentCoordinator as nil.
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
    
    /// Used to refetch data from the data source.
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
    
    /// Returns the index at a specified point.
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
        let segmentWidth = max(widthOfEachSegment(), 1)
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
    
    /// Determine whether a gesture recognizer can be used simultaneously with anothoer gesture recognizer. Returns true as long as one of the parameters includes the coordinator's gesture recognizer.
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == self.gestureRecognizer || otherGestureRecognizer == self.gestureRecognizer
    }
}

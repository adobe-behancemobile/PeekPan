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
    @objc optional func peekPanCoordinatorBegan(_ peekPanCoordinator: PeekPanCoordinator)
    /// Tells the delegate that the gesture recognizer received an update
    @objc optional func peekPanCoordinatorUpdated(_ peekPanCoordinator: PeekPanCoordinator)
    /// Tells the delegate that the gesture recognizer ended tracking
    @objc optional func peekPanCoordinatorEnded(_ peekPanCoordinator: PeekPanCoordinator)
    /// Tells the delegate that the coordinator changed its current index
    @objc optional func peekPanCoordinator(_ peekPanCoordinator: PeekPanCoordinator, movedTo index: Int)
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
    @objc optional func shouldStartFromMinimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Bool
    
    /**
     Sets the  minimum index of a range of indices. The maximum index has to be greater than or equal to the minimum index for "peekPanCoordinator:movedTo:" to work. Method is called upon setup.
     
     Returns: Default is 0.
     */
    @objc optional func minimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int
    
    /**
     Fixes the minimum point at a given location. Method is called when the gesture recognizer begins tracking.
     
     Returns: Return CGPointZero to leave unfixed.
     */
    @objc optional func minimumPoint(for peekPanCoordinator: PeekPanCoordinator) -> CGPoint
    
    /**
     Fixes the maximum point at a given location. Method is called when the gesture recognizer begins tracking.
     
     Returns: Return CGPointZero to leave unfixed.
     */
    @objc optional func maximumPoint(for peekPanCoordinator: PeekPanCoordinator) -> CGPoint
    
    /**
     The maximum amount of indices the user can pan through. Method is called upon setup.
     
     Returns: Return an integer less than 1 to set to default. Default is 8.
     */
    @objc optional func maxPeekRange(for peekPanCoordinator: PeekPanCoordinator) -> Int
    
    /**
     The horizontal margins that are inset from the source view's left and right edges. Method is called upon setup.
     
     Returns: Return a float less than 0.0 to set to default. Default is 40.0.
     */
    @objc optional func horizontalMargin(for peekPanCoordinator: PeekPanCoordinator) -> CGFloat
}

/// Used to represent the current state of PeekPanCoordinator.
@objc public enum PeekPanState : Int {
    /// Has been initialized or reset.
    case initialized
    /// Finished setup and is ready to start tracking the user's touch location.
    case ready
    /// Tracking the user's touch location while the Peek preview is displayed.
    case peeking
    /// Stopped tracking due to the user committing the view controller.
    case popped
    /// Stopped tracking due to the user's touch being released.
    case ended
}

/// PeekPanCoordinator uses the data given by its data source to connect an instance of PeekPanGestureRecognizer to a range of indices.
open class PeekPanCoordinator : NSObject, UIGestureRecognizerDelegate {
    
    // MARK: Constants
    
    /// Default number of indices that the user can pan through while Peeking.
    open static let DefaultPeekRange = 8
    /// Default size of the panning area's left and right margins.
    open static let DefaultHorizontalMargin: CGFloat = 40.0
    
    // MARK: Properties
    
    /// A reference to a coordinator that finished setting up.
    open weak static var currentCoordinator: PeekPanCoordinator?
    
    /// The view that PeekPanGestureRecognizer will use to track the user's touch.
    open fileprivate(set) weak var sourceView: UIView!
    /// The PeekPanState that the coordinator is in.
    open fileprivate(set) var state: PeekPanState
    /// PeekPanCoordinatorDelegate reference.
    open weak var delegate: PeekPanCoordinatorDelegate?
    /// PeekPanDataSource reference.
    open weak var dataSource: PeekPanCoordinatorDataSource?
    fileprivate var gestureRecognizer: PeekPanGestureRecognizer!
    
    fileprivate var startFromMinimum: Bool
    fileprivate var peekRange: Int
    fileprivate var horizontalMargin: CGFloat
    fileprivate var isUsingDelegateMinPoint: Bool
    fileprivate var isUsingDelegateMaxPoint: Bool
    
    /// The index that the coordinator starts at.
    open fileprivate(set) var startingIndex: Int
    /// The index that the coordinator was previously at.
    open fileprivate(set) var previousIndex: Int
    /// The index that the coordinator is currently at.
    open fileprivate(set) var currentIndex: Int
    /// The minimum index that the coordinator can reach.
    open fileprivate(set) var minimumIndex: Int
    /// The maximum index that the coordinator can reach.
    open fileprivate(set) var maximumIndex: Int
    
    /// The point that the coordinator starts at.
    open fileprivate(set) var startingPoint: CGPoint
    /// The point that the coordinator is currently at.
    open fileprivate(set) var currentPoint: CGPoint
    /// The minimum point that correlates with the minimum index.
    open fileprivate(set) var minimumPoint: CGPoint
    /// The maximum point that correlates with the maximum index.
    open fileprivate(set) var maximumPoint: CGPoint
    
    /// The leftmost point that the coordinator will track.
    open var leftMarginPoint: CGPoint {
        return CGPoint(x: horizontalMargin, y: currentPoint.y)
    }
    /// The rightmost point that the coordinator will track.
    open var rightMarginPoint: CGPoint {
        return CGPoint(x: sourceView.bounds.width - horizontalMargin, y: currentPoint.y)
    }
    
    /// The difference between the current point and the minimum point in relation to the size of the panning area. Value from 0.0 to 1.0.
    open var percentage: CGFloat {
        return max(min((currentPoint.x - minimumPoint.x) / (maximumPoint.x - minimumPoint.x), 1.0), 0.0)
    }
    
    // MARK: Init
    
    /// Required init that takes in the source view.
    required public init(sourceView view: UIView!) {
        state = .initialized
        
        startFromMinimum = false
        peekRange = type(of: self).DefaultPeekRange
        horizontalMargin = type(of: self).DefaultHorizontalMargin
        isUsingDelegateMinPoint = false
        isUsingDelegateMaxPoint = false
        
        startingIndex = 0
        previousIndex = 0
        currentIndex = 0
        minimumIndex = 0
        maximumIndex = 0
        
        startingPoint = CGPoint.zero
        currentPoint = CGPoint.zero
        minimumPoint = CGPoint.zero
        maximumPoint = CGPoint.zero
        
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
    open func setup() {
        setup(at: 0)
    }
    
    /// Gather data needed to start the coordinator at a specified index. Required to track the user's touch.
    open func setup(at index: Int) {
        reset()
        
        minimumIndex = dataSource?.minimumIndex?(for: self) ?? 0
        maximumIndex = dataSource?.maximumIndex(for: self) ?? 0
        startFromMinimum = dataSource?.shouldStartFromMinimumIndex?(for: self) ?? false
        
        let numOfIndices = maximumIndex - minimumIndex + 1
        if let delegatePeekRange = dataSource?.maxPeekRange?(for: self)
            , delegatePeekRange > 0 {
            peekRange = max(min(delegatePeekRange, numOfIndices), 1)
        }
        else {
            peekRange = max(min(type(of: self).DefaultPeekRange, numOfIndices), 1)
        }
        
        if let delegateHorizontalMargin = dataSource?.horizontalMargin?(for: self)
            , delegateHorizontalMargin >= 0.0 {
            horizontalMargin = delegateHorizontalMargin
        }
        else {
            horizontalMargin = type(of: self).DefaultHorizontalMargin
        }
        
        startingIndex = startFromMinimum ? minimumIndex : index
        currentIndex = minimumIndex - 1;
        previousIndex = minimumIndex - 1;
        
        type(of: self).currentCoordinator = self
        
        state = .ready
    }
    
    fileprivate func reset() {
        state = .initialized
        
        startFromMinimum = false
        peekRange = type(of: self).DefaultPeekRange
        horizontalMargin = type(of: self).DefaultHorizontalMargin
        
        isUsingDelegateMinPoint = false
        isUsingDelegateMaxPoint = false
        
        startingIndex = 0
        previousIndex = 0
        currentIndex = 0
        maximumIndex = 0
        minimumIndex = 0
        
        startingPoint = CGPoint.zero
        currentPoint = CGPoint.zero
        minimumPoint = leftMarginPoint
        maximumPoint = rightMarginPoint
    }
    
    // MARK: Gesture Action
    
    @objc fileprivate func handlePeekPanGesture(_ peekPanGestureRecognizer: PeekPanGestureRecognizer) {
        let point = peekPanGestureRecognizer.location(in: sourceView)
        
        switch peekPanGestureRecognizer.state {
        case .began, .changed:
            if state == .ready {
                state = .peeking
                begin(at: point)
            }
            else if state == .peeking {
                update(at: point)
            }
        case .ended, .cancelled, .failed:
            end(false)
        default: break
        }
    }
    
    // MARK: Gesture Action Methods
    
    fileprivate func begin(at point: CGPoint) {
        let pointBetweenBoundaries = CGPoint(x: max(min(point.x, rightMarginPoint.x), leftMarginPoint.x), y: point.y)
        
        startingPoint = pointBetweenBoundaries
        currentPoint = pointBetweenBoundaries
        
        setupMinMaxPoints()
        
        updateCurrentIndex(at: pointBetweenBoundaries)
        delegate?.peekPanCoordinatorBegan?(self)
    }
    
    fileprivate func update(at point: CGPoint) {
        let pointBetweenBoundaries = CGPoint(x: max(min(point.x, rightMarginPoint.x), leftMarginPoint.x), y: point.y)
        
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
    open func end(_ popped: Bool) {
        state = popped ? .popped : .ended
        delegate?.peekPanCoordinatorEnded?(self)
        reset()
        type(of: self).currentCoordinator = nil
    }
    
    // Methods
    
    fileprivate func updateCurrentIndex(at point: CGPoint) {
        if maximumIndex - minimumIndex >= 0 {
            let newIndex = index(at: point)
            if newIndex != currentIndex {
                previousIndex = currentIndex
                currentIndex = newIndex
                delegate?.peekPanCoordinator?(self, movedTo: currentIndex)
            }
        }
    }
    
    fileprivate func setupMinMaxPoints() {
        let pointBetweenBoundaries = CGPoint(x: max(min(startingPoint.x, rightMarginPoint.x), leftMarginPoint.x), y: startingPoint.y)
        
        if let delegateMinPointValue = dataSource?.minimumPoint?(for: self)
            , delegateMinPointValue != CGPoint.zero {
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
            , delegateMaxPointValue != CGPoint.zero {
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
    open func reloadData() {
        minimumIndex = dataSource?.minimumIndex?(for: self) ?? 0
        maximumIndex = dataSource?.maximumIndex(for: self) ?? 0
        startFromMinimum = dataSource?.shouldStartFromMinimumIndex?(for: self) ?? false
        
        let numOfIndices = maximumIndex - minimumIndex + 1
        if let delegatePeekRange = dataSource?.maxPeekRange?(for: self)
            , delegatePeekRange > 0 {
            peekRange = max(min(delegatePeekRange, numOfIndices), 1)
        }
        else {
            peekRange = max(min(type(of: self).DefaultPeekRange, numOfIndices), 1)
        }
        
        if let delegateHorizontalMargin = dataSource?.horizontalMargin?(for: self)
            , delegateHorizontalMargin >= 0.0 {
            horizontalMargin = delegateHorizontalMargin
        }
        else {
            horizontalMargin = type(of: self).DefaultHorizontalMargin
        }
        
        setupMinMaxPoints()
        if state == .peeking {
            update(at: currentPoint)
        }
    }
    
    // MARK: Helper Methods
    
    /// Returns the index at a specified point.
    open func index(at point: CGPoint) -> Int {
        return max(min(startingIndex + deltaIndex(at: point), maximumIndex), minimumIndex)
    }
    
    fileprivate func widthOfEachSegment() -> CGFloat {
        if startFromMinimum {
            return (maximumPoint.x - minimumPoint.x) / CGFloat(peekRange)
        }
        else {
            return (rightMarginPoint.x - leftMarginPoint.x) / CGFloat(peekRange)
        }
    }
    
    fileprivate func deltaIndex(at point: CGPoint) -> Int {
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
    open func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return gestureRecognizer == self.gestureRecognizer || otherGestureRecognizer == self.gestureRecognizer
    }
}

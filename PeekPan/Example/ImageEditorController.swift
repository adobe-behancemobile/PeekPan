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

import CoreImage
import CoreGraphics
import UIKit

class ImageEditorController : UIViewController, UIViewControllerPreviewingDelegate, PeekPanCoordinatorDelegate, PeekPanCoordinatorDataSource, PeekPanViewControllerDelegate {
    @IBOutlet var brightnessSlider: UISlider!
    @IBOutlet var contrastSlider: UISlider!
    @IBOutlet var sharpnessSlider: UISlider!
    
    @IBOutlet var brightnessLabel: UILabel!
    @IBOutlet var contrastLabel: UILabel!
    @IBOutlet var sharpnessLabel: UILabel!
    
    let coreImage = CIImage(image: UIImage(named: "color_image")!)
    
    var brightnessValue: CGFloat = 0.0
    var contrastValue: CGFloat = 1.0
    var sharpnessValue: CGFloat = 0.4
    
    weak var selectedSlider: UISlider?
    
    @IBOutlet var imageView: UIImageView!
    
    var peekPanCoordinator: PeekPanCoordinator!
    let peekPanVC = PeekPanViewController()
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        brightnessLabel.text = String(brightnessValue)
        contrastLabel.text = String(contrastValue)
        sharpnessLabel.text = String(sharpnessValue)
    }
    
    override func traitCollectionDidChange(previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .Available {
                registerForPreviewingWithDelegate(self, sourceView: view)
                peekPanCoordinator = PeekPanCoordinator(sourceView: view)
                peekPanCoordinator.delegate = peekPanVC
                peekPanCoordinator.dataSource = self
                peekPanVC.delegate = self
            }
        }
    }
    
    // MARK: Methods
    
    @IBAction func didSetBrightness(sender: UISlider) {
        brightnessValue = CGFloat(sender.value)
        brightnessLabel.text = NSString(format: "%.2f", sender.value) as String
        updateImageWithCurrentValues(imageView)
    }
    
    @IBAction func didSetContrast(sender: UISlider) {
        contrastValue = CGFloat(sender.value)
        contrastLabel.text = NSString(format: "%.2f", sender.value) as String
        updateImageWithCurrentValues(imageView)
    }
    
    @IBAction func didSetSharpness(sender: UISlider) {
        sharpnessValue = CGFloat(sender.value)
        sharpnessLabel.text = NSString(format: "%.2f", sender.value) as String
        updateImageWithCurrentValues(imageView)
    }
    
    func updateSelected() {
        if selectedSlider == nil { return }
        if selectedSlider == brightnessSlider {
            selectedSlider!.value = Float(brightnessValue)
            brightnessLabel!.text = NSString(format: "%.2f", brightnessValue) as String
        }
        else if selectedSlider == contrastSlider {
            selectedSlider!.value = Float(contrastValue)
            contrastLabel!.text = NSString(format: "%.2f", contrastValue) as String
        }
        else if selectedSlider == sharpnessSlider {
            selectedSlider!.value = Float(sharpnessValue)
            sharpnessLabel!.text = NSString(format: "%.2f", sharpnessValue) as String
        }
    }
    
    func revertSelected() {
        if selectedSlider == nil { return }
        if selectedSlider == brightnessSlider {
            brightnessValue = CGFloat(selectedSlider!.value)
        }
        else if selectedSlider == contrastSlider {
            contrastValue = CGFloat(selectedSlider!.value)
        }
        else if selectedSlider == sharpnessSlider {
            sharpnessValue = CGFloat(selectedSlider!.value)
        }
    }
    
    func updateImageWithCurrentValues(imageView: UIImageView) {
        let context = CIContext(options: nil)
        var extent = CGRectZero
        let colorFilter = CIFilter(name: "CIColorControls")! // brightness & contrast
        colorFilter.setValue(coreImage, forKey: kCIInputImageKey)
        colorFilter.setValue(brightnessValue, forKey: kCIInputBrightnessKey)
        colorFilter.setValue(contrastValue, forKey: kCIInputContrastKey)
        var outputImage = colorFilter.valueForKey(kCIOutputImageKey) as! CIImage
        let sharpnessFilter = CIFilter(name: "CISharpenLuminance")!
        sharpnessFilter.setValue(outputImage, forKey: kCIInputImageKey)
        sharpnessFilter.setValue(sharpnessValue, forKey: kCIInputSharpnessKey)
        outputImage = sharpnessFilter.valueForKey(kCIOutputImageKey) as! CIImage
        extent = outputImage.extent
        imageView.image = UIImage(CGImage: context.createCGImage(outputImage, fromRect: extent))
    }
    
    // MARK: PeekPanCoordinatorDataSource
    
    func maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int {
        return 0
    }
    
    func shouldStartFromMinimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Bool {
        return false
    }
    
    func minimumPoint(for peekPanCoordinator: PeekPanCoordinator) -> CGPoint {
        if let slider = selectedSlider {
            return slider.frame.origin
        }
        return CGPointZero
    }
    
    func maximumPoint(for peekPanCoordinator: PeekPanCoordinator) -> CGPoint {
        if let slider = selectedSlider {
            return CGPointMake(CGRectGetMaxX(slider.frame), CGRectGetMaxY(slider.frame))
        }
        return CGPointZero
    }
    
    // MARK: PeekPanViewControllerDelegate
    
    func peekPanCoordinatorEnded(peekPanCoordinator: PeekPanCoordinator) {
        if peekPanCoordinator.state == .Popped {
            updateSelected()
            updateImageWithCurrentValues(imageView)
        }
        else {
            revertSelected()
        }
        selectedSlider = nil
    }
    
    func view(for peekPanViewController: PeekPanViewController, atPercentage percentage: CGFloat) -> UIView? {
        let imageView = UIImageView()
        let valueLabel = UILabel()
        valueLabel.textColor = .whiteColor()
        valueLabel.frame.origin = CGPointMake(20, 20)
        valueLabel.font = UIFont.systemFontOfSize(38)
        valueLabel.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        imageView.addSubview(valueLabel)
        if selectedSlider == brightnessSlider {
            brightnessValue = CGFloat(brightnessSlider.maximumValue - brightnessSlider.minimumValue) * percentage + CGFloat(brightnessSlider.minimumValue)
            valueLabel.text = NSString(format: "%.2f", brightnessValue) as String
        }
        else if selectedSlider == contrastSlider {
            let range = CGFloat(contrastSlider.maximumValue - contrastSlider.minimumValue) * 0.3
            let startingValue = (CGFloat(peekPanCoordinator.startingPoint.x) - CGRectGetMinX(selectedSlider!.frame)) / CGRectGetWidth(selectedSlider!.bounds) * CGFloat(contrastSlider.maximumValue - contrastSlider.minimumValue)
            contrastValue = min(max(range * percentage + (startingValue - range/2), CGFloat(contrastSlider.minimumValue)), CGFloat(contrastSlider.maximumValue))
            valueLabel.text = NSString(format: "%.2f", contrastValue) as String
        }
        else if selectedSlider == sharpnessSlider {
            sharpnessValue = CGFloat(sharpnessSlider.maximumValue - sharpnessSlider.minimumValue) * percentage + CGFloat(sharpnessSlider.minimumValue)
            valueLabel.text = NSString(format: "%.2f", sharpnessValue) as String
            
            let zoomRatio: CGFloat = 0.3
            imageView.layer.contentsRect = CGRectMake(
                0.5 - (CGRectGetWidth(self.imageView.bounds)*zoomRatio/2)/CGRectGetWidth(self.imageView.bounds),
                0.5 - (CGRectGetHeight(self.imageView.bounds)*zoomRatio)/CGRectGetHeight(self.imageView.bounds),
                zoomRatio,
                zoomRatio)
        }
        
        valueLabel.sizeToFit()
        updateImageWithCurrentValues(imageView)
        
        return imageView
    }
    
    // MARK: UIViewControllerPreviewingDelegate
    
    @available (iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if CGRectContainsPoint(brightnessSlider.frame, location) {
            selectedSlider = brightnessSlider
        }
        else if CGRectContainsPoint(contrastSlider.frame, location) {
            selectedSlider = contrastSlider
        }
        else if CGRectContainsPoint(sharpnessSlider.frame, location) {
            selectedSlider = sharpnessSlider
        }
        else {
            selectedSlider = nil
            return nil
        }
        peekPanCoordinator.setup()
        
        previewingContext.sourceRect = selectedSlider!.frame
        return peekPanVC
    }
    
    @available (iOS 9.0, *)
    func previewingContext(previewingContext: UIViewControllerPreviewing, commitViewController viewControllerToCommit: UIViewController) {
        peekPanCoordinator.end(true)
    }
}
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
        
        brightnessLabel.text = String(describing: brightnessValue)
        contrastLabel.text = String(describing: contrastValue)
        sharpnessLabel.text = String(describing: sharpnessValue)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 9.0, *) {
            if traitCollection.forceTouchCapability == .available {
                registerForPreviewing(with: self, sourceView: view)
                peekPanCoordinator = PeekPanCoordinator(sourceView: view)
                peekPanCoordinator.delegate = peekPanVC
                peekPanCoordinator.dataSource = self
                peekPanVC.delegate = self
            }
        }
    }
    
    // MARK: Methods
    
    @IBAction func didSetBrightness(_ sender: UISlider) {
        brightnessValue = CGFloat(sender.value)
        brightnessLabel.text = NSString(format: "%.2f", sender.value) as String
        updateImageWithCurrentValues(imageView)
    }
    
    @IBAction func didSetContrast(_ sender: UISlider) {
        contrastValue = CGFloat(sender.value)
        contrastLabel.text = NSString(format: "%.2f", sender.value) as String
        updateImageWithCurrentValues(imageView)
    }
    
    @IBAction func didSetSharpness(_ sender: UISlider) {
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
    
    func updateImageWithCurrentValues(_ imageView: UIImageView) {
        let context = CIContext(options: nil)
        var extent = CGRect.zero
        let colorFilter = CIFilter(name: "CIColorControls")! // brightness & contrast
        colorFilter.setValue(coreImage, forKey: kCIInputImageKey)
        colorFilter.setValue(brightnessValue, forKey: kCIInputBrightnessKey)
        colorFilter.setValue(contrastValue, forKey: kCIInputContrastKey)
        var outputImage = colorFilter.value(forKey: kCIOutputImageKey) as! CIImage
        let sharpnessFilter = CIFilter(name: "CISharpenLuminance")!
        sharpnessFilter.setValue(outputImage, forKey: kCIInputImageKey)
        sharpnessFilter.setValue(sharpnessValue, forKey: kCIInputSharpnessKey)
        outputImage = sharpnessFilter.value(forKey: kCIOutputImageKey) as! CIImage
        extent = outputImage.extent
        imageView.image = UIImage(cgImage: context.createCGImage(outputImage, from: extent)!)
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
        return CGPoint.zero
    }
    
    func maximumPoint(for peekPanCoordinator: PeekPanCoordinator) -> CGPoint {
        if let slider = selectedSlider {
            return CGPoint(x: slider.frame.maxX, y: slider.frame.maxY)
        }
        return CGPoint.zero
    }
    
    // MARK: PeekPanViewControllerDelegate
    
    func peekPanCoordinatorEnded(_ peekPanCoordinator: PeekPanCoordinator) {
        if peekPanCoordinator.state == .popped {
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
        valueLabel.textColor = .white
        valueLabel.frame.origin = CGPoint(x: 20, y: 20)
        valueLabel.font = UIFont.systemFont(ofSize: 38)
        valueLabel.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.3)
        imageView.addSubview(valueLabel)
        if selectedSlider == brightnessSlider {
            brightnessValue = CGFloat(brightnessSlider.maximumValue - brightnessSlider.minimumValue) * percentage + CGFloat(brightnessSlider.minimumValue)
            valueLabel.text = NSString(format: "%.2f", brightnessValue) as String
        }
        else if selectedSlider == contrastSlider {
            let range = CGFloat(contrastSlider.maximumValue - contrastSlider.minimumValue) * 0.3
            let startingValue = (CGFloat(peekPanCoordinator.startingPoint.x) - selectedSlider!.frame.minX) / selectedSlider!.bounds.width * CGFloat(contrastSlider.maximumValue - contrastSlider.minimumValue)
            contrastValue = min(max(range * percentage + (startingValue - range/2), CGFloat(contrastSlider.minimumValue)), CGFloat(contrastSlider.maximumValue))
            valueLabel.text = NSString(format: "%.2f", contrastValue) as String
        }
        else if selectedSlider == sharpnessSlider {
            sharpnessValue = CGFloat(sharpnessSlider.maximumValue - sharpnessSlider.minimumValue) * percentage + CGFloat(sharpnessSlider.minimumValue)
            valueLabel.text = NSString(format: "%.2f", sharpnessValue) as String
            
            let zoomRatio: CGFloat = 0.3
            imageView.layer.contentsRect = CGRect(
                x: 0.5 - (self.imageView.bounds.width*zoomRatio/2)/self.imageView.bounds.width,
                y: 0.5 - (self.imageView.bounds.height*zoomRatio)/self.imageView.bounds.height,
                width: zoomRatio,
                height: zoomRatio)
        }
        
        valueLabel.sizeToFit()
        updateImageWithCurrentValues(imageView)
        
        return imageView
    }
    
    // MARK: UIViewControllerPreviewingDelegate
    
    @available (iOS 9.0, *)
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        if brightnessSlider.frame.contains(location) {
            selectedSlider = brightnessSlider
        }
        else if contrastSlider.frame.contains(location) {
            selectedSlider = contrastSlider
        }
        else if sharpnessSlider.frame.contains(location) {
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
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        peekPanCoordinator.end(true)
    }
}

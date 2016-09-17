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

class BaseCollectionViewController : UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PeekPanCoordinatorDelegate {
    let cellIdentifier = "imageCollectionCell"
    
    var thumbnailItems = [UIImage]()
    @IBOutlet var collectionView: UICollectionView!
    @IBOutlet var cellNumLabel: UILabel!
    @IBOutlet var cellNumStepper: UIStepper!
    @IBOutlet var cellPerRowLabel: UILabel!
    @IBOutlet var cellPerRowStepper: UIStepper!
    @IBOutlet var overlaySwitch: UISwitch!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cellNumLabel.text = "\(Int(cellNumStepper.value)) Cells"
        cellPerRowLabel.text = "\(Int(cellPerRowStepper.value)) Cells Per Row"
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @IBAction func cellNumChanged(_ sender: UIStepper) {
        cellNumLabel.text = "\(Int(sender.value)) Cells"
        collectionView.reloadData()
    }
    
    @IBAction func cellPerRowChanged(_ sender: UIStepper) {
        cellPerRowLabel.text = "\(Int(sender.value)) Cells Per Row"
        collectionView.reloadData()
    }
    
    @IBAction func toggleOverlay(_ sender: UISwitch) { }
    
    func getImage(from string: NSString) -> UIImage {
        let font = UIFont.boldSystemFont(ofSize: 100.0)
        let size = string.size(attributes: [NSFontAttributeName: font])
        UIGraphicsBeginImageContext(size)
        string.draw(at: CGPoint.zero, withAttributes: [NSFontAttributeName: font])
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Int(cellNumStepper.value)
    }
    
    // MARK: UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ImageCollectionCell
        cell.imageView.image = thumbnailItems[(indexPath as NSIndexPath).row]
        return cell
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let flowLayout = collectionViewLayout as? UICollectionViewFlowLayout else { return CGSize.zero }
        
        let size = view.bounds.width/CGFloat(cellPerRowStepper.value) - flowLayout.minimumInteritemSpacing
        return CGSize(width: size, height: size)
    }
}

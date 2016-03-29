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

class ImageTableViewController : UIViewController, UITableViewDataSource, UITableViewDelegate, PeekPanCoordinatorDelegate, PeekPanCoordinatorDataSource {
    let cellIdentifier = "imageTableCell"
    
    var imageTableItems = [ImageTableItem]()
    var imageCollectionItem = ImageCollectionItem(projId: 0, contentItems: []) {
        willSet {
            imageTableItems.removeAll()
            for tableItem in newValue.contentItems {
                imageTableItems.append(ImageTableItem(image: tableItem.image, text: tableItem.text))
            }
            tableView.reloadData()
        }
    }
    @IBOutlet var tableView: UITableView!
    
    // MARK: PeekPanCoordinatorDataSource
    
    func maximumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Int {
        return imageTableItems.count - 1
    }
    
    func shouldStartFromMinimumIndex(for peekPanCoordinator: PeekPanCoordinator) -> Bool {
        return true
    }
    
    func maxPeekRange(for peekPanCoordinator: PeekPanCoordinator) -> Int {
        return PeekPanCoordinator.DefaultPeekRange * 2
    }
    
    // MARK: PeekPanCoordinatorDelegate
    
    func peekPanCoordinator(peekPanCoordinator: PeekPanCoordinator, movedTo index: Int) {
        let indexPath = NSIndexPath(forRow: index, inSection: 0)
        let cellRect = tableView.rectForRowAtIndexPath(indexPath)
        tableView.contentOffset = cellRect.origin
        preferredContentSize = CGSizeMake(CGRectGetWidth(cellRect), CGRectGetHeight(cellRect) - 1)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageTableItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! ImageTableViewCell
        
        let item = imageCollectionItem.contentItems[indexPath.row]
        cell.tableImageView.image = item.image
        cell.headerLabel.text = item.text
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let imageSize = imageTableItems[indexPath.row].image.size
        let aspectRatio = imageSize.width/imageSize.height
        return CGRectGetWidth(tableView.bounds)/aspectRatio + 50.0
    }
    
}
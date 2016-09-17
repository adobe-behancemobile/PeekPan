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
    
    func peekPanCoordinator(_ peekPanCoordinator: PeekPanCoordinator, movedTo index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        let cellRect = tableView.rectForRow(at: indexPath)
        tableView.contentOffset = cellRect.origin
        preferredContentSize = CGSize(width: cellRect.width, height: cellRect.height - 1)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageTableItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as! ImageTableViewCell
        
        let item = imageCollectionItem.contentItems[(indexPath as NSIndexPath).row]
        cell.tableImageView.image = item.image
        cell.headerLabel.text = item.text
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let imageSize = imageTableItems[(indexPath as NSIndexPath).row].image.size
        let aspectRatio = imageSize.width/imageSize.height
        return tableView.bounds.width/aspectRatio + 50.0
    }
    
}

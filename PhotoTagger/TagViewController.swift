//
//  TagViewController.swift
//  PhotoTagger
//
//  Created by Otávio Zabaleta on 07/04/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit
import Photos

enum PTCOLLECTIONMODE {
    case TAG
    case LIBRARY
}

class TagViewController: DefaultViewController, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionViewPhotos: UICollectionView!
    
    var tag: Tag?
    var mode: PTCOLLECTIONMODE = .TAG
    let photoManager = PHImageManager.defaultManager()
    let cachingImageManager = PHCachingImageManager()
    var arrayPhotos = Array<PHAsset>()
    
    // ================================================================================
    // MARK: - Lifecycle
    // ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        var addPhotoButton = UIBarButtonItem(title: "Add", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("btnAddPhoto_TouchUpInside:"))
        navigationItem.rightBarButtonItem = addPhotoButton
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let theTag = tag {
            mode = .TAG
            navigationItem.title = tag?.name
        }
        else {
            mode = .LIBRARY
            navigationItem.title = "All photos"
        }
        
        if arrayPhotos.count == 0 {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            if let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options) {
                results.enumerateObjectsUsingBlock({ (object, index, _) -> Void in
                    if let asset = object as? PHAsset {
                        self.arrayPhotos.append(asset)
                    }
                })
                collectionViewPhotos.reloadData()
            }
            
        }
    }
    
    // ================================================================================
    // MARK: - IBAction
    // ================================================================================
    func btnAddPhoto_TouchUpInside(sender: UIBarButtonItem) {
        
    }
    
    // ================================================================================
    // MARK: - UICollectionViewDataSource / Delegate
    // ================================================================================
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrayPhotos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionViewPhotos.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! UICollectionViewCell
        cell.layer.shouldRasterize = true
        
        if cell.tag != 0 {
            photoManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        let asset = arrayPhotos[indexPath.row]
        cell.tag = Int(photoManager.requestImageForAsset(asset, targetSize: CGSize(width: cell.frame.width, height: cell.frame.height), contentMode:  .AspectFit, options: nil, resultHandler: { (result: UIImage! ,  _) -> Void in
            var imageView = cell.viewWithTag(99999) as? UIImageView
            if let aCell = self.collectionViewPhotos.cellForItemAtIndexPath(indexPath) {
                imageView?.image = result
            }
        }))

        return cell
    }
}

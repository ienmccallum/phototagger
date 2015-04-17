//
//  PhotoViewController.swift
//  PhotoTagger
//
//  Created by Otávio Zabaleta on 13/04/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit
import Photos
import CoreData

protocol PictureViewControllerDelegate {
    func startedSelectingWithPicure(picture: Picture)
}

class PictureViewController: DefaultViewController {
    @IBOutlet weak var imageViewPhoto: UIImageView!
    
    let photoManager = PHImageManager.defaultManager()
    let cachingImageManager = PHCachingImageManager()
    var delegate: PictureViewControllerDelegate?
    
    var picture: Picture?
    
    // ================================================================================
    // MARK: - Lifecycle
    // ================================================================================
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        if let thePicture = picture {
            let options = PHFetchOptions()
            options.predicate = NSPredicate(format: "localIdentifier == '\(thePicture.identifier)'")
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            if let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options) {
                results.enumerateObjectsUsingBlock({ (object, index: Int, _) -> Void in
                    if let asset = object as? PHAsset {
                        self.cachingImageManager.requestImageForAsset(asset, targetSize: CGSize(width: self.imageViewPhoto.frame.width * screenScale, height: self.imageViewPhoto.frame.height * screenScale), contentMode: PHImageContentMode.AspectFit, options: nil, resultHandler: { (image, _) -> Void in
                                self.imageViewPhoto.image = image
                        })
                    }
                })
            }
        }
    }
    
    // ================================================================================
    // MARK: - IBAction
    // ================================================================================
    @IBAction func btnDone_TouchUpInside(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func btnSelectMore_TouchUpInside(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
        delegate!.startedSelectingWithPicure(picture!)
    }
    
}
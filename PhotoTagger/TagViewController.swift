//
//  TagViewController.swift
//  PhotoTagger
//
//  Created by Otávio Zabaleta on 07/04/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit

class TagViewController: DefaultViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionViewPhotos: UICollectionView!
    
    var tag: Tag?
    var selectedImages = Array<UIImage>()
    
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
        navigationItem.title = tag?.name
    }
    
    // ================================================================================
    // MARK: - IBAction
    // ================================================================================
    func btnAddPhoto_TouchUpInside(sender: UIBarButtonItem) {
        let picker = UIImagePickerController()
        picker.delegate = self
        presentViewController(picker, animated: true, nil)
    }
    
    // ================================================================================
    // MARK: - UIIMagePickerControllerDelegate
    // ================================================================================
    func imagePickerController(picker: UIImagePickerController!, didFinishPickingImage image: UIImage!, editingInfo: [NSObject : AnyObject]!) {
        if find(selectedImages, image) == nil {
            selectedImages.append(image)
            collectionViewPhotos.reloadData()
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // ================================================================================
    // MARK: - UICollectionViewDataSource / Delegate
    // ================================================================================

    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return selectedImages.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionViewPhotos.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as UICollectionViewCell
        cell.layer.shouldRasterize = true
        var imageView = cell.viewWithTag(1) as UIImageView
        imageView.image = selectedImages[indexPath.row]
        return cell
    }
}

//
//  TagViewController.swift
//  PhotoTagger
//
//  Created by Otávio Zabaleta on 07/04/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit
import Photos
import CoreData

enum PTCOLLECTIONMODE {
    case TAG
    case LIBRARY
}

enum PTSELECTIONMODE {
    case VIEW
    case SELECT
}

class TagViewController: DefaultViewController, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, TagSelectingViewControllerDelegate, PictureViewControllerDelegate {
    
    @IBOutlet weak var collectionViewPhotos: UICollectionView!
    
    var tag: Tag?
    var mode: PTCOLLECTIONMODE = .TAG
    var selectMode: PTSELECTIONMODE = .VIEW
    let photoManager = PHImageManager.defaultManager()
    let cachingImageManager = PHCachingImageManager()
    var arrayPhotos = Array<PHAsset>()
    var selectedPhotos = Array<PHAsset>()
    var collectionViewCellSize: CGFloat = 78.0
    var pictures = [Picture]()
    var lastSelected: Picture?
    var lastSelectedIndexPath: NSIndexPath?
    var addPhotoButton: UIBarButtonItem?
    var initing = true
    
    // ================================================================================
    // MARK: - Lifecycle
    // ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionViewCellSize = ((UIScreen.mainScreen().nativeBounds.width / UIScreen.mainScreen().scale) - 6) / 4
        
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        var error: NSError?
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [Picture]
        if fetchedResults != nil {
            pictures = fetchedResults!
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if initing {
            initing = false;
            
            if let theTag = tag {
                mode = .TAG
                navigationItem.title = tag?.name
            }
            else {
                addPhotoButton = UIBarButtonItem(title: "Tag", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("btnAddPhoto_TouchUpInside:"))
                navigationItem.rightBarButtonItem = addPhotoButton
                mode = .LIBRARY
                navigationItem.title = "All photos"
            }
            
            generateDataStructures()
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showTagSelector" {
            let view: TagSelectingViewController = segue.destinationViewController as! TagSelectingViewController
            view.delegate = self
        }
        else if segue.identifier == "showPicture" {
            let view: PictureViewController = segue.destinationViewController as! PictureViewController
            view.picture = lastSelected
            view.delegate = self
        }
    }
    
    // ================================================================================
    // MARK: - Private
    // ================================================================================
    func addPictureWithIdentifier(identifier: String, tags: [Tag]) {
        // 1 - get managed context
        let managedContext = appDelegate.managedObjectContext!
        
        // 2 - Check if we already have it
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        fetchRequest.predicate = NSPredicate(format: "identifier = '\(identifier)'")
        
        var error: NSError? = nil
        var fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as! [Picture]
        if let theError = error  {
            println("Could not fetch \(error), \(error)")
        }
        else {
            var newPicture: Picture
            if fetchedResults.count == 0 {
                newPicture = NSEntityDescription.insertNewObjectForEntityForName("Picture", inManagedObjectContext: managedContext) as! Picture
            }
            else {
                newPicture = (fetchedResults as NSArray).objectAtIndex(0) as! Picture
            }
            
            //let newTag = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            
            // 4 - Set value for tag.name and save
            newPicture.identifier = identifier
            newPicture.tags = NSSet(array: tags)
            
            var error: NSError?
            if !managedContext.save(&error) {
                println("Could not save tag: \(error), \(error?.userInfo)")
            }
            
            pictures.append(newPicture)
        }
        
    }
    
    // ================================================================================
    // MARK: - Generate Data Structures
    // ================================================================================
    func generateDataStructures() {
        arrayPhotos = Array<PHAsset>()
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options) {
            results.enumerateObjectsUsingBlock({ (object, index, _) -> Void in
                if let asset = object as? PHAsset {
                    if let theTag = self.tag {
                        let pics = theTag.pics.allObjects as! [Picture]
                        for pic: Picture in pics {
                            if pic.identifier == asset.localIdentifier {
                                self.arrayPhotos.append(asset)
                            }
                        }
                    }
                    else {
                        self.arrayPhotos.append(asset)
                    }
                }
            })
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .HighQualityFormat
            cachingImageManager.startCachingImagesForAssets(arrayPhotos, targetSize: PHImageManagerMaximumSize, contentMode: .AspectFit, options: options)
            collectionViewPhotos.reloadData()
        }
        
    }
    
    // ================================================================================
    // MARK: - IBAction
    // ================================================================================
    func btnAddPhoto_TouchUpInside(sender: UIBarButtonItem) {
        performSegueWithIdentifier("showTagSelector", sender: self)
    }
    
    // ================================================================================
    // MARK: - TagSelectingViewControllerDelegate
    // ================================================================================
    func didCancel() {
        
    }
    
    func didSaveWithTags(tags: Array<Tag>!) {
        for pic: PHAsset in selectedPhotos {
            addPictureWithIdentifier(pic.localIdentifier, tags: tags)
        }
        
        for tag: Tag in tags {
            
        }
    }
    
    // ================================================================================
    // MARK: - PictureViewControllerDelegate
    // ================================================================================
    func startedSelectingWithPicure(picture: Picture) {
        selectMode = .SELECT
        collectionView(collectionViewPhotos, didSelectItemAtIndexPath: lastSelectedIndexPath!)
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
        var cell = collectionViewPhotos.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        cell.layer.shouldRasterize = true
        cell.imageViewSelected.hidden = !cell.selected
        if cell.tag != 0 {
            cachingImageManager.cancelImageRequest(PHImageRequestID(cell.tag))
        }
        
        let asset = arrayPhotos[indexPath.row]
        let options = PHImageRequestOptions()
        options.deliveryMode = .HighQualityFormat
        cell.tag = Int(cachingImageManager.requestImageForAsset(asset, targetSize: CGSize(width: cell.frame.width * screenScale, height: cell.frame.height * screenScale), contentMode: .AspectFit, options: options, resultHandler: { (result: UIImage! ,  _) -> Void in
            if let aCell = self.collectionViewPhotos.cellForItemAtIndexPath(indexPath) as? PhotoCell {
                aCell.imageViewPicture.image = result
            }
        }))

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        lastSelectedIndexPath = indexPath
        let cell = self.collectionViewPhotos.cellForItemAtIndexPath(indexPath) as? PhotoCell
        let selectedAsset = arrayPhotos[indexPath.item] as PHAsset
        
        if selectMode == .VIEW {
            var foundPic: Picture?
            for pic: Picture in pictures {
                if pic.identifier == selectedAsset.localIdentifier {
                    foundPic = pic
                    break
                }
            }
            if let thePic = foundPic {
                lastSelected = foundPic
            }
            else {
                self.addPictureWithIdentifier(selectedAsset.localIdentifier, tags: Array<Tag>())
                lastSelected = pictures.last
            }
            performSegueWithIdentifier("showPicture", sender: self)
        }
        else {
            if !(selectedPhotos as NSArray).containsObject(selectedAsset) {
                selectedPhotos.append(selectedAsset)
                cell?.imageViewSelected?.hidden = false
            }
            else {
                let index = (selectedPhotos as NSArray).indexOfObject(selectedAsset)
                selectedPhotos.removeAtIndex(index)
                cell?.imageViewSelected?.hidden = true
                if selectedPhotos.count == 0 {
                    selectMode = .VIEW
                }
            }
        }
    }
    
    // ================================================================================
    // MARK: - UICollectionViewDelegateFlowLayout
    // ================================================================================
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        return CGSize(width: collectionViewCellSize, height: collectionViewCellSize)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 2.0
    }


}

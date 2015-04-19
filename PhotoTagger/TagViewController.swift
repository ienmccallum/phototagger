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
    @IBOutlet weak var btnSelectDeselectAll: UIBarButtonItem!
    @IBOutlet weak var btnHideShowTagged: UIBarButtonItem!
    @IBOutlet weak var btnCount: UIBarButtonItem!
    
    var tag: Tag?
    var mode: PTCOLLECTIONMODE = .TAG
    var selectMode: PTSELECTIONMODE = .VIEW
    let photoManager = PHImageManager.defaultManager()
    let cachingImageManager = PHCachingImageManager()
    var arrayPhotos = Array<PHAsset>()
    var arrayFilteredPhotos = Array<PHAsset>()
    var selectedPhotos = Array<PHAsset>()
    var collectionViewCellSize: CGFloat = 78.0
    var imageSize: CGSize = CGSize(width: 78.0 * screenScale, height: 78.0 * screenScale)
    var pictures = [Picture]()
    var lastSelected: Picture?
    var lastSelectedIndexPath: NSIndexPath?
    var btnTag: UIBarButtonItem?
    var initing = true
    var isFiltering = false
    
    // ================================================================================
    // MARK: - Lifecycle
    // ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
        collectionViewCellSize = ((UIScreen.mainScreen().nativeBounds.width / UIScreen.mainScreen().scale) - 6) / 4
        imageSize = CGSize(width: collectionViewCellSize * screenScale, height: collectionViewCellSize * screenScale)
        
        if initing {
            initing = false;
            
            if let theTag = tag {
                mode = .TAG
                navigationItem.title = tag?.name
                btnTag = UIBarButtonItem(title: "Untag", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("btnUntagPhoto_TouchUpInside:"))
                navigationItem.rightBarButtonItem = btnTag
            }
            else {
                btnTag = UIBarButtonItem(title: "Tag", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("btnTagPhoto_TouchUpInside:"))
                navigationItem.rightBarButtonItem = btnTag
                mode = .LIBRARY
                navigationItem.title = "All photos"
                navigationController?.navigationBar.topItem?.title = "Tags"
                
            }
            
            btnTag?.enabled = false
            
            generateDataStructures()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
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
    
    func addTagWithName(name: String, pics: Array<Picture>) {
        // 1 - get managed context
        let managedContext = appDelegate.managedObjectContext!
        
        // 2 - Check if we already have it
        let fetchRequest = NSFetchRequest(entityName: "Tag")
        fetchRequest.predicate = NSPredicate(format: "name = '\(name)'")
        
        var error: NSError? = nil
        var fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [Tag]
        if let theError = error  {
            println("Could not fetch \(error), \(error)")
        }
        else {
            var newTag: Tag
            if fetchedResults!.count == 0 {
                newTag = NSEntityDescription.insertNewObjectForEntityForName("Tag", inManagedObjectContext: managedContext) as! Tag
                newTag.name = name
            }
            else {
                newTag = (fetchedResults! as NSArray).objectAtIndex(0) as! Tag
            }
            
            newTag.pics = NSSet(array: pics)
            tag = newTag
            var error: NSError?
            if !managedContext.save(&error) {
                println("Could not save tag: \(error), \(error?.userInfo)")
            }
            else {
                generateDataStructures()
                
                collectionViewPhotos.reloadData()
            }
        }
    }
    
    // ================================================================================
    // MARK: - Generate Data Structures
    // ================================================================================
    func generateDataStructures() {
        arrayPhotos = Array<PHAsset>()
        let options = PHFetchOptions()

        var picIdentifiers = Array<String>()
        if let theTag = tag {
            for pic: Picture in (tag?.pics.allObjects as! [Picture]) {
                picIdentifiers.append(pic.identifier)
            }
            
            if (picIdentifiers.count > 0) {
                if let filteredResults = PHAsset.fetchAssetsWithLocalIdentifiers(picIdentifiers, options: nil) {
                    for var i = 0; i < filteredResults.count; i++ {
                        if let asset = filteredResults.objectAtIndex(i) as? PHAsset {
                            self.arrayPhotos.append(asset)
                        }
                    }
                }
            }
        }
        else {
            if let results = PHAsset.fetchAssetsWithMediaType(.Image, options: options) {
                results.enumerateObjectsUsingBlock({ (object, index, _) -> Void in
                    if let asset = object as? PHAsset {
                        self.arrayPhotos.append(asset)
                    }
                })
            }
        }
        
        btnCount.title = "\(arrayPhotos.count)"
    }
    
    // ================================================================================
    // MARK: - IBAction
    // ================================================================================
    func btnTagPhoto_TouchUpInside(sender: UIBarButtonItem) {
        performSegueWithIdentifier("showTagSelector", sender: self)
    }
    
    func btnUntagPhoto_TouchUpInside(sender: UIBarButtonItem) {
        var noGo = Array<String>()
        for asset: PHAsset in selectedPhotos {
            noGo.append(asset.localIdentifier)
        }
        
        var picsArray = Array<Picture>()
        for pic: Picture in tag?.pics.allObjects as! [Picture] {
            if !(noGo as NSArray).containsObject(pic.identifier) {
                picsArray.append(pic)
            }
        }
        
        addTagWithName(tag!.name, pics: picsArray)
    }
    
    @IBAction func btnHideShowTagged_TouchUpInside(sender: UIBarButtonItem) {
        if !isFiltering {
            isFiltering = true
            performSegueWithIdentifier("showTagSelector", sender: self)
        }
        else {
            btnHideShowTagged.title = "Hide Tagged"
            isFiltering = false
            btnCount.title = "\(arrayPhotos.count)"
            self.collectionViewPhotos.reloadData()
        }
        
    }

    @IBAction func btnSelectDeselectAll_TouchUpInside(sender: UIBarButtonItem) {
        selectedPhotos = Array<PHAsset>()
        if btnSelectDeselectAll.tag == 0 {
           btnSelectDeselectAll.tag = 1
            btnSelectDeselectAll.title? = "Deselect All"
            for asset: PHAsset in arrayPhotos {
                selectedPhotos.append(asset)
            }
            btnTag?.enabled = true
        }
        else {
            btnSelectDeselectAll.tag = 0
            btnSelectDeselectAll.title? = "Select All"
            btnTag?.enabled = false
        }
        collectionViewPhotos.reloadData()
        
    }
    // ================================================================================
    // MARK: - TagSelectingViewControllerDelegate
    // ================================================================================
    func didCancel() {
        isFiltering = false
        selectedPhotos = Array<PHAsset>()
        lastSelectedIndexPath = nil
    }
    
    func didSaveWithTags(tags: Array<Tag>!) {
        if isFiltering {
            arrayFilteredPhotos = Array<PHAsset>()
            var notToShow = Array<String>()
            for tag: Tag in tags {
                for pic: Picture in (tag.pics.allObjects as! [Picture]) {
                    notToShow.append(pic.identifier)
                }
            }
            for asset: PHAsset in arrayPhotos {
                if !(notToShow as NSArray).containsObject(asset.localIdentifier) {
                    arrayFilteredPhotos.append(asset)
                }
            }
            
            if arrayFilteredPhotos.count >= 0 && arrayFilteredPhotos.count < arrayPhotos.count{
                btnCount.title = "\(arrayFilteredPhotos.count)"
                btnHideShowTagged.title = "Show All"
                self.collectionViewPhotos.reloadData()
            }
            else {
                isFiltering = false
            }
        }
        else {
            for pic: PHAsset in selectedPhotos {
                addPictureWithIdentifier(pic.localIdentifier, tags: tags)
            }
            
            selectedPhotos = Array<PHAsset>()
            lastSelectedIndexPath = nil
        }
        
        collectionViewPhotos.reloadData()
    }
    
    // ================================================================================
    // MARK: - PictureViewControllerDelegate
    // ================================================================================
    func startedSelectingWithPicure(picture: Picture) {
        selectMode = .SELECT
        btnTag?.enabled = true
        collectionView(collectionViewPhotos, didSelectItemAtIndexPath: lastSelectedIndexPath!)
    }
    
    // ================================================================================
    // MARK: - UICollectionViewDataSource / Delegate
    // ================================================================================
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isFiltering {
            return arrayFilteredPhotos.count
        }
        return arrayPhotos.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell = collectionViewPhotos.dequeueReusableCellWithReuseIdentifier("PhotoCell", forIndexPath: indexPath) as! PhotoCell
        cell.imageViewSelected.hidden = true
        var currentCellTag = cell.tag + 1
        cell.tag = currentCellTag
        var asset: PHAsset! = nil
        if isFiltering {
            asset = arrayFilteredPhotos[indexPath.item]
        }
        else {
            asset = arrayPhotos[indexPath.item]
        }
        
        if (selectedPhotos as NSArray).containsObject(asset) {
            cell.imageViewSelected.hidden = false
        }
        let options = PHImageRequestOptions()
        options.synchronous = false
        cachingImageManager.requestImageForAsset(asset, targetSize: imageSize, contentMode: .AspectFill, options: options, resultHandler: { (result: UIImage! ,  _) -> Void in
            if cell.tag == currentCellTag {
                cell.imageViewPicture.image = result
            }
        })

        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        lastSelectedIndexPath = indexPath
        let cell = self.collectionViewPhotos.cellForItemAtIndexPath(indexPath) as? PhotoCell
        var selectedAsset: PHAsset! = nil
        if isFiltering {
            selectedAsset = arrayFilteredPhotos[indexPath.item] as PHAsset
        }
        else {
            selectedAsset = arrayPhotos[indexPath.item] as PHAsset
        }
        
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
            if selectedPhotos.count > 0 {
                btnTag?.enabled = true
                if isFiltering {
                    btnCount.title = "\(selectedPhotos.count) - (\(arrayFilteredPhotos.count))"
                }
                else {
                    btnCount.title = "\(selectedPhotos.count) - (\(arrayPhotos.count))"
                }
                
            }
            else {
                btnTag?.enabled = false
                if isFiltering {
                    btnCount.title = "\(arrayFilteredPhotos.count)"
                }
                else {
                    btnCount.title = "\(arrayPhotos.count)"
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
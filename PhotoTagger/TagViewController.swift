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

class TagViewController: DefaultViewController, UINavigationControllerDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, TagSelectingViewControllerDelegate, PictureViewControllerDelegate, NSFetchedResultsControllerDelegate {
    
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
    var lastSelected: Picture! = nil
    var lastSelectedIndexPath: NSIndexPath?
    var btnTag: UIBarButtonItem?
    var initing = true
    var isFiltering = false
    var isTagging = false
    var picsFetchController: NSFetchedResultsController! = nil
    var picsDict: Dictionary<String, Picture>! = nil
    
    // ================================================================================
    // MARK: - Lifecycle
    // ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        //UIPasteboard.generalPasteboard().string = ""
        let managedContext = appDelegate.managedObjectContext!
        let picsFetchRequest = NSFetchRequest(entityName: "Picture")
        picsFetchRequest.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        picsFetchController = NSFetchedResultsController(fetchRequest: picsFetchRequest, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: "TagsViewControllerPics")
        picsFetchController.delegate = self
        var error: NSError?
        picsFetchController.performFetch(&error)
        if let theError = error {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        buildDictionary()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        collectionViewCellSize = ((UIScreen.mainScreen().nativeBounds.width / UIScreen.mainScreen().scale) - 4) / 3
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
            view.isTagging = self.isTagging
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
    func buildDictionary() {
        picsDict = Dictionary<String, Picture>()
        for pic: Picture in (picsFetchController.fetchedObjects as! [Picture]) {
            picsDict[pic.identifier] = pic
        }
    }
    
    // ================================================================================
    // MARK: - NSFetchedResultsControllerDelegate
    // ================================================================================
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        buildDictionary()
        collectionViewPhotos.reloadData()
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
        isTagging = true
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
        
        updateInsertTagWithName(tag!.name, pics: picsArray)
        save()
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
        isTagging = false
    }
    
    func didSaveWithTags(tags: Array<Tag>!) {
        for pic: PHAsset in selectedPhotos {
            updateInsertPictureWithIdentifier(pic.localIdentifier, tags: tags)
        }
        save()
        
        generateDataStructures()
        collectionViewPhotos.reloadData()
        
        selectedPhotos = Array<PHAsset>()
        lastSelectedIndexPath = nil
        
        collectionViewPhotos.reloadData()
        isTagging = false
    }
    
    func didFilterWithTags(tags: Array<Tag>!) {
        isTagging = false
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
            if ((picsDict as NSDictionary).allKeys as NSArray).containsObject(selectedAsset.localIdentifier) {
                lastSelected = picsDict[selectedAsset.localIdentifier]
            }
            else {
                updateInsertPictureWithIdentifier(selectedAsset.localIdentifier, tags: Array<Tag>())
                save()
                lastSelected = (picsFetchController.fetchedObjects as! [Picture]).last
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
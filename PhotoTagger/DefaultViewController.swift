//
//  DefaultViewController.swift
//  PhotoTagger
//
//  Created by Otavio Zabaleta on 30/03/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit
import Foundation
import CoreData

let screenScale = UIScreen.mainScreen().scale

class DefaultViewController: UIViewController {
    lazy var appDelegate: AppDelegate = {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate
    }()
    
    func updateInsertTagWithName(name: String) {
        updateInsertTagWithName(name, pics: Array<Picture>())
    }
    
    func updateInsertTagWithName(name: String, pics: Array<Picture>) {
        // 1 - get managed context
        let managedContext = appDelegate.managedObjectContext!
        
        // 2 - Check if we already have it
        let fetchRequest = NSFetchRequest(entityName: "Tag")
        fetchRequest.predicate = NSPredicate(format: "name = '\(name)'")
        
        var error: NSError? = nil
        var fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [Tag]
        if let theError = error  {
            println("Could not fetch \(error)")
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
        }
    }
    
    func updateInsertPictureWithIdentifier(identifier: String) {
        updateInsertPictureWithIdentifier(identifier, tags: Array<Tag>())
    }
    
    func updateInsertPictureWithIdentifier(identifier: String, tags: [Tag]) {
        // 1 - get managed context
        let managedContext = appDelegate.managedObjectContext!
        
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        fetchRequest.predicate = NSPredicate(format: "identifier = '\(identifier)'")
        var error: NSError? = nil
        var fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as! [Picture]
        if let theError = error  {
            println("Could not fetch \(error), \(error)")
        }
        else {
            // 2 - Check if we already have it
            var newPicture: Picture
            if fetchedResults.count == 0 {
                newPicture = NSEntityDescription.insertNewObjectForEntityForName("Picture", inManagedObjectContext: managedContext) as! Picture
            }
            else {
                newPicture = (fetchedResults as NSArray).objectAtIndex(0) as! Picture
            }
            
            // 3 - Link to previous + selected tags
            newPicture.identifier = identifier
            var finalArray = Array<Tag>()
            for tag: Tag in newPicture.tags.allObjects as! [Tag] {
                finalArray.append(tag)
            }
            for tag: Tag in tags {
                if !(finalArray as NSArray).containsObject(tag) {
                    finalArray.append(tag)
                }
            }
            newPicture.tags = NSSet(array: finalArray)
        }
    }
    
    func save() -> Bool {
        let managedContext = appDelegate.managedObjectContext!
        var error: NSError?
        if !managedContext.save(&error) {
            println("Could not save tag: \(error), \(error?.userInfo)")
            return false
        }
        return true
    }
}
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
    
    func addTagWithName(name: String) {
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
        else if fetchedResults?.count == 0 {
            //3 - Insert new
            let entity = NSEntityDescription.entityForName("Tag", inManagedObjectContext: managedContext)
            let newTag: Tag = NSEntityDescription.insertNewObjectForEntityForName("Tag", inManagedObjectContext: managedContext) as! Tag
            //let newTag = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            
            // 4 - Set value for tag.name and save
            newTag.name = name
            
            var error: NSError?
            if !managedContext.save(&error) {
                println("Could not save tag: \(error), \(error?.userInfo)")
            }
        }
    }
    
    func addPictureWithIdentifier(identifier: String) {
        // 1 - get managed context
        let managedContext = appDelegate.managedObjectContext!

        // 2 - Check if we already have it
        let fetchRequest = NSFetchRequest(entityName: "Picture")
        fetchRequest.predicate = NSPredicate(format: "identifier = '\(identifier)'")

        var error: NSError? = nil
        var fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [Picture]
        if let theError = error  {
            println("Could not fetch \(error), \(error)")
        }
        else if fetchedResults?.count == 0 {
            //3 - Insert new
            let newPicture: Picture = NSEntityDescription.insertNewObjectForEntityForName("Picture", inManagedObjectContext: managedContext) as! Picture

            // 4 - Set value for tag.name and save
            newPicture.identifier = identifier

            var error: NSError?
            if !managedContext.save(&error) {
                println("Could not save tag: \(error), \(error?.userInfo)")
            }
        }
    }
    
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
            var error: NSError?
            if !managedContext.save(&error) {
                println("Could not save tag: \(error), \(error?.userInfo)")
            }
        }
    }
}

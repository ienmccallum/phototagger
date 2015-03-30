//
//  ViewController.swift
//  PhotoTagger
//
//  Created by Otávio Zabaleta on 29/03/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: DefaultViewController, UITableViewDataSource, UITableViewDelegate {
    /*** IBOutlets ***/
    @IBOutlet weak var tableViewMain: UITableView!
    /*** CoreData ***/
    var tags = [Tag]()
    
    // ================================================================================
    // MARK: - Lifecycle
    // ================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Tag")

        var error: NSError?
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [Tag]
        if fetchedResults != nil {
            tags = fetchedResults!
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // ================================================================================
    // MARK: - IBAction
    // ================================================================================
    @IBAction func buttonAddTag_TouchUpInside(sender: UIBarButtonItem) {
        var alert = UIAlertController(title: "New Tag", message: "Add new tag", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in }
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action: UIAlertAction!) -> Void in
            let textField = alert.textFields![0] as UITextField
            if textField.text != "" {
                self.saveName(textField.text)
                self.tableViewMain.reloadData()
            }
        }
        alert.addAction(saveAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action: UIAlertAction!) -> Void in
            
        }
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // ================================================================================
    // MARK: - Private
    // ================================================================================
    func saveName(name: String) {
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
            let newTag: Tag = NSEntityDescription.insertNewObjectForEntityForName("Tag", inManagedObjectContext: managedContext) as Tag
            //let newTag = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
            
            // 4 - Set value for tag.name and save
            newTag.name = name
            
            var error: NSError?
            if !managedContext.save(&error) {
                println("Could not save tag: \(error), \(error?.userInfo)")
            }
            
            tags.append(newTag)
        }
    }
   

    // ================================================================================
    // MARK: - UITableViewDatasource
    // ================================================================================
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1;
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count;
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableViewMain.dequeueReusableCellWithIdentifier("CellMainTable", forIndexPath: indexPath) as UITableViewCell
        let tag = tags[indexPath.row]
        cell.textLabel!.text = tag.name
        return cell;
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.0
    }
}
//
//  TagSelectingViewController.swift
//  PhotoTagger
//
//  Created by Otávio Zabaleta on 11/04/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit
import CoreData

protocol TagSelectingViewControllerDelegate {
    func didCancel()
    func didSaveWithTags(Array<Tag>!)
}

class TagSelectingViewController: DefaultViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    var selectedTags: Array<Tag>! = Array<Tag>()
    var delegate: TagSelectingViewControllerDelegate?
    var pictures: Array<Picture>! = Array<Picture>()
    var tagsFetchController: NSFetchedResultsController! = nil
    
    @IBOutlet weak var tableViewTags: UITableView!
    @IBOutlet weak var btnSave: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequestTags = NSFetchRequest(entityName: "Tag")
        fetchRequestTags.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        tagsFetchController = NSFetchedResultsController(fetchRequest: fetchRequestTags, managedObjectContext: managedContext, sectionNameKeyPath: nil, cacheName: "Master")
        tagsFetchController.delegate = self
        var error: NSError?
        tagsFetchController.performFetch(&error)
        if let theError = error {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
        else {
            tableViewTags.reloadData()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    // ================================================================================
    // MARK: - Private
    // ================================================================================
   
    
    // ================================================================================
    // MARK: - NSFetchedResultsControllerDelegate
    // ================================================================================
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableViewTags.reloadData()
    }
    
    // ================================================================================
    // MARK: - IBAction
    // ================================================================================
    @IBAction func btnCancel_TouchUpInside(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            self.delegate!.didCancel()
        })
    }
    
    @IBAction func btnSave_TouchUpInside(sender: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: { () -> Void in
            self.delegate!.didSaveWithTags(self.selectedTags)
        })
    }
    
    @IBAction func btnAddTag_TouchUpInside(sender: UIBarButtonItem) {
        var alert = UIAlertController(title: "New Tag", message: "Add new tag", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in }
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action: UIAlertAction!) -> Void in
            let textField = alert.textFields![0] as! UITextField
            if textField.text != "" {
                self.addTagWithName(textField.text)
            }
        }
        alert.addAction(saveAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action: UIAlertAction!) -> Void in
            
        }
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    // ================================================================================
    // MARK: - UITableViewDataSource / Delegate
    // ================================================================================
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tagsFetchController.fetchedObjects!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("CellTag", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = (tagsFetchController.fetchedObjects![indexPath.row] as! Tag).name
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        let theTag = tagsFetchController.fetchedObjects![indexPath.row] as! Tag
        self.selectedTags.append(theTag)
        self.btnSave?.enabled = true
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = UITableViewCellAccessoryType.None
        let theTag = tagsFetchController.fetchedObjects![indexPath.row] as! Tag
        let index = (self.selectedTags as NSArray).indexOfObject(theTag)
        self.selectedTags.removeAtIndex(index)
        if(self.selectedTags.count == 0) {
            self.btnSave?.enabled = false
        }
    }
}
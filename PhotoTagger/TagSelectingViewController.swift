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

class TagSelectingViewController: DefaultViewController, UITableViewDataSource, UITableViewDelegate {
    var selectedTags: Array<Tag>! = Array<Tag>()
    var delegate: TagSelectingViewControllerDelegate?
    var tags: Array<Tag>! = Array<Tag>()
    var pictures: Array<Picture>! = Array<Picture>()
    
    @IBOutlet weak var tableViewTags: UITableView!
    @IBOutlet weak var btnSave: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName: "Tag")
        
        var error: NSError?
        
        let fetchedResults = managedContext.executeFetchRequest(fetchRequest, error: &error) as? [Tag]
        if fetchedResults != nil {
            tags = fetchedResults!
            tableViewTags.reloadData()
        }
        else {
            println("Could not fetch \(error), \(error!.userInfo)")
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
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
    }
    
    // ================================================================================
    // MARK: - UITableViewDataSource / Delegate
    // ================================================================================
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tags.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell = tableView.dequeueReusableCellWithIdentifier("CellTag", forIndexPath: indexPath) as! UITableViewCell
        cell.textLabel?.text = tags[indexPath.row].name
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        cell!.accessoryType = UITableViewCellAccessoryType.Checkmark
        let theTag = (self.tags as NSArray).objectAtIndex(indexPath.row) as! Tag
        self.selectedTags.append(theTag)
        self.btnSave?.enabled = true
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        var cell = tableView.cellForRowAtIndexPath(indexPath)
        cell?.accessoryType = UITableViewCellAccessoryType.None
        let theTag = (self.tags as NSArray).objectAtIndex(indexPath.row) as! Tag
        let index = (self.selectedTags as NSArray).indexOfObject(theTag)
        self.selectedTags.removeAtIndex(index)
        if(self.selectedTags.count == 0) {
            self.btnSave?.enabled = false
        }
    }
}
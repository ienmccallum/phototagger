//
//  ViewController.swift
//  PhotoTagger
//
//  Created by Otávio Zabaleta on 29/03/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: DefaultViewController, UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate {
    /*** IBOutlets ***/
    @IBOutlet weak var tableViewMain: UITableView!
    var barButtonAdd: UIBarButtonItem! = nil
    var barButtonDelete: UIBarButtonItem! = nil
    /*** CoreData ***/
    var selectedTag: Tag?
    var arraySelectedTags = Array<NSIndexPath>()
    var tagsFetchController: NSFetchedResultsController! = nil
    
    // ================================================================================
    // MARK: - Lifecycle
    // ================================================================================
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
            tableViewMain.reloadData()
        }
        
        barButtonDelete = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Trash, target: self, action: Selector("deletePressed"))
        barButtonAdd = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Add, target: self, action: Selector("addPressed"))
        self.navigationItem.rightBarButtonItem = self.barButtonAdd
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showTag" {
            let tagViewController = segue.destinationViewController as! TagViewController
            tagViewController.tag = selectedTag
        }
    }
    
    @IBAction func btnEdit_TouchUpInside(sender: UIBarButtonItem) {
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.tableViewMain.editing = !self.tableViewMain.editing
        }) { (Bool) -> Void in
            self.arraySelectedTags = Array<NSIndexPath>()
            if self.tableViewMain.editing {
                self.navigationItem.rightBarButtonItem = self.barButtonDelete
                self.barButtonDelete.enabled = false
            }
            else {
                self.navigationItem.rightBarButtonItem = self.barButtonAdd
            }
        }
    }
    // ================================================================================
    // MARK: - Private
    // ================================================================================
    func addPressed() {
        var alert = UIAlertController(title: "New Tag", message: "Add new tag", preferredStyle: .Alert)
        alert.addTextFieldWithConfigurationHandler { (textField: UITextField!) -> Void in }
        
        let saveAction = UIAlertAction(title: "Save", style: .Default) { (action: UIAlertAction!) -> Void in
            let textField = alert.textFields![0] as! UITextField
            if textField.text != "" {
                self.addTagWithName(textField.text)
                self.tableViewMain.reloadData()
            }
        }
        alert.addAction(saveAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .Default) { (action: UIAlertAction!) -> Void in
            
        }
        alert.addAction(cancelAction)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func deletePressed() {
        
    }

    
    // ================================================================================
    // MARK: - NSFetchedResultsControllerDelegate
    // ================================================================================
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        tableViewMain.reloadData()
    }
    
    // ================================================================================
    // MARK: - UITableViewDatasource / Delegate
    // ================================================================================
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else {
            return tagsFetchController.fetchedObjects!.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        if indexPath.section == 0 {
            cell = tableViewMain.dequeueReusableCellWithIdentifier("CellAllImages", forIndexPath: indexPath)as! UITableViewCell
        }
        else {
            cell = tableViewMain.dequeueReusableCellWithIdentifier("CellTag", forIndexPath: indexPath) as! UITableViewCell
        }

        let lblTitle = cell.viewWithTag(1) as! UILabel
        
        if indexPath.section == 0 {
            lblTitle.text = "All photos"
            
        }
        else {
            let tag = tagsFetchController.fetchedObjects![indexPath.row] as! Tag
            lblTitle.text = tag.name
            let lblCount = cell.viewWithTag(2) as! UILabel
            lblCount.text = ""
            if tag.pics.count > 0 {
                lblCount.text = "\(tag.pics.count)"
            }
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !tableViewMain.editing {
            if indexPath.section == 0 {
                selectedTag = nil
            }
            else {
                selectedTag = tagsFetchController.fetchedObjects![indexPath.row] as? Tag
            }
            performSegueWithIdentifier("showTag", sender: self)
        }
        else {
            if !(arraySelectedTags as NSArray).containsObject(indexPath) {
                arraySelectedTags.append(indexPath)
                barButtonDelete.enabled = true
            }
            
        }
    }
    
    func tableView(tableView: UITableView, didDeselectRowAtIndexPath indexPath: NSIndexPath) {
        let index = (arraySelectedTags as NSArray).indexOfObject(indexPath)
        arraySelectedTags.removeAtIndex(index)
        if arraySelectedTags.count == 0 {
            barButtonDelete.enabled = false
        }
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        var header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 44))
        var label = UILabel(frame: CGRect(x: 10, y: 0, width: header.frame.width - 10, height: header.frame.height))
        if section == 0 {
            label.text = "Photo Library"
        }
        else {
            label.text = "Tags"
        }
        header.addSubview(label)
        return header
    }
}
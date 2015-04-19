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
    /*** CoreData ***/
    var selectedTag: Tag?
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
    
    // ================================================================================
    // MARK: - IBAction
    // ================================================================================
    @IBAction func buttonAddTag_TouchUpInside(sender: UIBarButtonItem) {
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
    
    // ================================================================================
    // MARK: - Private
    // ================================================================================
    
    
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
        if indexPath.section == 0 {
            selectedTag = nil
        }
        else {
            selectedTag = tagsFetchController.fetchedObjects![indexPath.row] as? Tag
        }
        performSegueWithIdentifier("showTag", sender: self)
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
//
//  Tag.swift
//  PhotoTagger
//
//  Created by Otávio Zabaleta on 26/04/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import Foundation
import CoreData

class Tag: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var creationDate: NSDate
    @NSManaged var pics: NSSet

}

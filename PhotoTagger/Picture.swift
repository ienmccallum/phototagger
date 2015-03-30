//
//  ManagedPicture.swift
//  PhotoTagger
//
//  Created by Otavio Zabaleta on 30/03/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import Foundation
import CoreData

class Picture: NSManagedObject {

    @NSManaged var date: NSDate
    @NSManaged var image: String
    @NSManaged var tags: NSSet

}

//
//  ManagedTag.swift
//  PhotoTagger
//
//  Created by Otavio Zabaleta on 30/03/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import Foundation
import CoreData

class Tag: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var forbiddenPics: NSSet
    @NSManaged var pics: NSSet

}

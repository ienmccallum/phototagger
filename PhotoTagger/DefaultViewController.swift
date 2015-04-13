//
//  DefaultViewController.swift
//  PhotoTagger
//
//  Created by Otavio Zabaleta on 30/03/2015.
//  Copyright (c) 2015 OZ. All rights reserved.
//

import UIKit
import Foundation

class DefaultViewController: UIViewController {
    lazy var appDelegate: AppDelegate = {
        let delegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return delegate
    }()
    
    lazy var screenScale: CGFloat = {
        let scale = UIScreen.mainScreen().scale
        return scale
    }()
}

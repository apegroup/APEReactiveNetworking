//
//  NetworkActivityIndicator.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-05-27.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import UIKit

class NetworkActivityIndicator {
    
    //Singelton
    static let sharedInstance = NetworkActivityIndicator()  //Swift complier will execute this as a dispatch_once thus guarantee thread-safety
    
    //This prevents others from using the default '()' initializer for this class.
    private init() {
        enabled = false
    }
    
    private var count : Int = 0
    
    var enabled : Bool {
        didSet {
            if enabled {
                count += 1
            } else {
                count = max(0, (count - 1))
            }
            
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.4 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                UIApplication.sharedApplication().networkActivityIndicatorVisible = (self.count > 0)
            }
        }
    }
    
}
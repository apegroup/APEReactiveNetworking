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
    
    //Singleton
    static let sharedInstance = NetworkActivityIndicator()
    
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                UIApplication.shared.isNetworkActivityIndicatorVisible = (self.count > 0)
            }
        }
    }
}

//
//  UIViewController+Presentation.swift
//  Example
//
//  Created by Magnus Eriksson on 15/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit

extension UIViewController {
    
    func currentlyPresentedViewController() -> UIViewController {
        var current = self
        
        while let next = current.presentedViewController {
            current = next
        }
        return current
    }
}
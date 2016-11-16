//
//  UIStoryboard+Scenes.swift
//  Example
//
//  Created by Magnus Eriksson on 2016-11-01.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit

extension UIStoryboard {
    static var loginScene: UIStoryboard {
        return UIStoryboard(name: "Login", bundle: nil)
    }
    static var userScene: UIStoryboard {
        return UIStoryboard(name: "User", bundle: nil)
    }
}

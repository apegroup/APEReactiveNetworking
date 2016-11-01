//
//  UIImage+Resize.swift
//  Example
//
//  Created by Magnus Eriksson on 2016-11-01.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit

extension UIImage {
    func resized(to newWidth: CGFloat) -> UIImage {
        let scale = newWidth / size.width
        let newHeight = size.height * scale
        UIGraphicsBeginImageContext(CGSize(width:newWidth, height: newHeight))
        draw(in: CGRect(x:0, y:0, width:newWidth, height:newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage!
    }
}

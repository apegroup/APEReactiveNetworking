//
//  UserCell.swift
//  Example
//
//  Created by Magnus Eriksson on 15/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import UIKit

class UserCell: UITableViewCell {
    
    override var reuseIdentifier: String? {
        return "\(type(of: self))"
    }
}

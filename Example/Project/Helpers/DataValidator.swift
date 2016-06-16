//
//  DataValidator.swift
//  Example
//
//  Created by Magnus Eriksson on 16/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

struct DataValidator {
    
    func isValidUsername(username: String) -> Bool {
        return username.characters.count > 3
    }
    
    func isValidPassword(password: String) -> Bool {
        return !password.characters.isEmpty
    }
}
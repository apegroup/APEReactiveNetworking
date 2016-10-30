//
//  User.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 26/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import Unbox
import Wrap

struct User {
    let username: String
}

//MARK: Unboxable

extension User: Unboxable {
    init(unboxer: Unboxer) throws {
        self.username = try unboxer.unbox(key: "username")
    }
}

// MARK: Wrap

extension User: WrapCustomizable {
    func keyForWrappingPropertyNamed(propertyName: String) -> String {
        switch propertyName {
        case "username":        return "username"
        default:                return propertyName
        }
    }
}


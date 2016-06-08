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
    let userId : String
    let firstName: String
    let lastName: String
    let gender: String //Enum?
    let createdAt: NSDate
    let birthYear: Int //Date?
    let avatarUrl: String
}

//MARK: Unboxable

extension User: Unboxable {
    init(unboxer: Unboxer) {
        self.userId = unboxer.unbox("userId")
        self.firstName = unboxer.unbox("firstname")
        self.lastName = unboxer.unbox("lastname")
        self.gender = unboxer.unbox("gender")
        self.createdAt = unboxer.unbox("createdAt", formatter: NSDate.iso8601DateFormatter())
        self.birthYear = unboxer.unbox("birthyear")
        self.avatarUrl = unboxer.unbox("avatarUrl")
    }
}

// MARK: Wrap

extension User: WrapCustomizable {
    func keyForWrappingPropertyNamed(propertyName: String) -> String {
        switch propertyName {
        case "firstName":
            return "firstname"
        case "lastName":
            return "lastname"
        case "birthYear":
            return "birthyear"
        default:
            return propertyName
        }
    }
}


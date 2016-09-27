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
    let createdAt: Date
    let birthYear: Int //Date?
    let avatarUrl: String
}

//MARK: Unboxable

extension User: Unboxable {
    init(unboxer: Unboxer) throws {
        self.userId = try unboxer.unbox(key: "userId")
        self.firstName = try unboxer.unbox(key: "firstname")
        self.lastName = try unboxer.unbox(key: "lastname")
        self.gender = try unboxer.unbox(key: "gender")
        self.createdAt = try unboxer.unbox(key: "createdAt", formatter: Date.iso8601DateFormatter)
        self.birthYear = try unboxer.unbox(key: "birthyear")
        self.avatarUrl = try unboxer.unbox(key: "avatarUrl")
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


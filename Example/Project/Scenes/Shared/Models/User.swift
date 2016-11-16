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
    var avatar: Data?
}

//MARK: Unboxable

extension User: Unboxable {
    init(unboxer: Unboxer) throws {
        username = try unboxer.unbox(key: "username")
        
        if let base64Encoded: String = unboxer.unbox(key: "avatar"),
            let decodedAvatar = Data(base64Encoded: base64Encoded) {
            avatar = decodedAvatar
        }
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


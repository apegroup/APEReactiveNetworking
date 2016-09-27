//
//  AuthResponse.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 26/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import Unbox

struct AuthResponse {
    let accessToken: String
    let user: User
}

extension AuthResponse: Unboxable {
    init(unboxer: Unboxer) throws {
        self.accessToken = try unboxer.unbox(key: "token")
        self.user = try unboxer.unbox(key: "user")
    }
}


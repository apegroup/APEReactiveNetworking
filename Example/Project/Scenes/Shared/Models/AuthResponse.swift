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
    let accessToken : String
    let user : User
}

extension AuthResponse: Unboxable {
    init(unboxer: Unboxer) {
        self.accessToken = unboxer.unbox("token")
        self.user = unboxer.unbox("user")
    }
}


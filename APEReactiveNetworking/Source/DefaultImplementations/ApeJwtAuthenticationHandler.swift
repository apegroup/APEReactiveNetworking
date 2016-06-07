//
//  ApeJwtAuthenticationHandler.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 26/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

struct ApeJwtAuthenticationHandler : AuthenticationHandler {

    ///Returns a formatted HTTP Authorization header value
    var authHeader: String? {
        guard let token = KeychainManager.jwtToken() else {
            return nil
        }
        return "Bearer \(token)"
    }

    ///Saves the received token to the Keychain
    func handleAuthTokenReceived(token: String) {
        let saved = KeychainManager.saveJwtToken(token)
        precondition(saved, "Error occurred when saving http auth token")
    }
}

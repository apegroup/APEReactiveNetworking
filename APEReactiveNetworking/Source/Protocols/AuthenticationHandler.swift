//
//  AuthenticationHandler.swift
//  APEReactiveNetworking
//
//  Created by Dennis Korkchi on 07/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

protocol AuthenticationHandler {
    var authHeader: String? { get }
    func handleAuthTokenReceived(token: String) -> ()
}


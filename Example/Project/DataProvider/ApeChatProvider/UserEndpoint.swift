//
//  ApeChatApiEndpoints.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-05-06.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import APEReactiveNetworking

enum UserEndpoint: Endpoint {
    
    //MARK: - Endpoints
    
    case register
    case login
    case currentUser
    case allUsers
    
    //MARK: - Endpoint protocol conformance
    
    var httpMethod : Http.Method {
        switch self {
        case .register, .login:             return .post
        default:                            return .get
        }
    }
    
    var absoluteUrl: String {
        let userPath = "/users"
        
        let relativePath: String
        switch self {
        case .register:
            relativePath = "/register"
        case .login:
            relativePath = "/login"
        case .currentUser:
            relativePath = "/me"
        case .allUsers:
            relativePath = ""
        }
        
        return AppConfiguration.environment.baseUrl + userPath + relativePath
    }
    
    var acceptedResponseCodes : [Http.StatusCode] {
        switch self {
        default:                return [.ok]
        }
    }
}

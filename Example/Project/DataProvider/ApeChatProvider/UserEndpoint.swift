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
    case user(username: String)
    case allUsers
    case currentUser
    case updateAvatar
    
    //MARK: - Endpoint protocol conformance
    
    var httpMethod : Http.Method {
        switch self {
        case .register, .login, .updateAvatar:             return .post
        default:                                           return .get
        }
    }
    
    var absoluteUrl: String {
        let userPath = "/users"
        
        let relativePath: String
        switch self {
        case .register:                             relativePath = "/register"
        case .login:                                relativePath = "/login"
        case .allUsers:                             relativePath = ""
        case .user(let username):                   relativePath = "/\(username)"
        case .currentUser, .updateAvatar:           relativePath = "/me"
        }
        
        return AppConfiguration.environment.baseUrl + userPath + (relativePath.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed))!
    }
    
    var acceptedResponseCodes : [Http.StatusCode] {
        switch self {
        default:                return [.ok]
        }
    }
}

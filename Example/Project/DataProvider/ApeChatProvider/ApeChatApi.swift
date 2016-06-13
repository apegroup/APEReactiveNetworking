//
//  ApeChatApi.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import ReactiveCocoa
import APEReactiveNetworking

// MARK: API Protocol
protocol ApeChatApi {
    //TODO: Replace 'NetworkError' with a more general error 
    //since data is not necessarilly fetched from the network 
    //(e.g. canned data from file, from database, etc)

    // MARK: User

    func authenticateUser(username: String,
                          password: String) -> SignalProducer<AuthResponse, NetworkError>

    func getAllUsers() -> SignalProducer<[User], NetworkError>

    func updateUserAvatar (userId: String, avatar: UIImage) -> SignalProducer<User, NetworkError>
    

    // MARK: Messages

    

    
}


// MARK: API Factory
struct ApeChatApiFactory {
    
    static func create(environment: Environment = AppConfiguration.environment) -> ApeChatApi {
        switch environment {
        case .Debug:    return MockApeChatApiProvider() 
        default:        return NetworkedApeChatApiProvider()
        }
    }
}
//
//  ApeChatApi.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import ReactiveSwift
import APEReactiveNetworking

// MARK: API Protocol
protocol ApeChatApi {
    //TODO: Replace 'NetworkError' with a more general error 
    //since data is not necessarilly fetched from the network 
    //(e.g. canned data from file, from database, etc)

    // MARK: User

    func authenticateUser(_ username: String,
                          password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError>

    func getAllUsers() -> SignalProducer<NetworkDataResponse<[User]>, Network.OperationError>

    func updateUserAvatar(userId: String, avatar: UIImage) -> SignalProducer<NetworkDataResponse<User>, Network.OperationError>
    

    // MARK: Messages

    

    
}


// MARK: API Factory
struct ApeChatApiFactory {
    
    static func make(environment: Environment = AppConfiguration.environment) -> ApeChatApi {
        //FIXME: Remove hard coded value
        return NetworkedApeChatApiProvider()
        
//        switch environment {
//        case .debug:    return MockApeChatApiProvider()
//        default:        return NetworkedApeChatApiProvider()
//        }
    }
}

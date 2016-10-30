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
protocol UserApi {
    //TODO: Replace 'NetworkError' with a more general error 
    //since data is not necessarilly fetched from the network 
    //(e.g. canned data from file, from database, etc)

    func register(username: String, password: String) -> SignalProducer<NetworkDataResponse<User>, Network.OperationError>
    func login(username: String, password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError>
    func getAllUsers() -> SignalProducer<NetworkDataResponse<[User]>, Network.OperationError>
}


// MARK: API Factory
struct UserApiFactory {
    
    static func make(environment: Environment = AppConfiguration.environment) -> UserApi {
        //FIXME: Remove hard coded value
        return NetworkedUserApi()
        
        switch environment {
        case .debug:    return MockUserApi()
        default:        return NetworkedUserApi()
        }
    }
}

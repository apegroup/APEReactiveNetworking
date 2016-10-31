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
    //TODO: Stop leaking details, i.e. replace 'NetworkError' with a more general error since data is not necessarilly
    //fetched from the network (e.g. canned data from file, from database, etc)

    ///Register a user
    func register(username: String, password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError>
    
    ///Authenticate a user
    func login(username: String, password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError>
    
    ///Fetch a list of all users
    func getAllUsers() -> SignalProducer<NetworkDataResponse<[User]>, Network.OperationError>
    
    ///Fetch a detailed view of the currently logged in user
    func getCurrentUser() -> SignalProducer<NetworkDataResponse<User>, Network.OperationError>
    
    ///Fetch a detailed view of the user with username 'username'
    func getUser(_ username: String) -> SignalProducer<NetworkDataResponse<User>, Network.OperationError>
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

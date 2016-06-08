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

    func authenticateUser(username: String,
                          password: String) -> SignalProducer<AuthResponse, NetworkError>

    // MARK: User
    func getAllUsers() -> SignalProducer<[User], NetworkError>

    func getUser(id: String) -> SignalProducer<User, NetworkError>
    
    func updateUserAvatar (userId: String, avatar: UIImage) -> SignalProducer<User, NetworkError>
    
    func updateUser(userId: String, userChanges: AuthResponse) -> SignalProducer<User, NetworkError>
    
    func deleteUser(userId: String) -> SignalProducer<Void, NetworkError>
    
    // MARK: Device
  
    func getDevices(userId: String) -> SignalProducer<[Device], NetworkError>
    
    func addDevice(userId: String, device: Device) -> SignalProducer<Device, NetworkError>
    
    func removeDevice(userId: String, vendorId: String) -> SignalProducer<Void, NetworkError>
    
    
}


// MARK: API Factory
struct ApeChatApiFactory {
    
    static func create(environment: Environment = AppConfiguration.environment) -> ApeChatApi {
        switch environment {
        case .Debug:    return NetworkedApeChatApiProvider() //FIXME
        default:        return NetworkedApeChatApiProvider()
        }
    }
}
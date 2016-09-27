//
//  NetworkedApeChatApiProvider.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import ReactiveSwift
import enum Result.NoError
import APEReactiveNetworking
import Unbox
import Wrap

struct NetworkedApeChatApiProvider: ApeChatApi {
    
    //MARK: ApeChatApi
    
    //Elaborate example
    func authenticateUser(_ username: String, password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError> {
        
        //Endpoint for authenticating a user
        let endpoint: Endpoint = ApeChatApiEndpoints.authUser
        
        //Create a request builder
        let builder : HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)
        
        //Build request
        let jsonDict: [String:Any] = ["user":username, "password":password]
        let request: ApeURLRequest = builder.setBody(json: jsonDict).build()
        
        //Scheduler to handle signal events
        let scheduler: SchedulerProtocol = UIScheduler()
        
        //Max seconds allowed before aborting network operation
        let timeoutSeconds: TimeInterval = 20
        
        //Block for transforming response Data --> AuthenticateUserResponse
        let parseDataBlock: (Data) -> AuthResponse? = { data in
            guard let authResponse = try? unbox(data: data) as AuthResponse else {
                return nil
            }
            return authResponse
        }
        
        return Network().send(request,
                              scheduler: scheduler,
                              abortAfter: timeoutSeconds,
                              parseDataBlock: parseDataBlock)
    }
    
    
    func getAllUsers() -> SignalProducer<NetworkDataResponse<[User]>, Network.OperationError> {
        let request = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.getAllUsers).build()
        return Network().send(request) { try? unbox(data: $0) }
    }
    
    
    func updateUserAvatar(userId: String, avatar: UIImage) -> SignalProducer<NetworkDataResponse<User>, Network.OperationError> {
        let avatarRawData = UIImageJPEGRepresentation(avatar, 0.9)!
        let request = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.updateUserAvatar(userId: userId))
            .setBody(data: avatarRawData, contentType: .imageJpeg)
            .build()
        return Network().send(request) { try? unbox(data: $0) }
    }
}

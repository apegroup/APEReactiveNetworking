//
//  NetworkedApeChatApiProvider.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import ReactiveSwift
import APEReactiveNetworking
import Unbox

struct NetworkedUserApi: UserApi {
    
    //Elaborate example
    func register(username: String, password: String) -> SignalProducer<NetworkDataResponse<User>, Network.OperationError> {
        
        //1) Specify the endpoint for registering a user
        let endpoint: Endpoint = UserEndpoint.register
        
        //2) Create a request builder
        let builder: HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)
        
        //3) Build your request
        let jsonBody = ["username":username, "password":password]
        let request = builder.setBody(json: jsonBody).build()
        
        //4) Specify scheduler that will handle events from the SignalProducer
        let scheduler: SchedulerProtocol = UIScheduler()
        
        //5) Configure network operation settings, such as timeout and max number of retries
        let timeoutSeconds: TimeInterval = 5
        let maxRetries = 3
        
        //6) If you are expecting data to be returned, specify how to parse it into your desired model
        let userParseBlock: (Data) -> User? = { userData in
            guard let user = try? unbox(data: userData) as User else {
                return nil
            }
            return user
        }
        
        //7) Create the signal producer
        return Network().send(request,
                              scheduler: scheduler,
                              abortAfter: timeoutSeconds,
                              maxRetries: maxRetries,
                              parseDataBlock: userParseBlock)
    }
    
    
    func login(username: String, password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError> {
        let request = ApeRequestBuilder(endpoint: UserEndpoint.login)
            .setBody(json: ["username":username, "password":password])
            .build()
        return Network().send(request) { try? unbox(data: $0) }
    }
    
    func getAllUsers() -> SignalProducer<NetworkDataResponse<[User]>, Network.OperationError> {
        let request = ApeRequestBuilder(endpoint: UserEndpoint.allUsers).build()
        return Network().send(request) { try? unbox(data: $0) }
    }
}

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
    func register(username: String, password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError> {
        
        //1) Specify the endpoint for registering a user
        let endpoint: Endpoint = UserEndpoint.register
        
        //2) Create a request builder
        let builder: HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)
        
        //3) Build your request
        let jsonBody = ["username":username, "password":password]
        let request = builder.setBody(json: jsonBody).build()
        
        //4) Configure network operation settings, such as operation timeout and scheduler that will handle events from the SignalProducer
        let timeoutSeconds: TimeInterval = 5
        let scheduler: SchedulerProtocol = UIScheduler()
        
        //5) If you are expecting data to be returned, specify how to parse it into your desired model
        let authParseBlock: (Data) -> AuthResponse? = { userData in
            guard let user = try? unbox(data: userData) as AuthResponse else {
                return nil
            }
            return user
        }
        
        //6) Create the signal producer
        return Network().send(request,
                              scheduler: scheduler,
                              abortAfter: timeoutSeconds,
                              parseDataBlock: authParseBlock)
    }
    
    
    func login(username: String, password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError> {
        let request = ApeRequestBuilder(endpoint: UserEndpoint.login)
            .setBody(json: ["username":username, "password":password])
            .build()
        return Network().send(request) { try? unbox(data: $0)}
    }
    
    func getAllUsers() -> SignalProducer<NetworkDataResponse<[User]>, Network.OperationError> {
        let request = ApeRequestBuilder(endpoint: UserEndpoint.allUsers)
            .setAuthorizationHeader(token: KeychainManager.jwtToken() ?? "-" )
            .build()
        return Network().send(request) { try? unbox(data: $0)}.handleUnauthorizedResponse()
    }
    
    func getCurrentUser() -> SignalProducer<NetworkDataResponse<User>, Network.OperationError> {
        let request = ApeRequestBuilder(endpoint: UserEndpoint.currentUser)
            .setAuthorizationHeader(token: KeychainManager.jwtToken() ?? "-" )
            .build()
        return Network().send(request) { try? unbox(data: $0)}.handleUnauthorizedResponse()
    }
    
    func updateAvatar(image: UIImage) -> SignalProducer<Http.ResponseHeaders, Network.OperationError> {
        let base64Data = UIImagePNGRepresentation(image)!.base64EncodedData()
        let request = ApeRequestBuilder(endpoint: UserEndpoint.updateAvatar)
            .setAuthorizationHeader(token: KeychainManager.jwtToken() ?? "-")
            .setBody(data: base64Data, contentType: .imagePng)
            .build()
        return Network().send(request)
    }
    
    func getUser(_ username: String) -> SignalProducer<NetworkDataResponse<User>, Network.OperationError> {
        let request = ApeRequestBuilder(endpoint: UserEndpoint.user(username: username))
            .setAuthorizationHeader(token: KeychainManager.jwtToken() ?? "-" )
            .build()
        return Network().send(request) { try? unbox(data: $0)}.handleUnauthorizedResponse()
    }
}

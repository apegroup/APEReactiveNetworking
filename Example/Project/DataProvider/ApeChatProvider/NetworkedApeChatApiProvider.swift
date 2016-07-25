//
//  NetworkedApeChatApiProvider.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import ReactiveCocoa
import enum Result.NoError
import APEReactiveNetworking
import Unbox
import Wrap

struct NetworkedApeChatApiProvider: ApeChatApi {
    
    let authHandler: AuthenticationHandler = ApeJwtAuthenticationHandler()
    
    //MARK: ApeChatApi
    
    //More elaborate example
    func authenticateUser(username: String,
                          password: String) -> SignalProducer<NetworkResponse<AuthResponse>, NetworkError> {
        
        //Endpoint for authenticating a user
        let endpoint: Endpoint = ApeChatApiEndpoints.AuthUser
        
        //Create a request builder
        let builder : HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)
        
        //Build request
        let jsonDict: [String:AnyObject] = ["user":username, "password":password]
        let request: NSURLRequest = builder.setBody(json: jsonDict).build()
        
        //The URLSession to use
        let URLCache = NSURLCache(memoryCapacity: 4 * 1024 * 1024,
                                  diskCapacity: 20 * 1024 * 1024,
                                  diskPath: "URLCache")
        
        let sessionConfig = NSURLSessionConfiguration.defaultSessionConfiguration()
        sessionConfig.URLCache = URLCache
        //Customize sessionConfig even more... (eg cookies etc)
        
        let session = NSURLSession(configuration: sessionConfig)
        
        //Alternative way of setting the cache but try avoid using this since its not recomended by Apple
        //Add the code block in your AppDelegate, didFinishLaunchingWithOptions() method
        /*
         let URLCache = NSURLCache(memoryCapacity: 4 * 1024 * 1024,
         diskCapacity: 20 * 1024 * 1024,
         diskPath: "URLCache")
         
         NSURLCache.setSharedURLCache(URLCache)
         */
        
        
        //Block for transforming response NSData --> AuthenticateUserResponse
        let parseDataBlock: (data:NSData) -> AuthResponse? = { data in
            guard let authResponse = try? Unbox(data) as AuthResponse else {
                return nil
            }
            return authResponse
        }
        
        //Scheduler to handle signal events
        let scheduler: SchedulerType = UIScheduler()
        
        let validator: HttpResponseCodeValidator = ApeResponseCodeValidator()
        
        return Network().send(request,
                              responseCodeValidator: validator,
                              session: session,
                              scheduler: scheduler,
                              abortAfter: 20,
                              parseDataBlock: parseDataBlock)
    }
    
    
    func getAllUsers() -> SignalProducer<NetworkResponse<[User]>, NetworkError> {
        let request = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.GetAllUsers)
            .addAuthHandler(authHandler)
            .build()
        return Network().send(request) { try? Unbox($0) }
    }
    
    
    func updateUserAvatar(userId: String, avatar: UIImage) -> SignalProducer<NetworkResponse<User>, NetworkError> {
        let avatarRawData = UIImageJPEGRepresentation(avatar, 0.9)!
        
        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.UpdateUserAvatar(userId: userId))
            .addAuthHandler(authHandler)
            .setBody(rawData: avatarRawData, contentType: .ImageJpeg)
            .build()
        
        return Network().send(request) { try? Unbox($0) }
    }
}
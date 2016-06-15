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
                          password: String) -> SignalProducer<AuthResponse, NetworkError> {
        
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
                              retry: 3,
                              timeout: 20,
                              parseDataBlock: parseDataBlock)
    }
    
    
    func getAllUsers() -> SignalProducer<[User], NetworkError> {
        let request = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.GetAllUsers)
            .addAuthHandler(authHandler)
            .build()
        return sendAuthenticatedRequest(request) { try? Unbox($0) }
    }
    
    
    func updateUserAvatar(userId: String, avatar: UIImage) -> SignalProducer<User, NetworkError> {
        let avatarRawData = UIImageJPEGRepresentation(avatar, 0.9)!
        
        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.UpdateUserAvatar(userId: userId))
            .addAuthHandler(authHandler)
            .setBody(rawData: avatarRawData, contentType: .ImageJpeg)
            .build()
        
        return sendAuthenticatedRequest(request) { try? Unbox($0) }
    }
    
    
    //MARK: Custom authentication
    
    ///This is a test method that tests the authentication flow (since we don't have a backend to test it against). All API methods which require authentication send their requests through this method
    private func sendAuthenticatedRequest<T>(request: NSURLRequest,
                                          parseDataBlock: ((data:NSData) -> T?)? = nil) -> SignalProducer<T, NetworkError> {
        
        //'failUnlessAuthenticatedSignal' is a signal that will fail unless we are marked as authenticated.
        //The failure-event contains a specific Http Status code which signifies that an Authentication error has occurred.
        let failUnlessAuthenticatedSignal = SignalProducer<T, NetworkError>(){ observer, _disposable in
            guard Authenticated.authed else {
                return observer.sendFailed(.ErrorResponse(httpCode: .Forbidden,reason: "Not authenticated!"))
            }
            observer.sendCompleted()
        }
        
        //'requestSignal' is the actual network-request signal
        let requestSignal = Network().send(request, parseDataBlock: parseDataBlock)
        
        //We create a signal producer of these two signal producers
        let signal = SignalProducer<SignalProducer<T, NetworkError>, Result.NoError>() { observer, _ in
            observer.sendNext(failUnlessAuthenticatedSignal)
            observer.sendNext(requestSignal)
            observer.sendCompleted()
        }
        
        //Finally we concat these two signal producers into a wrapper-signal producer and return it.
        //The wrapper-signal producer will fail when not authenticated (due to the 'failUnlessAuthenticatedSignal') - thus simulating a 'not authenticated' scenario
        //However, if we are authenticated then the 'requestSignal' will be performed.
        
        //This is convenient since we are able to replay the signal! E.g:
        //1) Execute the wrapper signal, which fails since we are not authenticated
        //2) Listen to auth-failures from this signal and authenticate if a failure occurrs
        //3) After authenticating - simply replay the signal!
        return signal.flatten(.Concat)
    }
}

struct Authenticated {
    static var authed = false
}
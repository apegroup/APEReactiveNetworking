//
//  NetworkedApeChatApiProvider.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import ReactiveCocoa
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

        let jsonDict: [String:AnyObject] = ["user":username, "password":password]

        //Create a request builder
        let builder : HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)

        //Build request
        let request: NSURLRequest = builder.setBody(json: jsonDict).build()

        //The URLSession to use
        let session: NSURLSession = NSURLSession.sharedSession()
        
        //Block for transforming NSData --> AuthenticateUserResponse
        let parseDataBlock: (data:NSData) -> AuthResponse? = { data in
            guard let authResponse = try? Unbox(data) as AuthResponse else {
                return nil
            }
            
            // Save the jwt token to be used by subsequent requests
            self.authHandler.handleAuthTokenReceived(authResponse.accessToken)
            
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
        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.GetAllUsers)
            .addAuthHandler(authHandler)
            .build()
        return Network().send(request) { try? Unbox($0) }
    }

    
    func getUser(id: String) -> SignalProducer<User, NetworkError> {
        
        //Build request (note that it uses the authHandler to inject JWT token since the getUser endpoint is protected)
        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.GetUser(userId: id))
            .addAuthHandler(authHandler)
            .build()
        return Network().send(request) { try? Unbox($0) }
    }
    
    
    func updateUserAvatar(userId: String, avatar: UIImage) -> SignalProducer<User, NetworkError> {

        let avatarRawData = UIImageJPEGRepresentation(avatar, 0.9)!

        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.UpdateUserAvatar(userId: userId))
            .addAuthHandler(authHandler)
            .setBody(rawData: avatarRawData, contentType: .ImageJpeg)
            .build()

        return Network().send(request) { try? Unbox($0) }
    }


    func updateUser(userId: String, userChanges: AuthResponse) -> SignalProducer<User, NetworkError> {
        guard let jsonDict : WrappedDictionary = try? Wrap(userChanges, dateFormatter:NSDate.iso8601DateFormatter()) else {
            return SignalProducer<User, NetworkError>(error: NetworkError.ParseFailure) // TODO Better kind of error
        }

        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.UpdateUser(userId: userId))
            .addAuthHandler(authHandler)
            .setBody(json: jsonDict)
            .build()
    
        return Network().send(request) { try? Unbox($0) }
    }

    
    func deleteUser(userId: String) -> SignalProducer<Void, NetworkError> {
        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.DeleteUser(userId: userId))
            .addAuthHandler(authHandler)
            .build()

        return Network().send(request)
    }


    func getDevices(userId: String) -> SignalProducer<[Device], NetworkError> {
        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.GetDevices(userId: userId))
            .addAuthHandler(authHandler)
            .build()
        return Network().send(request) { try? Unbox($0) }
    }


    func addDevice(userId: String, device: Device) -> SignalProducer<Device, NetworkError> {
        guard let jsonDict : WrappedDictionary = try? Wrap(device, dateFormatter:NSDate.iso8601DateFormatter()) else {
            return SignalProducer<Device, NetworkError>(error: NetworkError.ParseFailure) // TODO Better kind of error
        }
        
        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.AddDevice(userId: userId))
            .addAuthHandler(authHandler)
            .setBody(json: jsonDict)
            .build()
        
        return Network().send(request) { try? Unbox($0) }
    }

    
    func removeDevice(userId: String, vendorId: String) -> SignalProducer<Void, NetworkError> {
        let request: NSURLRequest = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.RemoveDevice(userId: userId, vendorId: vendorId))
            .addAuthHandler(authHandler)
            .build()
        return Network().send(request)
    }
    
}
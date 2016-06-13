//
//  MockApeChatApiProvider.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveCocoa
import Unbox
import APEReactiveNetworking

struct MockApeChatApiProvider: ApeChatApi {
    
    //MARK: ApeChatApi
    
    func authenticateUser(username: String,
                          password: String) -> SignalProducer<AuthResponse, NetworkError> {
        return signalProducer()
    }
    
    func getAllUsers() -> SignalProducer<[User], NetworkError> {
        return signalProducer()
    }
    

    func updateUserAvatar (userId: String, avatar: UIImage) -> SignalProducer<User, NetworkError> {
        return signalProducer()
    }





    
    //MARK: Private
    
    private func signalProducer<T: Unboxable>() -> SignalProducer<[T], NetworkError> {
        
        return signalProducer()
    }
    
    ///Returns a signal producer that sends a next event containing a parsed model of type 'T' or a 'ParseFailure' if an error occurred.
    private func signalProducer<T: Unboxable>() -> SignalProducer<T, NetworkError> {
        
        return SignalProducer<T, NetworkError>(){ observer, _disposable in
            guard let model = self.initFromJsonFile(T) else {
                return observer.sendFailed(.ParseFailure)
            }
            
            observer.sendNext(model)
            observer.sendCompleted()
        }
    }
    
    
    /**
     Attempts to load a json file from the main bundle and unbox it to the received model type
     - parameter clazz: The class to convert the contents of the json file
     - returns: An instance of class 'clazz', or nil if an error occurred
     
     **ASSUMPTION** This method assumes that:
     - there is a .json file containing the json required to instantiate the class
     - the .json file resides in the main bundle
     - the .json file has the same name as the class
     */
    private func initFromJsonFile<T: Unboxable>(clazz: T.Type) -> T? {
        guard let path = NSBundle.mainBundle().pathForResource(String(T), ofType: "json"),
            contents = NSData(contentsOfFile: path),
            model = try? Unbox(contents) as T else {
                return nil
        }
        return model
    }
}
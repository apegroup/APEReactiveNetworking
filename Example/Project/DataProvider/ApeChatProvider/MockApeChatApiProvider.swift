//
//  MockApeChatApiProvider.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveSwift
import Unbox
import APEReactiveNetworking

struct MockApeChatApiProvider { //: ApeChatApi {
    
    //MARK: ApeChatApi
    
    func authenticateUser(_ username: String,
                          password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.OperationError> {
        return signalProducer()
    }
    
    func getAllUsers() -> SignalProducer<NetworkDataResponse<[User]>, Network.OperationError> {
        return signalProducer()
    }
    

    func updateUserAvatar (userId: String, avatar: UIImage) -> SignalProducer<NetworkDataResponse<User>, Network.OperationError> {
        return signalProducer()
    }





    
    //MARK: Private
    
    private func signalProducer<T: Unboxable>() -> SignalProducer<NetworkDataResponse<[T]>, Network.OperationError> {
        
        return signalProducer()
    }
    
    ///Returns a signal producer that sends a next event containing a parsed model of type 'T' or a 'ParseFailure' if an error occurred.
    private func signalProducer<T: Unboxable>() -> SignalProducer<NetworkDataResponse<T>, Network.OperationError> {
        
        return SignalProducer<NetworkDataResponse<T>, Network.OperationError>(){ observer, _disposable in
            guard let response = self.initFromJsonFile(clazz: T.self) else {
                return observer.send(error: .parseFailure)
            }
            
            observer.send(value: response)
            observer.sendCompleted()
        }
    }
    
    
    /**
     Attempts to load a json file from the main bundle and unbox it to the received model type
     - parameter clazz: The class to convert the contents of the json file
     - returns: NetworkDataResponse containing an instance of class 'clazz', or nil if an error occurred
     
     **ASSUMPTION** This method assumes that:
     - there is a .json file containing the json required to instantiate the class
     - the .json file resides in the main bundle
     - the .json file has the same name as the class
     */
    private func initFromJsonFile<T: Unboxable>(clazz: T.Type) -> NetworkDataResponse<T>? {
        guard let path = Bundle.main.url(forResource: String(describing: T.self), withExtension: "json"),
            let contents = try? Data(contentsOf: path),
            let model = try? unbox(data: contents) as T else {
                return nil
        }
        return NetworkDataResponse(responseHeaders: [:], rawData: contents, parsedData: model)
    }
}

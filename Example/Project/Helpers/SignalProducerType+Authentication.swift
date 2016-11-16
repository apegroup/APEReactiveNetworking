//
//  SignalProducerType+Authentication.swift
//  Example
//
//  Created by Magnus Eriksson on 14/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveSwift
import enum Result.NoError
import APEReactiveNetworking

extension SignalProducerProtocol where Error == Network.OperationError {
    
    //MARK: Public
    
    /**
     Injects a side effect that presents the 'LoginViewController' if the SignalProducer receives an 'authentication' error.
     - returns: A new SignalProducer containing the added side effects
     */
    public func handleUnauthorizedResponse() -> SignalProducer<Value, Error> {
        return on(failed: { (error: Network.OperationError) in
            if case let .unexpectedResponseCode(httpCode, data) = error, httpCode == .unauthorized {
                print("Authentication required: '\(String(data: data ?? Data(), encoding: .utf8) ?? "")' - presenting login")
                self.presentLoginViewController()
                    
                //FIXME: If the user is sucessful in authenticating the original signal should be restarted by calling 'self.start()'
                //Unfortunately 'self.start()' will perform an *identical* operation - no dynamism at all. This means that the old jwt token will still be used even though the LoginViewController will have retrieved and persisted a new one after it has successfully authenticated :(
            }
        })
    }
    
    /**
     Called when a SignalProducer that was started with 'startWithAuthentication' fails due to an authentication error.
     Presents the LoginViewController, allowing the user to authenticate.
     If authentication is successful, the original SignalProducer will be restarted, hence allowing it to complete.
     
     - parameter presentingViewController: The view controller to present the LoginViewController
     */
    private func presentLoginViewController() {
        guard let currentVc = UIApplication.shared.keyWindow?.rootViewController?.currentlyPresentedViewController(),
            currentVc is LoginViewController == false else {
                //LoginViewController is already presented
                return
        }
        DispatchQueue.main.async {
            let loginVc = UIStoryboard.loginScene.instantiateInitialViewController()!
            currentVc.present(loginVc, animated: true, completion: nil)
        }
    }
}

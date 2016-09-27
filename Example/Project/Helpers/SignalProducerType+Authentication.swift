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

struct DummyState {
    static var authed = false
}

extension SignalProducerProtocol where Error == Network.OperationError {
    
    //MARK: Public
    
    /**
     Injects a side effect that presents the 'LoginViewController' if the SignalProducer receives an 'authentication' error.
     If the user is sucessful in authenticating the original signal will be restarted
     
     - returns: A new SignalProducer containing the added side effects
     */
    public func requireAuthentication() -> SignalProducer<Value, Error> {
        guard let originalSignalProducer = self as? SignalProducer<Value, Error> else {
            preconditionFailure("'injectAuthorizationSideEffect' must be called on a 'SignalProducer' and not another SignalProducerType'")
        }
        
        //Create a signal that will fail unless we are marked as authenticated.
        //The failure-event contains a specific Http status code (401) which signifies that an Authentication error has occurred.
        let failUnlessAuthenticatedSignal = SignalProducer<Value, Error>() { observer, _disposable in
            guard DummyState.authed else {
                return observer.send(error: .unexpectedResponseCode(httpCode: .unauthorized,
                                                                    data: "401 Unauthorized".data(using: .utf8)))
            }
            observer.sendCompleted()
        }
        
        
        //Concatenate the two SignalProducers into a single SignalProducer.
        //The new producer fails if not authenticated, thus simulating a 'not authenticated' scenario.
        //However, if we are authenticated then the original signal will be performed.
        let mergedSignal: SignalProducer<Value, Error> =
            SignalProducer<SignalProducer<Value, Error>, NoError>() { observer, _ in
                observer.send(value: failUnlessAuthenticatedSignal)
                observer.send(value: originalSignalProducer)
                observer.sendCompleted()
                }
                .flatten(.concat)
                .on(failed: { (error: Network.OperationError) in
                    if case .unexpectedResponseCode(httpCode: .unauthorized, _) = error {
                        print("Received error: \(error) - presenting login")
                        self.presentLoginViewController()
                    }
                })
        
        return mergedSignal
    }
    
    /**
     Called when a SignalProducer that was started with 'startWithAuthentication' fails due to an authentication error.
     Presents the LoginViewController, allowing the user to authenticate.
     If authentication is successful, the original SignalProducer will be restarted, hence allowing it to complete.
     
     - parameter presentingViewController: The view controller to present the LoginViewController
     */
    private func presentLoginViewController(presentingViewController: UIViewController
        = (UIApplication.shared.keyWindow?.rootViewController?.currentlyPresentedViewController())!) {
        
        let navCtrl = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let loginVc = navCtrl.topViewController as! LoginViewController
        
        loginVc.loginCompletionHandler = { [unowned loginVc] _authResponse in
            DispatchQueue.main.async {
                loginVc.dismiss(animated: true, completion: nil)
            }
            
            self.start()
        }
        
        DispatchQueue.main.async {
            presentingViewController.present(navCtrl, animated: true, completion: nil)
        }
    }
}

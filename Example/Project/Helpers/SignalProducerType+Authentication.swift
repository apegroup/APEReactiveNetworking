//
//  SignalProducerType+Authentication.swift
//  Example
//
//  Created by Magnus Eriksson on 14/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveCocoa
import enum Result.NoError
import APEReactiveNetworking

struct DummyState {
    static var authed = false
}

extension SignalProducerType where Error == NetworkError {
    
    //MARK: Public
    
    /**
     Starts a SignalProducer injected with a side effect that presents the 'LoginViewController' if the an 'authentication' error occurs.
     If the user is sucessful in authenticating the original signal will be restarted
     */
    func startWithAuthentication() -> Disposable {
        return injectAuthorizationSideEffect().start()
    }
    
    //MARK: Private
    
    /**
     Injects a side effect that presents the 'LoginViewController' if the SignalProducer receives an 'authentication' error.
     If the user is sucessful in authenticating the original signal will be restarted
     
     - returns: A new SignalProducer containing the added side effects
     */
    private func injectAuthorizationSideEffect() -> SignalProducer<Value, Error> {
        guard let originalSignalProducer = self as? SignalProducer<Value, Error> else {
            preconditionFailure("'injectAuthorizationSideEffect' must be called on a 'SignalProducer' and not another SignalProducerType'")
        }
        
        //Create a signal that will fail unless we are marked as authenticated.
        //The failure-event contains a specific Http status code (401) which signifies that an Authentication error has occurred.
        let failUnlessAuthenticatedSignal = SignalProducer<Value, Error>() { observer, _disposable in
            guard DummyState.authed else {
                return observer.sendFailed(.ErrorResponse(httpCode: .Unauthorized, reason: "'401 Unauthorized'"))
            }
            observer.sendCompleted()
        }
        
        
        //Merge the two SignalProducers into a single SignalProducer.
        //The merged starts both signal producers but fails if not authenticated, thus simulating a 'not authenticated' scenario.
        //However, if we are authenticated then the original signal will be performed.
        let mergedSignal: SignalProducer<Value, Error> =
            SignalProducer<SignalProducer<Value, Error>, NoError>() { observer, _ in
                observer.sendNext(originalSignalProducer)
                observer.sendNext(failUnlessAuthenticatedSignal)
                observer.sendCompleted()
                }
                .flatten(.Merge)
                .on(failed: { (error: NetworkError) in
                    if case .ErrorResponse(httpCode: .Unauthorized, reason: let reason) = error {
                        print("Received error: \(reason) - presenting login")
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
        = (UIApplication.sharedApplication().keyWindow?.rootViewController?.currentlyPresentedViewController())!) {
        
        let navCtrl = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let loginVc = navCtrl.topViewController as! LoginViewController
        
        loginVc.loginCompletionHandler = { _authResponse in
            dispatch_async(dispatch_get_main_queue()) {
                loginVc.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
            }
            
            self.start()
        }
        
        dispatch_async(dispatch_get_main_queue()) {
            presentingViewController.presentViewController(navCtrl, animated: true, completion: nil)
        }
    }
}
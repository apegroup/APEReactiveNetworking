//
//  SignalProducer+Authentication.swift
//  Example
//
//  Created by Magnus Eriksson on 14/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveCocoa
import APEReactiveNetworking

extension SignalProducer {
    

    /**
     Injects a side effect that presents the 'LoginViewController' if the signal producer receives a NetworkError with the HttpStatusCode '403 Forbidden'
     If the user is sucessful in authenticating the original signal will be replayed
     
     - parameter presentingViewController: The view controller to present the 'LoginViewController'
     - parameter loginCompletionHandler:   A block that is called upon authentication success
     
     - returns: 'Self', i.e. the same SignalProducer
     */
    func injectAuthorizationSideEffect(presentingViewController: UIViewController,
                                       loginCompletionHandler: LoginCompletionHandler? = nil) -> SignalProducer<Value, Error> {
        
        func presentLoginViewController(presentingViewController: UIViewController,
                                        _: LoginCompletionHandler? = nil) {
            let navCtrl = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as! UINavigationController
            let loginVc = navCtrl.topViewController as! LoginViewController
            
            loginVc.loginCompletionHandler = { authResponse in
                loginCompletionHandler?(authResponse)
                
                //The original signal producer failed since the user was not logged in.
                //After a successful login, let's replay the original signal producer
                self.replayLazily(0).start()
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                presentingViewController.presentViewController(navCtrl, animated: true, completion: nil)
            }
        }
        
        return on(failed: { error in
            //Check if failure is due to user not being authenticated
            if let error = error as? NetworkError,
                case .ErrorResponse(httpCode: .Forbidden, reason: _) = error {
                print("NOT AUTHENTICATED: Received an error with http status code '403 Forbidden' - presenting login")
                presentLoginViewController(presentingViewController, loginCompletionHandler)
            }
        })
    }
}
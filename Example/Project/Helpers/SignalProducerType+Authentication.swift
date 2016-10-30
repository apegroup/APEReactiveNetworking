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
     If the user is sucessful in authenticating the original signal will be restarted
     
     - returns: A new SignalProducer containing the added side effects
     */
    public func handleUnauthorizedResponse() -> SignalProducer<Value, Error> {
        return on(failed: { (error: Network.OperationError) in
            if case let .unexpectedResponseCode(httpCode, data) = error, httpCode == .unauthorized {
                print("Received \(httpCode) '\(String(data: data ?? Data(), encoding: .utf8) ?? "")' - presenting login")
                self.presentLoginViewController {
                    self.start()
                }
            }
        })
    }
    
    /**
     Called when a SignalProducer that was started with 'startWithAuthentication' fails due to an authentication error.
     Presents the LoginViewController, allowing the user to authenticate.
     If authentication is successful, the original SignalProducer will be restarted, hence allowing it to complete.
     
     - parameter presentingViewController: The view controller to present the LoginViewController
     */
    private func presentLoginViewController(completion: @escaping ()->()) {
        
        let navCtrl = UIStoryboard(name: "Login", bundle: nil).instantiateInitialViewController() as! UINavigationController
        let loginVc = navCtrl.topViewController as! LoginViewController
        
        loginVc.loginCompletionHandler = { [unowned loginVc] _authResponse in
            DispatchQueue.main.async {
                loginVc.dismiss(animated: true, completion: nil)
            }
            
            completion()
        }
        
        DispatchQueue.main.async {
            let presentingViewController = (UIApplication.shared.keyWindow?.rootViewController?.currentlyPresentedViewController())!
            presentingViewController.present(navCtrl, animated: true, completion: nil)
        }
    }
}

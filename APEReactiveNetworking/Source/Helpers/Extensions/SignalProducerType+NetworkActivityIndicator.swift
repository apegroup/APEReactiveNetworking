//
//  SignalProducerType+NetworkActivityIndicator.swift
//  APEReactiveNetworking
//
//  Created by Magnus Eriksson on 22/07/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveSwift

extension SignalProducerProtocol {
    
    /**
     Injects side effects into the SignalProducer's life cycle events.
     Starts the network activity indicator
     
     - returns: The signal producer
     */
    func injectNetworkActivityIndicatorSideEffect() -> SignalProducer<Value, Error> {
        return self.on(started: {
            NetworkActivityIndicator.sharedInstance.enabled = true
            }, terminated: {
                NetworkActivityIndicator.sharedInstance.enabled = false
            }
        )
    }
}

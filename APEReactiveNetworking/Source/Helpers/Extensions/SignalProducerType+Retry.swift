//
//  SignalProducerType+Retry.swift
//  APEReactiveNetworking
//
//  Created by Magnus Eriksson on 22/07/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveSwift

extension SignalProducerProtocol where Error == Network.OperationError {
    
    ///Retries the SignalProducer. Implements an exponential backoff between each retry.
    func retryWithExponentialBackoff() -> SignalProducer<Value, Error> {
        return retry(backoffStrategy: ExponentialSequence())
    }
    
    private func retry<S: Sequence>(backoffStrategy strategy: S) -> SignalProducer<Value, Error> where S.Iterator.Element == TimeInterval {
        var delayIterator = strategy.makeIterator()
        guard let delay = delayIterator.next() else {
            return self.producer.on(failed: { error in
                print("\t\(Date()): Received error: '\(error)'. No next timeout generated - aborting.\n")
            })
        }
        
        return self.flatMapError { error -> SignalProducer<Value, Error> in
            //Only retry when receiving a 'requestFailure' error (meaning that the request could not be sent/a response was not received)
            guard case let .requestFailure(reason) = error else {
                return self.producer
            }
            
            print("\t\(Date()): Received error: '\(reason.localizedDescription)'.\n\tRetrying in: '\(delay)' seconds\n")
            
            /* Catch the 'requestFailure' and map it to a new concatenated SignalProducer which will:
             - Create an inner SignalProducer that will wait 'timout' seconds
             - Replay the original SignalProducer when the previously delayed signal has completed
             */
            return SignalProducer.empty
                .delay(delay, on: QueueScheduler())
                .concat(self.retry(backoffStrategy: IteratorSequence(delayIterator)))
            }
    }
}

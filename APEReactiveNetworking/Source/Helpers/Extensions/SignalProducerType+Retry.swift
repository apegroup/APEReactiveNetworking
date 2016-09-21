//
//  SignalProducerType+Retry.swift
//  APEReactiveNetworking
//
//  Created by Magnus Eriksson on 22/07/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveSwift

extension SignalProducerProtocol {
    
    ///Retries the SignalProducer 'maxAttempts' number of times before failing. Implements an exponential backoff between each retry.
    func retryWithExponentialBackoff(maxAttempts: Int) -> SignalProducer<Value, Error> {
        return retry(backoffStrategy: ExponentialSequence(), attemptsLeft: maxAttempts)
    }
    
    private func retry<S: Sequence>(backoffStrategy strategy: S, attemptsLeft: Int)
        -> SignalProducer<Value, Error> where S.Iterator.Element == TimeInterval {
            
            guard attemptsLeft > 0 else {
                return self.producer.on(failed: { error in
                    print("\t\(Date()): Received error: '\(error)'. No attempts left - aborting.\n")
                })
            }
            
            var delayIterator = strategy.makeIterator()
            guard let delay = delayIterator.next() else {
                return self.producer.on(failed: { error in
                    print("\t\(Date()): Received error: '\(error)'. No next timeout generated - aborting.\n")
                })
            }
            
            // If an error occurs we catch it and map it to a new concatenated SignalProducer which will:
            //  - Create an inner SignalProducer that will wait 'timout' seconds
            //  - Replay the original SignalProducer when the previously delayed signal has completed
            return self.flatMapError { error -> SignalProducer<Value, Error> in
                print("\t\(Date()): Received error: '\(error)'. Retrying in: '\(delay)' seconds\n")
                return SignalProducer.empty
                    .delay(delay, on: QueueScheduler())
                    .concat(self.retry(backoffStrategy: IteratorSequence(delayIterator), attemptsLeft: attemptsLeft-1))
                }.on (started: {
                    print("\t\(Date()): Starting operation. Attempts left: \(attemptsLeft)")
                })
    }
}

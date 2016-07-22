//
//  SignalProducerType+Retry.swift
//  APEReactiveNetworking
//
//  Created by Magnus Eriksson on 22/07/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import ReactiveCocoa

extension SignalProducerType {
    
    ///Retries the SignalProducer 'maxAttempts' number of times before failing. Implements an exponential backoff between each retry.
    func retryWithExponentialBackoff(maxAttempts: Int)
        -> SignalProducer<Value, Error> {
            return retryWithBackoff(ExponentialSequence(), attemptsLeft: maxAttempts)
    }
    
    
    
    private func retryWithBackoff<S: SequenceType where S.Generator.Element == NSTimeInterval>(strategy: S, attemptsLeft: Int)
        -> SignalProducer<Value, Error> {
            
            guard attemptsLeft > 0 else {
                return self.producer.on(failed: { error in
                    print("\t\(NSDate()): Received error: '\(error)'. No attempts left - aborting.\n")
                })
            }
            
            var generator = strategy.generate()
            guard let timeout = generator.next() else {
                return self.producer.on(failed: { error in
                    print("\t\(NSDate()): Received error: '\(error)'. No next timeout generated - aborting.\n")
                })
            }
            
            // If an error occurs we catch it and map it to a new concatenated SignalProducer which will:
            //  - Create an inner SignalProducer that will wait 'timout' seconds
            //  - Replay the original SignalProducer when the previously delayed signal has completed
            return self.flatMapError { error -> SignalProducer<Value, Error> in
                print("\t\(NSDate()): Received error: '\(error)'. Retrying in: '\(timeout)' seconds\n")
                return SignalProducer.empty
                    .delay(timeout, onScheduler: QueueScheduler())
                    .concat(self.retryWithBackoff(GeneratorSequence(generator), attemptsLeft: attemptsLeft-1))
                }.on (started: {
                    print("\t\(NSDate()): Starting operation. Attempts left: \(attemptsLeft)")
                })
    }
}

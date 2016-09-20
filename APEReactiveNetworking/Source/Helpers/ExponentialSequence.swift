//
//  ExponentialSequence.swift
//  APEReactiveNetworking
//
//  Created by Magnus Eriksson on 21/07/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

/**
 *  A SequenceType that creates a generator which increases exponentially
 */
struct ExponentialSequence: Sequence {
    func makeIterator() -> AnyIterator<TimeInterval> {
        var attempt = -1
        return AnyIterator {
            attempt += 1
            return pow(2, TimeInterval(attempt))
        }
    }
}

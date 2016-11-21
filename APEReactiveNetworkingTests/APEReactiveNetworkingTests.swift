//
//  APEReactiveNetworkingTests.swift
//  APEReactiveNetworkingTests
//
//  Created by Dennis Korkchi on 07/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import XCTest
import ReactiveSwift
@testable import APEReactiveNetworking

struct GoogleEndpoint: Endpoint {
    let absoluteUrl = "http://www.google.com"
    let httpMethod: Http.Method = .get
    let acceptedResponseCodes: [Http.StatusCode] = [.ok]
}

struct InvalidResponseCodeEndpoint: Endpoint {
    let absoluteUrl = "http://www.google.com"
    let httpMethod: Http.Method = .get
    let acceptedResponseCodes: [Http.StatusCode] = [.badRequest, .internalServerError]
}


struct InvalidEndpoint: Endpoint {
    let absoluteUrl = "http://www._thisisaninvalidURL_asdfasoiddlkdk.com"
    let httpMethod: Http.Method = .get
    let acceptedResponseCodes: [Http.StatusCode] = [Http.StatusCode.badRequest]
}

class APEReactiveNetworkingTests: XCTestCase {
    
    /**
     Tests the successful case of 200 OK
     */
    func testSuccessfulGET() {
        let maxSecondsPermitted: TimeInterval = 5
        let endpoint = GoogleEndpoint()
        let expect = expectation(description: "Expected status \(endpoint.acceptedResponseCodes) within \(maxSecondsPermitted) seconds")
        
        
        let request = ApeRequestBuilder(endpoint: endpoint).build()
        let producer: SignalProducer<Http.ResponseHeaders, Network.OperationError> = Network().send(request)
            .on(completed: {
                expect.fulfill()
            })
        
        producer.start()
        waitForExpectations(timeout: maxSecondsPermitted, handler: nil)
    }
    
    /**
     Tests the scenario of an invalid response code
     */
    func testInvalidResponseCodeGET() {
        let maxSecondsPermitted: TimeInterval = 5
        let endpoint = InvalidResponseCodeEndpoint()
        let expect = expectation(description: "Expected status \(endpoint.acceptedResponseCodes) within \(maxSecondsPermitted) seconds")
        
        let request = ApeRequestBuilder(endpoint: endpoint).build()
        let producer: SignalProducer<Http.ResponseHeaders, Network.OperationError> = Network().send(request, abortAfter: 10)
        producer.startWithFailed { (operationError: Network.OperationError) in
            guard case let .unexpectedResponseCode(httpCode, _) = operationError,
                !endpoint.acceptedResponseCodes.contains(httpCode) else {
                    return
            }
            expect.fulfill()
        }
    
        waitForExpectations(timeout: maxSecondsPermitted, handler: nil)
    }
    
    /**
     Tests the 'abortAfter' functionality, ensuring that the operation is aborted immediately and that a TimedOut error is sent.
     */
    func testAbortAfter() {
        let expect = expectation(description: "Expected timeout")
        
        let request = ApeRequestBuilder(endpoint: GoogleEndpoint()).build()
        let producer: SignalProducer<Http.ResponseHeaders, Network.OperationError> = Network().send(request, abortAfter: 0.0)
            .on(failed: { (error: Network.OperationError) in
                XCTAssertEqual(error._code, Network.OperationError.timedOut._code)
                expect.fulfill()
            })
        
        producer.start()
        waitForExpectations(timeout: 1, handler: nil)
    }
}

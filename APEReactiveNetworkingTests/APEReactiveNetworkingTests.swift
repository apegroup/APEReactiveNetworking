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
        let producer: SignalProducer<Http.ResponseHeaders, Network.OperationError> = Network().send(request, maxRetries: 0)
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
    
    /**
     Tests the 'exponential backoff retry' functionality.
     
     This is tested by connecting to an invalid URL and ensuring that:
       - a request failure occurs
       - a minimum required amount of time (based on the number of retries and the exponential backoff time units added between each retry) has elapsed before the failure occurs.
     */
    func testExponentialBackoff() {
        let expect = expectation(description: "Minimum required time has not elapsed")
        
        //Number of times to retry the request operation
        let numberOfRetries = 4
        
        //Calculate the minimum amount of seconds that the network request will take (due to exponential backoff)
        var minimumRequiredTime: TimeInterval = 0
        let exponentialGenerator = ExponentialSequence().makeIterator()
        (0..<numberOfRetries).forEach { _ in
            minimumRequiredTime += exponentialGenerator.next()!
        }
        
        //Set a maximum time permitted before failing the test (give each request 2 seconds to complete)
        let secondsPerRequest = 2
        let marginSeconds = TimeInterval(numberOfRetries * secondsPerRequest)
        let maximumTimePermitted = minimumRequiredTime + marginSeconds
        
        var startTime: TimeInterval?
        var endTime: TimeInterval?
        let request = ApeRequestBuilder(endpoint: InvalidEndpoint()).build()
        let producer: SignalProducer<Http.ResponseHeaders, Network.OperationError> = Network().send(request, abortAfter: maximumTimePermitted, maxRetries: numberOfRetries)
            .on(started: {
                    //Capture the start time
                    startTime = Date().timeIntervalSince1970
                    
                }, failed: { (error: Network.OperationError) in
                    //Capture the end time
                    endTime = Date().timeIntervalSince1970
                    
                    //Calculate the total time elapsed
                    let timeElapsed = endTime! - startTime!
                    
                    //Assert that the total time elapsed is larger than the minimum required time
                    XCTAssert(timeElapsed > minimumRequiredTime)
                    
                    //Assert that a request failure has occurred
                    let expectedError = NSError(domain: "URLErrorDomain", code: -1003, userInfo: nil)
                    XCTAssertEqual(error._code, Network.OperationError.requestFailure(error: expectedError)._code)
                    
                    expect.fulfill()
            })
        
        producer.start()
        
        waitForExpectations(timeout: maximumTimePermitted, handler: nil)
    }
}

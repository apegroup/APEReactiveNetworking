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

class APEReactiveNetworkingTests: XCTestCase {
    
    /**
     Tests the successful case of 200 OK
     */
    func testSuccessfulGET() {
        let maxSecondsPermitted: TimeInterval = 5
        let expect = expectation(description: "Expected status 200 OK within 5 seconds")
        
        let request = URLRequest(url: URL(string: "http://www.google.com")!)
        let producer: SignalProducer<HttpResponseHeaders, NetworkError> = Network().send(request: request)
            .on(completed: {
                expect.fulfill()
            })
        
        producer.start()
        waitForExpectations(timeout: maxSecondsPermitted, handler: nil)
    }
    
    /**
     Tests the 'abortAfter' functionality, ensuring that the operation is aborted immediately and that a TimedOut error is sent.
     */
    func testAbortAfter() {
        let expect = expectation(description: "Expected timeout")
        
        let request = URLRequest(url: URL(string: "http://www.google.com")!)
        let producer: SignalProducer<HttpResponseHeaders, NetworkError> = Network().send(request: request, abortAfter: 0.0)
            .on(failed: { (error: NetworkError) in
                XCTAssertEqual(error._code, NetworkError.TimedOut._code)
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
        let request = URLRequest(url: URL(string: "http://www._thisisaninvalidURL_asdfasoiddlkdk.com")!)
        let producer: SignalProducer<HttpResponseHeaders, NetworkError> = Network().send(request: request, abortAfter:maximumTimePermitted, maxRetries:numberOfRetries)
            .on(
                started: {
                    //Capture the start time
                    startTime = Date().timeIntervalSince1970
                    
                }, failed: { (error: NetworkError) in
                    //Capture the end time
                    endTime = Date().timeIntervalSince1970
                    
                    //Calculate the total time elapsed
                    let timeElapsed = endTime! - startTime!
                    
                    //Assert that the total time elapsed is larger than the minimum required time
                    XCTAssert(timeElapsed > minimumRequiredTime)
                    
                    //Assert that a request failure has occurred
                    let expectedError = NSError(domain: "URLErrorDomain", code: -1003, userInfo: nil)
                    XCTAssertEqual(error._code, NetworkError.RequestFailure(reason: expectedError)._code)
                    
                    expect.fulfill()
            })
        
        producer.start()
        
        waitForExpectations(timeout: maximumTimePermitted, handler: nil)
    }
}

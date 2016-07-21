//
//  APEReactiveNetworkingTests.swift
//  APEReactiveNetworkingTests
//
//  Created by Dennis Korkchi on 07/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import XCTest
import ReactiveCocoa
@testable import APEReactiveNetworking

class APEReactiveNetworkingTests: XCTestCase {
    
    /**
     Tests the successful case of 200 OK
     */
    func testSuccessfulGET() {
        let maxSecondsPermitted: NSTimeInterval = 5
        let expectation = expectationWithDescription("Expected status 200 OK within 5 seconds")
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.google.com")!)
        let producer: SignalProducer<(), NetworkError> = Network().send(request)
            .on(completed: {
                expectation.fulfill()
            })
        
        producer.start()
        waitForExpectationsWithTimeout(maxSecondsPermitted, handler: nil)
    }
    
    /**
     Tests the 'abortAfter' functionality, ensuring that the operation is aborted immediately and that a TimedOut error is sent.
     */
    func testAbortAfter() {
        let expectation = expectationWithDescription("Expected timeout")
        
        let request = NSURLRequest(URL: NSURL(string: "http://www.google.com")!)
        let producer: SignalProducer<(), NetworkError> = Network().send(request, abortAfter: 0.0)
            .on(failed: { (error: NetworkError) in
                XCTAssertEqual(error._code, NetworkError.TimedOut._code)
                expectation.fulfill()
            })
        
        producer.start()
        waitForExpectationsWithTimeout(1, handler: nil)
    }
    
    /**
     Tests the 'exponential backoff retry' functionality.
     
     This is tested by connecting to an invalid URL and ensuring that:
       - a request failure occurs
       - a minimum required amount of time (based on the number of retries and the exponential backoff time units added between each retry) has elapsed before the failure occurs.
     */
    func testExponentialBackoff() {
        let expectation = expectationWithDescription("Minimum required time has not elapsed")
        
        //Number of times to retry the request operation
        let numberOfRetries = 4
        
        //Calculate the minimum amount of seconds that the network request will take (due to exponential backoff)
        var minimumRequiredTime: NSTimeInterval = 0
        let exponentialGenerator = ExponentialSequence().generate()
        (0..<numberOfRetries).forEach { _ in
            minimumRequiredTime += exponentialGenerator.next()!
        }
        
        //Set a maximum time permitted before failing the test (give each request 2 seconds to complete)
        let secondsPerRequest = 2
        let marginSeconds = NSTimeInterval(numberOfRetries * secondsPerRequest)
        let maximumTimePermitted = minimumRequiredTime + marginSeconds
        
        var startTime: NSTimeInterval?
        var endTime: NSTimeInterval?
        let request = NSURLRequest(URL: NSURL(string: "http://www._thisisaninvalidURL_asdfasoiddlkdk.com")!)
        let producer: SignalProducer<(), NetworkError> = Network().send(request, abortAfter:maximumTimePermitted, maxRetries:numberOfRetries)
            .on(
                started: {
                    //Capture the start time
                    startTime = NSDate().timeIntervalSince1970
                    
                }, failed: { (error: NetworkError) in
                    //Capture the end time
                    endTime = NSDate().timeIntervalSince1970
                    
                    //Calculate the total time elapsed
                    let timeElapsed = endTime! - startTime!
                    
                    //Assert that the total time elapsed is larger than the minimum required time
                    XCTAssert(timeElapsed > minimumRequiredTime)
                    
                    //Assert that a request failure has occurred
                    let expectedError = NSError(domain: "NSURLErrorDomain", code: -1003, userInfo: nil)
                    XCTAssertEqual(error._code, NetworkError.RequestFailure(reason: expectedError)._code)
                    
                    expectation.fulfill()
            })
        
        producer.start()
        
        waitForExpectationsWithTimeout(maximumTimePermitted, handler: nil)
    }
}

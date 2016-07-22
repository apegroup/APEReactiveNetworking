//
//  Network.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-04-29.
//  Copyright © 2016 Apegroup. All rights reserved.
//


import Foundation
import ReactiveCocoa
import enum Result.NoError


public enum NetworkError : ErrorType {
    case ParseFailure
    case MissingData
    case MissingResponse
    case ErrorResponse (httpCode: HttpStatusCode, reason: String)
    case RequestFailure (reason: NSError)
    case TimedOut
}

// TODO: Consider customisable data, download, upload tasks

public struct Network {
    
    /// The TOTAL number of seconds to wait before aborting the entire operation.
    static let operationTimeoutSeconds: NSTimeInterval = 10
    
    /// The max number of retries before aborting the entire operation
    static let maxRetryCount = 10
    
    
    //MARK: Public
    
    public init() {}
    
    /**
     Sends a request over the network.
     
     - parameter request:               The request to be sent
     
     - parameter responseCodeValidator: An http status code validator that asserts that the received response code matches the expected response code.
     Defaults to 'ApeResponseCodeValidator'
     
     - parameter session:               The NSURLSession to be used. Defaults to the shared session
     
     - parameter scheduler:             The scheduler to which the returned SignalProducer will forward events to. Defaults to the UIScheduler.
     
     - parameter abortAfter:            Number of seconds to wait until the operation is aborted and a 'TimedOut' failure is sent. Defaults to 'operationTimeoutSeconds'
     
     - parameter maxRetries:            Max number of retries before failing the operation. Implements an exponential backoff between each retry. Defaults to 'retryCount'
     
     - parameter parseDataBlock:        If response data is expected you should provide this parameter as a means to parse the data to the expected data type.
     
     - returns: A SignalProducer that will begin the network request when started
     */
    public func send<T>(request: NSURLRequest,
                     responseCodeValidator: HttpResponseCodeValidator = ApeResponseCodeValidator(),
                     session: NSURLSession = NSURLSession.sharedSession(),
                     scheduler: SchedulerType = UIScheduler(),
                     abortAfter: NSTimeInterval = operationTimeoutSeconds,
                     maxRetries: Int = maxRetryCount,
                     parseDataBlock: ((data:NSData) -> T?)? = nil) -> SignalProducer<T, NetworkError> {
        
        let operationProducer = session.dataTaskSignalProducer(request: request,
            responseCodeValidator: responseCodeValidator,
            parseDataBlock: parseDataBlock)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retryWithExponentialBackoff(maxRetries)
        
        
        /* In order to implement 'entire-operation-timeout' (rather than 'timeout-per-retry') we merge the
         * Operation-SignalProducer with an empty SignalProducer and apply the timeout to the merged/outer SignalProducer.
         *
         * The Merged-SignalProducer will fail if:
         *      - the inner Operation-SignalProducers fails,
         *      or if
         *      - the inner Operation-SignalProducer doesn't complete withhin 'abortAfter' seconds
         *
         * Whichever occurs first.
         */
        return SignalProducer<SignalProducer<T, NetworkError>, NoError> (values: [SignalProducer.empty, operationProducer])
            .flatten(.Merge)
            .timeoutWithError(.TimedOut, afterInterval: abortAfter, onScheduler: QueueScheduler())
            .observeOn(scheduler)
            .on (
                started: {
                    print("# NetworkOperation started")
                }, failed: { error in
                    print("# NetworkOperation failed: \(error)")
                }, completed: {
                    print("# NetworkOperation completed")
                }, interrupted: {
                    print("# NetworkOperation interrupted")
                }, terminated: {
                    print("# NetworkOperation terminated")
            })
    }
}

//MARK: NSURLSession + ReactiveCocoa

private extension NSURLSession {
    
    func dataTaskSignalProducer<T>(request request: NSURLRequest,
                                responseCodeValidator: HttpResponseCodeValidator,
                                parseDataBlock: ((data:NSData) -> T?)? = nil)
        -> SignalProducer<T, NetworkError> {
            
            return SignalProducer<T, NetworkError>(){ observer, disposable in
                
                let task = self.dataTaskWithRequest(request) { data, response, error in
                    
                    guard error == nil else {
                        return observer.sendFailed(.RequestFailure(reason: error!))
                    }
                    
                    guard let httpResponse = response as? NSHTTPURLResponse else {
                        return observer.sendFailed(.MissingResponse)
                    }
                    
                    //Ensure expected response code is returned
                    guard let method = HttpMethod(value: request.HTTPMethod),
                        statusCode = HttpStatusCode(rawValue: httpResponse.statusCode)
                        where responseCodeValidator.isResponseCodeValid(statusCode, httpMethod: method) else {
                            
                            let httpCode = HttpStatusCode(value: httpResponse.statusCode)
                            let reason = NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode)
                            return observer.sendFailed(.ErrorResponse(httpCode: httpCode, reason: reason))
                    }
                    
                    //If we're expecting data to be returned - let's parse it
                    if let parseDataBlock = parseDataBlock {
                        guard let data = data else {
                            return observer.sendFailed(.MissingData)
                        }
                        
                        guard let parsedData = parseDataBlock(data:data) else {
                            return observer.sendFailed(.ParseFailure)
                        }
                        
                        observer.sendNext(parsedData)
                        observer.sendCompleted()
                    }  else {
                        observer.sendCompleted()
                    }
                }
                
                disposable.addDisposable {
                    task.cancel()
                }
                
                task.resume()
            }
    }
}

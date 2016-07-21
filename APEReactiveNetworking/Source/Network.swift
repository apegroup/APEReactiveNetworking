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
    static let operationTimeoutSeconds : NSTimeInterval = 20
    
    /// The max number of retries before aborting the entire operation
    static let retryCount = 10
    
    
    //MARK: Public
    
    public init() {}
    
    /**
     Sends a request over the network. 
     
     Aborts and fails the operation after 'abortAfter' seconds.
     
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
                     maxRetries: Int = retryCount,
                     parseDataBlock: ((data:NSData) -> T?)? = nil) -> SignalProducer<T, NetworkError> {
        
        
        /// Create a SignalProducer that will fail after 'abortAfter' seconds
        var timeoutObserver: Observer<T, NetworkError>?
        let timeoutProducer = SignalProducer<T, NetworkError> { observer, _disposable in
            timeoutObserver = observer
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(abortAfter * Double(NSEC_PER_SEC))),
            dispatch_get_main_queue()) {
                timeoutObserver?.sendFailed(NetworkError.TimedOut)
            }
        }
        
        /// Create a SignalProducer that will perform the actual operation
        let operationProducer = session.dataTaskSignalProducer(request: request,
            responseCodeValidator: responseCodeValidator,
            parseDataBlock: parseDataBlock)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retryWithExponentialBackoff(maxRetries)
            .on(completed: {
                //Complete and invalidate the Timeout-SignalProducer when the operation is completed, in order to complete the merged SignalProducer below
                timeoutObserver?.sendCompleted()
                timeoutObserver = nil
            })
        
        
        /* Merge the Timeout-SignalProducer and the Operation-SignalProducer.
         * The Merged-SignalProducer will:
         *      - fail if one of the inner SignalProducers fail,
         *      or
         *      - complete if both inner SignalProducers complete
         *
         * Whichever occurs first.
         */
        return SignalProducer<SignalProducer<T, NetworkError>, NoError> (values: [timeoutProducer, operationProducer])
            .flatten(.Merge)
            .observeOn(scheduler)
            .on (
                started: {
                    print("# NetworkOperationSignal started")
                }, failed: { error in
                    print("# NetworkOperationSignal failed: \(error)")
                }, completed: {
                    print("# NetworkOperationSignal completed")
                }, interrupted: {
                    print("# NetworkOperationSignal interrupted")
                }, terminated: {
                    print("# NetworkOperationSignal terminated")
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

//MARK: SignalProducer + SideEffects

private extension SignalProducer {
    
    /**
     Injects side effects into the SignalProducer's life cycle events.
     Starts the network activity indicator
     
     - returns: The signal producer
     */
    func injectNetworkActivityIndicatorSideEffect() -> SignalProducer<Value, Error> {
        return self.on (
            started: {
                NetworkActivityIndicator.sharedInstance.enabled = true
            }, terminated: {
                NetworkActivityIndicator.sharedInstance.enabled = false
            }
        )
    }
}

//MARK: SignalProducerType + Retry Exponential Backoff

private extension SignalProducerType {
    
     ///Retries the SignalProducer 'maxAttempts' number of times before failing. Implements an exponential backoff between each retry.
    func retryWithExponentialBackoff(maxAttempts: Int)
        -> SignalProducer<Value, Error> {
            return retryWithBackoff(ExponentialSequence(), attemptsLeft: maxAttempts)
    }
    
    
    private func retryWithBackoff<S: SequenceType where S.Generator.Element == NSTimeInterval>(strategy: S, attemptsLeft: Int)
        -> SignalProducer<Value, Error> {
            
            guard attemptsLeft > 0 else {
                print("No attempts left. Aborting.")
                return self.producer
            }
            
            var generator = strategy.generate()
            guard let timeout = generator.next() else {
                print("Failed to generate next timeout. Aborting.")
                return self.producer
            }
            
            // If an error occurs we catch it and map it to a new concatenated SignalProducer which will:
            //  - Create an inner SignalProducer that will wait 'timout' seconds
            //  - Replay the original SignalProducer when the previously delayed signal has completed
            return self.flatMapError { _ -> SignalProducer<Value, Error> in
                print("\(NSDate()): Received an error. Timing out for: \(timeout) seconds")
                return SignalProducer.empty
                    .delay(timeout, onScheduler: QueueScheduler())
                    .concat(self.retryWithBackoff(GeneratorSequence(generator), attemptsLeft: attemptsLeft-1))
                }.on (started: {
                    print("\(NSDate()): Starting operation. Attempts left: \(attemptsLeft)")
                })
    }
}
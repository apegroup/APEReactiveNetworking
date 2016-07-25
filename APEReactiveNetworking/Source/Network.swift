//
//  Network.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-04-29.
//  Copyright © 2016 Apegroup. All rights reserved.
//


import Foundation
import ReactiveCocoa


// TODO: Move into Network when possible
public struct NetworkDataResponse<T> {
    public let responseHeaders: HttpResponseHeaders
    public let parsedData: T

    public init(responseHeaders: HttpResponseHeaders, data: T) {
        self.responseHeaders = responseHeaders
        self.parsedData = data
    }
}


// TODO: Consider customisable data, download, upload tasks
public struct Network {

    public enum Error : ErrorType {
        case ParseFailure
        case MissingData
        case MissingResponse
        case ErrorResponse (httpCode: HttpStatusCode, reason: String)
        case RequestFailure (reason: NSError)
        case TimedOut
    }


    /// The TOTAL number of seconds to wait before aborting the entire operation.
    static let operationTimeoutSeconds: NSTimeInterval = 10
    
    /// The max number of retries before aborting the entire operation
    static let maxRetryCount = 10
    
    
    //MARK: Public
    
    public init() {}
    
    
    /**
     Sends a request over the network.
     
     - parameter request:               The request to be sent
     
     - parameter responseCodeValidator: An http status code validator that asserts that the received response code matches the expected response code. Defaults to 'ApeResponseCodeValidator'
     
     - parameter session:               The NSURLSession to be used. Defaults to the shared session
     
     - parameter scheduler:             The scheduler to which the returned SignalProducer will forward events to. Defaults to the UIScheduler.
     
     - parameter abortAfter:            Number of seconds to wait until the operation is aborted and a 'TimedOut' failure is sent. Defaults to 'operationTimeoutSeconds'
     
     - parameter maxRetries:            Max number of retries before failing the operation. Implements an exponential backoff between each retry. Defaults to 'retryCount'
     
     - returns: A SignalProducer that will begin the network request when started. The 'next' event contains the HttpResponseHeaders.
     */
    public func send(request: NSURLRequest,
                     responseCodeValidator: HttpResponseCodeValidator = ApeResponseCodeValidator(),
                     session: NSURLSession = NSURLSession.sharedSession(),
                     scheduler: SchedulerType = UIScheduler(),
                     abortAfter: NSTimeInterval = operationTimeoutSeconds,
                     maxRetries: Int = maxRetryCount) -> SignalProducer<HttpResponseHeaders, Network.Error> {
        
        return session
            .dataTaskHttpHeaderSignalProducer(request: request,responseCodeValidator: responseCodeValidator)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retryWithExponentialBackoff(maxRetries)
            .timeoutWithError(.TimedOut, afterInterval: abortAfter, onScheduler: QueueScheduler())
            .addLogging(abortAfter)
            .observeOn(scheduler)
    }
    
    /**
     Sends a request over the network.
     
     - parameter request:               The request to be sent
     
     - parameter responseCodeValidator: An http status code validator that asserts that the received response code matches the expected response code.
     Defaults to 'ApeResponseCodeValidator'
     
     - parameter session:               The NSURLSession to be used. Defaults to the shared session
     
     - parameter scheduler:             The scheduler to which the returned SignalProducer will forward events to. Defaults to the UIScheduler.
     
     - parameter abortAfter:            Number of seconds to wait until the operation is aborted and a 'TimedOut' failure is sent. Defaults to 'operationTimeoutSeconds'
     
     - parameter maxRetries:            Max number of retries before failing the operation. Implements an exponential backoff between each retry. Defaults to 'retryCount'
     
     - parameter parseDataBlock:        A block that accepts the response raw data as a means to parse the it to the expected data type.
     
     - returns: A SignalProducer that will begin the network request when started. The 'next' event contains the a NetworkResponse object, containing the HttpResponseHeaders and the parsed data.
     */
    public func send<T>(request: NSURLRequest,
                     responseCodeValidator: HttpResponseCodeValidator = ApeResponseCodeValidator(),
                     session: NSURLSession = NSURLSession.sharedSession(),
                     scheduler: SchedulerType = UIScheduler(),
                     abortAfter: NSTimeInterval = operationTimeoutSeconds,
                     maxRetries: Int = maxRetryCount,
                     parseDataBlock: ((data:NSData) -> T?)) -> SignalProducer<NetworkDataResponse<T>, Network.Error> {
        
        return session
            .dataTaskSignalProducer(request: request,responseCodeValidator: responseCodeValidator, parseDataBlock: parseDataBlock)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retryWithExponentialBackoff(maxRetries)
            .timeoutWithError(.TimedOut, afterInterval: abortAfter, onScheduler: QueueScheduler())
            .addLogging(abortAfter)
            .observeOn(scheduler)
    }
}

private extension SignalProducerType {
    
    private func addLogging(abortAfter: NSTimeInterval) -> SignalProducer<Value, Error> {
        return self
            .on (
                started: {
                    print("# \(NSDate()): NetworkOperation started. Must complete within '\(abortAfter)' seconds")
                }, failed: { error in
                    print("# \(NSDate()): NetworkOperation failed: \(error)")
                }, completed: {
                    print("# \(NSDate()): NetworkOperation completed")
                }, interrupted: {
                    print("# \(NSDate()): NetworkOperation interrupted")
                }, terminated: {
                    print("# \(NSDate()): NetworkOperation terminated")
            })
    }
}

//MARK: NSURLSession + ReactiveCocoa

private extension NSURLSession {
    
    /**
     Returns a SignalProducer that returns the Http response headers, or an appropriate NetworkError if an error occurs
     */
    func dataTaskHttpHeaderSignalProducer(request request: NSURLRequest,
                                                  responseCodeValidator: HttpResponseCodeValidator)
        -> SignalProducer<HttpResponseHeaders, Network.Error> {
            
            return SignalProducer<HttpResponseHeaders, Network.Error> { observer, disposable in
                
                let task = self.dataTaskWithRequest(request) { data, response, error in
                    
                    let (maybeHttpResponse, networkError) = self.validate(request, withResponseCodeValidator: responseCodeValidator, error: error, response: response)
                    guard let httpResponse = maybeHttpResponse else {
                        return observer.sendFailed(networkError!)
                    }
                    
                    observer.sendNext(httpResponse.allHeaderFields)
                    observer.sendCompleted()
                }
                
                disposable.addDisposable {
                    task.cancel()
                }
                
                task.resume()
            }
    }
    
    /**
     Returns a SignalProducer that returns a NetworkResponse, containing the Http response headers and the parsed response data, or an appropriate NetworkError if an error occurs
     */
    func dataTaskSignalProducer<T>(request request: NSURLRequest,
                                responseCodeValidator: HttpResponseCodeValidator,
                                parseDataBlock: ((data:NSData) -> T?))
        -> SignalProducer<NetworkDataResponse<T>, Network.Error> {
            
            return SignalProducer<NetworkDataResponse<T>, Network.Error> { observer, disposable in
                
                let task = self.dataTaskWithRequest(request) { data, response, error in

                    let (maybeHttpResponse, networkError) = self.validate(request, withResponseCodeValidator: responseCodeValidator, error: error, response: response)
                    guard let httpResponse = maybeHttpResponse else {
                        return observer.sendFailed(networkError!)
                    }
                    
                    //Ensure that response data exists
                    guard let data = data else {
                        return observer.sendFailed(.MissingData)
                    }
                    
                    //Ensure that we are able to parse the response data
                    guard let parsedData = parseDataBlock(data:data) else {
                        return observer.sendFailed(.ParseFailure)
                    }
                    
                    observer.sendNext(NetworkDataResponse(responseHeaders: httpResponse.allHeaderFields, data: parsedData))
                    observer.sendCompleted()
                }
                
                disposable.addDisposable {
                    task.cancel()
                }
                
                task.resume()
            }
    }
    
    
    /**
     Validates that response, making sure that:
        - No error has occurred
        - The response is a HttpURLResponse
        - The expected http status code is received
     
     - returns: The HttpURLResponse, or an associated NetworkError if an error has occurred
     */
    private func validate(request: NSURLRequest,
                          withResponseCodeValidator responseCodeValidator: HttpResponseCodeValidator,
                                                    error: NSError?,
                                                    response: NSURLResponse?) -> (httpResponse: NSHTTPURLResponse?, networkError: Network.Error?) {
        //Ensure no error occurred
        guard error == nil else {
            return (httpResponse: nil, networkError: .RequestFailure(reason: error!))
        }
        
        //Ensure httpResponse was returned
        guard let httpResponse = response as? NSHTTPURLResponse else {
            return (httpResponse: nil, networkError: .MissingResponse)
        }
        
        //Ensure expected response code is returned
        guard let method = HttpMethod(value: request.HTTPMethod),
            statusCode = HttpStatusCode(rawValue: httpResponse.statusCode)
            where responseCodeValidator.isResponseCodeValid(statusCode, httpMethod: method) else {
                let httpCode = HttpStatusCode(value: httpResponse.statusCode)
                let reason = NSHTTPURLResponse.localizedStringForStatusCode(httpResponse.statusCode)
                return (httpResponse: nil, networkError: .ErrorResponse(httpCode: httpCode, reason: reason))
        }
        
        return (httpResponse: httpResponse, networkError: nil)
    }
}

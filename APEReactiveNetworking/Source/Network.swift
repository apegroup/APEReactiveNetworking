//
//  Network.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-04-29.
//  Copyright © 2016 Apegroup. All rights reserved.
//


import Foundation
import ReactiveSwift


//TODO: Move into Network when possible
public struct NetworkDataResponse<T> {
    public let responseHeaders: Http.ResponseHeaders
    public let parsedData: T
    
    public init(responseHeaders: Http.ResponseHeaders, data: T) {
        self.responseHeaders = responseHeaders
        self.parsedData = data
    }
}

// TODO: Consider customisable data, download, upload tasks
public struct Network {
    
    public enum OperationError : Error {
        case parseFailure
        case missingData
        case missingResponse
        case errorResponse(httpCode: Http.StatusCode, reason: String)
        case requestFailure(reason: Error)
        case timedOut
    }
    
    public init() {}
    
    /// The total number of seconds to wait before aborting the entire operation
    static let operationTimeoutSeconds: TimeInterval = 10
    
    /// The max number of retries before aborting the entire operation
    static let maxRetryCount = 10
    
    //MARK: Public
    
    /**
     Sends a request over the network.
     
     - parameter request:               The request to be sent
     
     - parameter responseCodeValidator: An http status code validator that asserts that the received response code matches the expected response code. Defaults to 'ApeResponseCodeValidator'
     
     - parameter session:               The URLSession to be used. Defaults to the shared session
     
     - parameter scheduler:             The scheduler to which the returned SignalProducer will forward events to. Defaults to the UIScheduler.
     
     - parameter abortAfter:            Number of seconds to wait until the operation is aborted and a 'TimedOut' failure is sent. Defaults to 'operationTimeoutSeconds'
     
     - parameter maxRetries:            Max number of retries before failing the operation. Implements an exponential backoff between each retry. Defaults to 'retryCount'
     
     - returns: A SignalProducer that will begin the network request when started. The 'next' event contains the Http.ResponseHeaders.
     */
    public func send(_ request: URLRequest,
                     responseCodeValidator: HttpResponseCodeValidator = ApeResponseCodeValidator(),
                     session: URLSession = URLSession.shared,
                     scheduler: SchedulerProtocol = UIScheduler(),
                     abortAfter: TimeInterval = operationTimeoutSeconds,
                     maxRetries: Int = maxRetryCount) -> SignalProducer<Http.ResponseHeaders, Network.OperationError> {
        
        return session
            .dataTaskHttpHeaderSignalProducer(request: request,responseCodeValidator: responseCodeValidator)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retryWithExponentialBackoff(maxAttempts: maxRetries)
            .timeout(after: abortAfter, raising: .timedOut, on: QueueScheduler())
            .addLogging(request: request, abortAfter: abortAfter)
            .observe(on: scheduler)
    }
    
    /**
     Sends a request over the network.
     
     - parameter request:               The request to be sent
     
     - parameter responseCodeValidator: An http status code validator that asserts that the received response code matches the expected response code.
     Defaults to 'ApeResponseCodeValidator'
     
     - parameter session:               The URLSession to be used. Defaults to the shared session
     
     - parameter scheduler:             The scheduler to which the returned SignalProducer will forward events to. Defaults to the UIScheduler.
     
     - parameter abortAfter:            Number of seconds to wait until the operation is aborted and a 'TimedOut' failure is sent. Defaults to 'operationTimeoutSeconds'
     
     - parameter maxRetries:            Max number of retries before failing the operation. Implements an exponential backoff between each retry. Defaults to 'retryCount'
     
     - parameter parseDataBlock:        A block that accepts the response raw data as a means to parse the it to the expected data type.
     
     - returns: A SignalProducer that will begin the network request when started. The 'next' event contains the a NetworkResponse object, containing the Http.ResponseHeaders and the parsed data.
     */
    public func send<T>(_ request: URLRequest,
                     responseCodeValidator: HttpResponseCodeValidator = ApeResponseCodeValidator(),
                     session: URLSession = URLSession.shared,
                     scheduler: SchedulerProtocol = UIScheduler(),
                     abortAfter: TimeInterval = operationTimeoutSeconds,
                     maxRetries: Int = maxRetryCount,
                     parseDataBlock: @escaping ((Data) -> T?)) -> SignalProducer<NetworkDataResponse<T>, Network.OperationError> {
        
        return session
            .dataTaskSignalProducer(request: request,responseCodeValidator: responseCodeValidator, parseDataBlock: parseDataBlock)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retryWithExponentialBackoff(maxAttempts: maxRetries)
            .timeout(after: abortAfter, raising: .timedOut, on: QueueScheduler())
            .addLogging(request: request, abortAfter: abortAfter)
            .observe(on: scheduler)
    }
}

fileprivate extension SignalProducerProtocol {
    
    fileprivate func addLogging(request: URLRequest, abortAfter: TimeInterval) -> SignalProducer<Value, Error> {
        return self.on (
                started: {
                    print("# \(Date()): NetworkOperation started. URL: '\(request.url?.absoluteString ?? "---")'. Must complete within '\(abortAfter)' seconds")
                }, failed: { error in
                    print("# \(Date()): NetworkOperation failed: \(error)")
                }, completed: {
                    print("# \(Date()): NetworkOperation completed")
                }, interrupted: {
                    print("# \(Date()): NetworkOperation interrupted")
                }, terminated: {
                    print("# \(Date()): NetworkOperation terminated")
            })
    }
}

//MARK: URLSession + ReactiveSwift

private extension URLSession {
    
    /**
     Returns a SignalProducer that returns the Http response headers, or an appropriate Network.OperationError if an error occurs
     */
    func dataTaskHttpHeaderSignalProducer(request: URLRequest, responseCodeValidator: HttpResponseCodeValidator)
        -> SignalProducer<Http.ResponseHeaders, Network.OperationError> {
            
            return SignalProducer<Http.ResponseHeaders, Network.OperationError> { observer, disposable in
                
                let task = self.dataTask(with: request) { data, response, error in
                    
                    let (maybeHttpResponse, networkError) = self.validate(request, withResponseCodeValidator: responseCodeValidator, error: error, response: response)
                    guard let httpResponse = maybeHttpResponse else {
                        return observer.send(error: networkError!)
                    }
                    
                    observer.send(value: httpResponse.allHeaderFields)
                    observer.sendCompleted()
                }
                
                _ = disposable.add {
                    task.cancel()
                }
                
                task.resume()
            }
    }
    
    /**
     Returns a SignalProducer that returns a NetworkResponse, containing the Http response headers and the parsed response data, or an appropriate Network.OperationError if an error occurs
     */
    func dataTaskSignalProducer<T>(request: URLRequest,
                                responseCodeValidator: HttpResponseCodeValidator,
                                parseDataBlock: @escaping ((Data) -> T?))
        -> SignalProducer<NetworkDataResponse<T>, Network.OperationError> {
            
            return SignalProducer<NetworkDataResponse<T>, Network.OperationError> { observer, disposable in
                
                let task = self.dataTask(with: request) { data, response, error in
                    
                    let (maybeHttpResponse, networkError) = self.validate(request, withResponseCodeValidator: responseCodeValidator, error: error, response: response)
                    guard let httpResponse = maybeHttpResponse else {
                        return observer.send(error: networkError!)
                    }
                    
                    //Ensure that response data exists
                    guard let data = data else {
                        return observer.send(error: .missingData)
                    }
                    
                    //Ensure that we are able to parse the response data
                    guard let parsedData = parseDataBlock(data) else {
                        return observer.send(error: .parseFailure)
                    }
                    
                    observer.send(value: NetworkDataResponse(responseHeaders: httpResponse.allHeaderFields, data: parsedData))
                    observer.sendCompleted()
                }
                
                _ = disposable.add {
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
     
     - returns: The HttpURLResponse, or an associated Network.OperationError if an error has occurred
     */
    private func validate(_ request: URLRequest,
                          withResponseCodeValidator responseCodeValidator: HttpResponseCodeValidator,
                          error: Error?,
                          response: URLResponse?) -> (httpResponse: HTTPURLResponse?, networkError: Network.OperationError?) {
        
        //Ensure no error occurred
        guard error == nil else {
            return (httpResponse: nil, networkError: .requestFailure(reason: error!))
        }
        
        //Ensure httpResponse was returned
        guard let httpResponse = response as? HTTPURLResponse else {
            return (httpResponse: nil, networkError: .missingResponse)
        }
        
        //Ensure expected response code is returned
        let statusCode = Http.StatusCode(code: httpResponse.statusCode)
        guard let method = Http.Method(value: request.httpMethod),
            responseCodeValidator.isValid(responseCode: statusCode, forHttpMethod: method) else {
                let reason = HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
                return (httpResponse: nil, networkError: .errorResponse(httpCode: statusCode, reason: reason))
        }
        
        return (httpResponse: httpResponse, networkError: nil)
    }
}

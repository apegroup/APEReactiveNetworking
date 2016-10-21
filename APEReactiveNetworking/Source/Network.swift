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
    public let rawData: Data
    public let parsedData: T
    
    public init(responseHeaders: Http.ResponseHeaders, rawData: Data, parsedData: T) {
        self.responseHeaders = responseHeaders
        self.rawData = rawData
        self.parsedData = parsedData
    }
}

//TODO: Consider customisable data, download, upload tasks
public struct Network {
    
    /// The total number of seconds to wait before aborting the network operation
    static let defaultOperationTimeoutSeconds: TimeInterval = 10
    
    /// The max number of retries before failing the network operation
    static let defaultOperationMaxRetries = 10
    
    /// The URLSession to be used to send requests
    private let session: URLSession
    
    public enum OperationError : Error {
        case parseFailure
        case missingData
        case invalidResponseType
        case unexpectedResponseCode(httpCode: Http.StatusCode, data: Data?)
        case requestFailure(error: Error)
        case timedOut
    }
    
    /// The URLSession to be used to send requests. Defaults to the shared session
    public init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    //MARK: Public
    
    /**
     Sends a request over the network
     
     - parameter request:               The request to be sent
     - parameter scheduler:             The scheduler to which the returned SignalProducer will forward events to. Defaults to the UIScheduler.
     - parameter abortAfter:            Number of seconds to wait until the operation is aborted and a 'TimedOut' failure is sent. Defaults to 'defaultOperationTimeoutSeconds'
     - parameter maxRetries:            Max number of retries before failing the operation. Implements an exponential backoff between each retry. Defaults to 'defaultOperationMaxRetries'
     
     - returns: A SignalProducer that will begin the network request when started. The 'next' event contains the Http.ResponseHeaders.
     */
    public func send(_ request: ApeURLRequest,
                     scheduler: SchedulerProtocol = UIScheduler(),
                     abortAfter: TimeInterval = Network.defaultOperationTimeoutSeconds,
                     maxRetries: Int = Network.defaultOperationMaxRetries) -> SignalProducer<Http.ResponseHeaders, Network.OperationError> {
        
        return session
            .dataTaskHttpHeaderSignalProducer(request: request)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retryWithExponentialBackoff(maxAttempts: maxRetries)
            .timeout(after: abortAfter, raising: .timedOut, on: QueueScheduler())
            .addLogging(request: request.urlRequest, abortAfter: abortAfter)
            .observe(on: scheduler)
    }
    
    /**
     Sends a request over the network.
     
     - parameter request:               The request to be sent
     - parameter scheduler:             The scheduler to which the returned SignalProducer will forward events to. Defaults to the UIScheduler.
     - parameter abortAfter:            Number of seconds to wait until the operation is aborted and a 'TimedOut' failure is sent. Defaults to 'defaultOperationTimeoutSeconds'
     - parameter maxRetries:            Max number of retries before failing the operation. Implements an exponential backoff between each retry. Defaults to 'defaultOperationMaxRetries'
     - parameter parseDataBlock:        A block that accepts the response raw data as a means to parse the it to the expected data type.
     
     - returns: A SignalProducer that will begin the network request when started. The 'next' event contains the a NetworkResponse object, containing the Http.ResponseHeaders and the parsed data.
     */
    public func send<T>(_ request: ApeURLRequest,
                     scheduler: SchedulerProtocol = UIScheduler(),
                     abortAfter: TimeInterval = Network.defaultOperationTimeoutSeconds,
                     maxRetries: Int = Network.defaultOperationMaxRetries,
                     parseDataBlock: @escaping ((Data) -> T?)) -> SignalProducer<NetworkDataResponse<T>, Network.OperationError> {
        
        return session
            .dataTaskSignalProducer(request: request, parseDataBlock: parseDataBlock)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retryWithExponentialBackoff(maxAttempts: maxRetries)
            .timeout(after: abortAfter, raising: .timedOut, on: QueueScheduler())
            .addLogging(request: request.urlRequest, abortAfter: abortAfter)
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
    func dataTaskHttpHeaderSignalProducer(request: ApeURLRequest)
        -> SignalProducer<Http.ResponseHeaders, Network.OperationError> {
            
            return SignalProducer<Http.ResponseHeaders, Network.OperationError> { observer, disposable in
                
                let task = self.dataTask(with: request.urlRequest) { data, response, error in
                    
                    let (maybeHttpResponse, networkError) = self.validate(request, error: error, response: response, data: data)
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
    func dataTaskSignalProducer<T>(request: ApeURLRequest,
                                parseDataBlock: @escaping ((Data) -> T?))
        -> SignalProducer<NetworkDataResponse<T>, Network.OperationError> {
            
            return SignalProducer<NetworkDataResponse<T>, Network.OperationError> { observer, disposable in
                
                let task = self.dataTask(with: request.urlRequest) { data, response, error in
                    
                    let (maybeHttpResponse, networkError) = self.validate(request, error: error, response: response, data: data)
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
                    
                    observer.send(value: NetworkDataResponse(responseHeaders: httpResponse.allHeaderFields,
                                                             rawData: data,
                                                             parsedData: parsedData))
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
    private func validate(_ request: ApeURLRequest,
                          error: Error?,
                          response: URLResponse?,
                          data: Data?) -> (httpResponse: HTTPURLResponse?, networkError: Network.OperationError?) {
        
        //Ensure no error occurred
        if let error = error {
            return (httpResponse: nil, networkError: .requestFailure(error: error))
        }
        
        //Ensure httpUrlResponse was returned
        guard let httpResponse = response as? HTTPURLResponse else {
            return (httpResponse: nil, networkError: .invalidResponseType)
        }
        
        //Ensure expected response code is returned
        let statusCode = Http.StatusCode(code: httpResponse.statusCode)
        guard request.acceptedResponseCodes.contains(statusCode) else {
            return (httpResponse: nil, networkError: .unexpectedResponseCode(httpCode: statusCode, data: data))
        }
        
        return (httpResponse: httpResponse, networkError: nil)
    }
}

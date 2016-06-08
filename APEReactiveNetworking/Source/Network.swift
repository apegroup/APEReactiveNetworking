//
//  Network.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-04-29.
//  Copyright © 2016 Apegroup. All rights reserved.
//


import Foundation
import ReactiveCocoa


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

    //FIXME in future versions perhaps the caller should be able to inject its own retry-handler (eg exponential backoff)
    let retryCount : Int = 2

    //FIXME in future versions perhaps the caller should be able to set its own timeout tolerance
    let timeoutTolerance : NSTimeInterval = 20


    //MARK: Public

    public init() {}

    /**
     Sends a request over the network
     
     - parameter request:               The request to be sent
     - parameter responseCodeValidator: An http status code validator that asserts that the received response code matches the expected response code. Defaults to 'ApeResponseCodeValidator'
     - parameter session:               The NSURLSession to be used. Defaults to the shared session
     - parameter scheduler:             The scheduler to which the returned SignalProducer will forward events to
     - parameter maybeParseDataBlock:   If response data is expected you should provide this parameter as a means to parse the data to the expected data type.
     
     - returns: A SignalProducer that will begin the network request when started
     */
    public func send<T>(request: NSURLRequest,
              responseCodeValidator: HttpResponseCodeValidator = ApeResponseCodeValidator(),
              session: NSURLSession = NSURLSession.sharedSession(),
              scheduler: SchedulerType = UIScheduler(),
              parseDataBlock: ((data:NSData) -> T?)? = nil) -> SignalProducer<T, NetworkError> {
        
        return session
            .dataTaskSignalProducer(
                request: request,
                responseCodeValidator: responseCodeValidator,
                parseDataBlock: parseDataBlock)
            .injectNetworkActivityIndicatorSideEffect()  //NOTE: injection must always be done before other RAC operations since it will create a new SignalProducer
            .retry(retryCount)
//            .timeoutWithError(.TimedOut, afterInterval: timeoutTolerance, onScheduler: QueueScheduler())
            .observeOn(scheduler)
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
        return self.on ( started: {
            print("# signal started")
            NetworkActivityIndicator.sharedInstance.enabled = true
            }, failed: { error in
                print("# signal failed: \(error)")
            }, completed: {
                print("# signal completed")
            }, interrupted: {
                print("# signal interrupted")
            }, terminated: {
                print("# signal terminated")
                NetworkActivityIndicator.sharedInstance.enabled = false
            }
        )
    }
}
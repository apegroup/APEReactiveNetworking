# APEReactiveNetworking

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

A light-weight networking library based on ReactiveCocoa 4.x

## Features
- PUT, POST, DELETE, GET, PATCH operations
- Possibility to add custom request headers
- Reactive oriented, based on ReactiveCocoa 4.x 
- Automatically updates the network activity indicator
- Possibility to customize authentication handlder, default implementation saves JWT token in safe storage (Keychain)
- 100% Swift (Swift 2.X)
- Powering Swift Generics
- Access to all HTTP response headers
- Light-weigth, less than 600 lines of code (including whitespace, comments and other meta lines)
- Automatic retry mechanism with possiblity to define max number of retries (exponential back-off strategy)
- Deterministic response time (successful, error or timeout), ie abort after X seconds
- Possibility to customize response code validation, default implementation accepts 200-299 codes
- Code coverage at X %
- Example project available, using all network methods and binding to UI (a full reactive chain)

## Does not support
- Multipart request
- ? 

## Future improvements
- Improve the README file with logo, example and architecture
- Support for background download/upload by the OS
- Add more testcases
- Project logo
- Async image downloads  for cell updating (extension of UIImage?)
- Support for cookie headers (since Google AppEngine does not support setting Response headers, we cannot set a new jwt token in headers)
- A custom NSURLSession with request timeout set to 10 s
- Add HTTPS  + SSL certificate validation support
- Consider response caching (using HTTP headers: ETag, If-Modified-Since, Last-Modified)
- Extend the Example project with more api methods, better commenting etc








## Usage example

```swift
import APEReactiveNetworking
import ReactiveCocoa
import enum Result.NoError

/**
  The authentication handler is used to
  - set the value of the 'Authorization' http header field in the request
  - handle received credentials/tokens, etc, e.g. by storing them in the keychain
 **/
let authHandler: AuthenticationHandler = ApeJwtAuthenticationHandler()


/**
- The 'authenticateUser()' method returns the response value of 'Network::send()'.
- 'Network::send()' returns a 'ReactiveCocoa::SignalProducer<NetworkDataResponse<AuthResponse>, Network.Error>', where 'AuthResponse' is expected response data model.
**/
func onLoginButtonTapped() {
  let signalProducer<NetworkDataResponse<AuthResponse>, Network.Error> = authenticateUser("ape", password: "ape123")
    signalProducer.start { event in
      switch event {
        case .Next(let networkDataResponse):
          let authResponse = networkDataResponse.parsedData
          self.authHandler.handleAuthTokenReceived(authResponse)
        case .Failed(let error):
          print("An error occurred: \(error)")
        default: break
      }
    }
}


/** 
  Elaborate example: Sending a request.
**/
func authenticateUser(username: String, password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.Error> {

  ///1) Constructing the http request: 

  //1.1) Create an endpoint by implementing the endpoint protocol, which requires two methods to be implemented: 'absoluteUrl' and 'httpMethod'
  let endpoint: Endpoint = ApeChatApiEndpoints.AuthUser

  //1.2) Create a custom request builder by implementing the HttpRequestBuilder protocol (or use the provided default implementation 'ApeRequestBuilder')
  let builder : HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)

  //1.3) *** Optional: Provide your http request body ***
  let jsonDict: [String:AnyObject] = ["user":username, "password":password]
  builder.setBody(json: jsonDict)

  //1.4) *** Optional: Provide the request builder with a authentication handler (a type conforming to the 'AuthenticationHandler' protocol). A 'ApeJwtAuthenticationHandler' is provided by the framework *** 
  // The authentication handler is primarily used to set the 'Authorization' http header field in the http request.
  builder.addAuthHandler(self.authHandler)

  //1.5) Create the request
  let request: NSURLRequest = builder.build()


  ///Configuring the operation settings

  //2) *** Optional: Provide a custom http response code validator by implementing the 'HttpResponseCodeValidator' protocol ('ApeResponseCodeValidator', which accepts all 200-299 response codes, is provided by default)
  let validator: HttpResponseCodeValidator = ApeResponseCodeValidator()

  //3) *** Optional: Provide if you wish to use a custom NSURLSession (the 'defaultSessionConfiguration' will be used by default) ***
  let session = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration())

  //4) *** Optional: Provide a custom 'ReactiveCocoa::SchedulerType' if you wish to handle signal events on a custom queue (the main queue is used by default) ***
  let scheduler: SchedulerType = UIScheduler()

  //5) *** Optional: Provide a custom request timeout before aborting the operation (10 seconds is used by default)
  let timeoutSeconds = 20

  //6) *** Optional: Provide a max number of retries before aborting the operation (a maximum of 10 retries is the default)
  let maxNumberOfRetries = 5

  //7) *** Optional: If you are expecting data to be returned: Provide a 'parse data block' (i.e. a block that transforms the received response data to your expected model) ***
  let parseDataBlock: (data:NSData) -> AuthResponse? = { data in
    guard let authResponse = try? Unbox(data) as AuthResponse else {
      return nil
    }
    return authResponse
  }

  ///Creating the request command/signal producer

  //8) Send the request along with other configuration settings to 'Network.send()'
  return Network().send(
      request,
      responseCodeValidator: validator,
      session: session,
      scheduler: scheduler,
      abortAfter: timeoutSeconds,
      maxRetries: maxNumberOfRetries,
      parseDataBlock: parseDataBlock)
}

//Compact example: Sending the above request using the default values
func authenticateUser2(username: String,
    password: String) -> SignalProducer<NetworkDataResponse<AuthResponse>, Network.Error> {
  let request = ApeRequestBuilder(endpoint: ApeChatApiEndpoints.AuthUser)
    .setBody(json: ["user":username, "password":password])
    .addAuthHandler(self.authHandler)
    .build()

    return Network().send(request) { try? Unbox($0) }
}

```

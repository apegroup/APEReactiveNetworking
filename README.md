# APEReactiveNetworking
![Logotype](Banner.jpg)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/apegroup/APEReactiveNetworking) 
[![Version](https://cocoapod-badges.herokuapp.com/v/APEReactiveNetworking/badge.png)](https://cocoapods.org/pods/APEReactiveNetworking)
[![Version](https://img.shields.io/cocoapods/v/APEReactiveNetworking.svg?style=flat)](https://cocoapods.org/pods/APEReactiveNetworking)
![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20OS%20X-lightgrey.svg)
[![License](https://img.shields.io/cocoapods/l/Networking.svg?style=flat)](https://cocoapods.org/pods/Networking)

**APEReactiveNetworking** is simply a `reactive oriented`, `feather-weight` networking library, `made by Sweden`

We focused on building a network lib that was real-world, use-case oriented (looking at what our existing app projects actually used/needed from a networking lib) rather than implementing all sorts of functions any given project would possibly use.

It's feather-weight because we deliberately did not implement features, available in other networking libs, that is seldom used, for example multipart request-body support. Why create waste?

It's reactive based because we built it on top of [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift), which is an aswesome lib that we think will be the best Reactive lib for the Apple platforms.

We also added functions that we needed but missed in other network libraries, such as deterministic timeout time for a given request with built-in retry mechanism *(eg: Send request X with maximum 5 retries and an exponential backoff-strategy staring at 1 second, but cancel everything and timeout after maximum 10 seconds, no mather how many retries have been executed)* 

**APEReactiveNetworking** is implemented purley in `Swift 3` and powering the magic of Swift Generics.


## Features
- Feather-weight
- 100% Swift 3
- Powering Swift Generics
- Reactive oriented, based on ReactiveSwift
- Automatic retry mechanism with possiblity to define max number of retries (exponential back-off strategy)
- Deterministic response time (successful, error or timeout), i.e. abort after 'X' seconds
- Automatically updates the network activity indicator
- Possibility to add custom request headers
- Access to all HTTP response headers
- PUT, POST, DELETE, GET, PATCH operations
- Possibility to customize response code validation, default implementation accepts 200-299 codes
- Code coverage at X %
- Example project available, using all network methods and binding to UI (a full reactive chain)


## Does not support
- Multipart request
- Download/Upload tasks
- ? 

## Future improvements
- Support for background download/upload by the OS
- Add more test cases
- Async image downloads  for cell updating (extension of UIImage?)
- Support for cookie headers (since Google AppEngine does not support setting Response headers, we cannot set a new jwt token in headers)
- A custom URLSession with request timeout set to 10 s
- Add HTTPS  + SSL certificate validation support
- Consider response caching (using HTTP headers: ETag, If-Modified-Since, Last-Modified)
- Extend the Example project with more api methods, better commenting etc








## Usage example

```swift
import APEReactiveNetworking
import ReactiveSwift
import enum Result.NoError

/**
  The authentication handler is used to
  - set the value of the 'Authorization' http header field in the request
  - handle received credentials/tokens, etc, e.g. by storing them in the keychain
 **/
let authHandler: AuthenticationHandler = ApeJwtAuthenticationHandler()


/**
- The 'authenticateUser()' method returns the response value of 'Network::send()'.
- 'Network::send()' returns a 'ReactiveSwift::SignalProducer<NetworkDataResponse<AuthResponse>, Network.Error>', where 'AuthResponse' is expected response data model.
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

  //1.1) Create an endpoint by implementing the endpoint protocol, which requires three methods to be implemented: 'absoluteUrl', 'httpMethod' and 'acceptedResponseCodes'
  let endpoint: Endpoint = ApeChatApiEndpoints.AuthUser

  //1.2) Create a custom request builder by implementing the HttpRequestBuilder protocol (or use the provided default implementation 'ApeRequestBuilder')
  let builder : HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)

  //1.3) *** Optional: Provide your http request body ***
  let jsonDict: [String:AnyObject] = ["user":username, "password":password]
  builder.setBody(json: jsonDict)

  //1.4) *** Optional: Provide the request builder with a authentication handler (a type conforming to the 'AuthenticationHandler' protocol). A 'ApeJwtAuthenticationHandler' is provided by the framework *** 
  // The authentication handler is primarily used to set the 'Authorization' http header field in the http request.
  builder.add(authHandler: self.authHandler)

  //1.5) Create the request
  let request: ApeURLRequest = builder.build()


  ///Configuring the operation settings

  //2) *** Optional: Provide if you wish to use a custom URLSession (the 'defaultSessionConfiguration' will be used by default) ***
  let session = URLSession(configuration: URLSessionConfiguration.defaultSessionConfiguration())

  //4) *** Optional: Provide a custom 'ReactiveSwift::SchedulerProtocol' if you wish to handle signal events on a custom queue (the main queue is used by default) ***
  let scheduler: SchedulerProtocol = UIScheduler()

  //5) *** Optional: Provide a custom request timeout before aborting the operation (10 seconds is used by default)
  let timeoutSeconds = 20

  //6) *** Optional: Provide a max number of retries before aborting the operation (a maximum of 10 retries is the default)
  let maxNumberOfRetries = 5

  //7) *** Optional: If you are expecting data to be returned: Provide a 'parse data block' (i.e. a block that transforms the received response data to your expected model) ***
  let parseDataBlock: (Data) -> AuthResponse? = { data in
    guard let authResponse = try? Unbox(data) as AuthResponse else {
      return nil
    }
    return authResponse
  }

  ///Creating the request command/signal producer

  //8) Send the request along with other configuration settings to 'Network.send()'
  return Network(session: session).send(
      request,
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
    .add(authHandler: self.authHandler)
    .build()

    return Network().send(request) { try? Unbox($0) }
}

```

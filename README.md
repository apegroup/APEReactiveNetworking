# APEReactiveNetworking
![Logotype](Banner.jpg)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/apegroup/APEReactiveNetworking) 
[![Version](https://img.shields.io/cocoapods/v/APEReactiveNetworking.svg?style=flat)](https://cocoapods.org/pods/APEReactiveNetworking)
[![Language](https://img.shields.io/badge/language-Swift%203.0-orange.svg)](https://swift.org/)
![platforms](https://img.shields.io/badge/platforms-iOS%20%7C%20OS%20X-lightgrey.svg)
[![License](https://img.shields.io/cocoapods/l/Networking.svg?style=flat)](https://cocoapods.org/pods/Networking)

**APEReactiveNetworking** is simply a `reactive oriented`, `lightweight` networking library, made by [Apegroup](http://www.apegroup.com)

We focused on building a network lib that was real-world, use-case oriented (looking at what our existing app projects actually used/needed from a networking lib) rather than implementing all sorts of functions any given project would possibly use.

It's lightweight because we deliberately did not implement features, available in other networking libs, that are seldom used, for example multipart request-body support. Why create waste?

It's reactive based because we built it on top of [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift), which is an aswesome lib that we think will be the best Reactive lib for the Apple platforms.

**APEReactiveNetworking** is implemented purley in `Swift 3` and powering the magic of Swift Generics. Its used in production by [BLOX](https://itunes.apple.com/se/app/blox-by-apegroup/id1162178318?mt=8&ign-mpt=uo%3D2) iOS app among others.


## Features
- [x] Feather-weight
- [x] 100% Swift 3
- [x] Powering Swift Generics
- [x] Reactive oriented, based on ReactiveSwift
- [x] Automatic retry mechanism with possiblity to define max number of retries (exponential back-off strategy)
- [x] Deterministic response time (successful, error or timeout), i.e. abort after 'X' seconds
- [x] Automatically updates the network activity indicator
- [x] Possibility to add custom request headers
- [x] Access to all HTTP response headers
- [x] PUT, POST, DELETE, GET, PATCH operations
- [x] Possibility to customize response code validation (default implementation accepts 200-299 codes)
- [ ] Example project available
- [ ] Code coverage at X % 

## Future improvements
- [ ] Support for background download/upload by the OS
- [ ] Async image downloads for cell updating (extension of UIImage?)
- [ ] Support for cookie headers (since Google AppEngine does not support setting Response headers, we cannot set a new jwt token in headers)
- [ ] A custom URLSession with request timeout set to 10 s
- [ ] Add HTTPS  + SSL certificate validation support
- [ ] Consider response caching (using HTTP headers: ETag, If-Modified-Since, Last-Modified)
- [ ] Extend the Example project
- [ ] Add more test cases



## Table of Contents

  * [Requirements](#requirements)
  * [Installation](#installation)
    * [Carthage](#carthage)
    * [CocoaPods](#cocoapods)
  * [Usage](#usage)
    * [Create your endpoints](#create-your-endpoints)
    * [Create your request](#create-your-request)
    * [Authentication](#authentication)
      * [HTTP basic](#http-basic)
      * [Bearer token](#bearer-token)
      * [Custom authentication header](#custom-authentication-header)
    * [Setting custom http headers](#setting-custom-http-headers)
    * [Setting the request body](#setting-the-request-body)
      * [JSON](#json)
      * [Plain Text](#plain-text)
      * [Custom content type](#custom-content-type)
    * [Sending a request](#sending-a-request)
    * [Handling a response](#handling-a-response)
      * [Response without data](#response-without-data)
      * [Response with data](#response-with-data)
      * [Error handling](#error-handling)
      * [Configuring the request operation](#configuring-the-request-operation)
        * [Retries](#retries)
        * [Timeout](#timeout)
        * [Scheduler](#scheduler)
  * [Author](#author)
  * [Attribution](#attribution)
  * [Constribution](#contribution)
  * [License](#license)

## Requirements

- iOS 9.0 or greater
- Xcode 8 (Swift 3.0) or later

- Dependencies:
  - [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift)

## Installation

### Carthage


### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `APEReactiveNetworking` by adding it to your `Podfile`:
```ruby
platform :ios, '9.0'
use_frameworks!

target '<MyApp>' do
    pod 'APEReactiveNetworking'
end
```

## Usage

### Create your endpoints

An endpoint is a type that conforms to the 'Endpoint' protocol and describes the endpoints that your client communicates with.

```swift
public protocol Endpoint {
    var httpMethod: Http.Method { get }
    var absoluteUrl: String { get }
    var acceptedResponseCodes: [Http.StatusCode] { get }
}
```

Example of conforming to the 'Endpoint' protocol:
```swift
struct ApegroupEndpoint: Endpoint {
    var httpMethod = Http.Method.get
    var absoluteUrl = "http://www.apegroup.com"
    var acceptedResponseCodes = [Http.StatusCode.ok]
}
```

### Create your request

Build your request by using a 'HttpRequestBuilder'.

```swift
public protocol HttpRequestBuilder {
    init(endpoint: Endpoint)
    func addHeader(_ header: (key: String, value: String)) -> HttpRequestBuilder
    func setHeaders(_ headers: Http.RequestHeaders) -> HttpRequestBuilder
    func setBody(data: Data, contentType: Http.ContentType) -> HttpRequestBuilder
    func build() -> ApeURLRequest
}
```

'ApeRequestBuilder', a type conforming to the 'HttpRequestBuilder' protocol, is provided by the framework:
```swift
let endpoint = ApegroupEndpoint()
let requestBuilder: HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)
let request: ApeURLRequest = requestBuilder.build()
```

### Authentication
#### HTTP Basic

To authenticate using [basic authentication](http://www.w3.org/Protocols/HTTP/1.0/spec.html#BasicAA) with a username **"ape"** and password **"group"** you only need to do this:

```swift
let endpoint = ApegroupEndpoint()
let requestBuilder = try ApeRequestBuilder(endpoint: endpoint).setAuthorizationHeader(username: "ape", password: "group")
```
#### Bearer token

To authenticate using a [bearer token](https://tools.ietf.org/html/rfc6750) **"ASDFASDFASDF12345"** you only need to do this:

```swift
let endpoint = ApegroupEndpoint()
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).setAuthorizationHeader(token: "ASDFASDFASDF12345")
```

#### Custom authentication header
To authenticate using a custom authentication header, for example **"Token token=ASDFASDFASDF12345"** you would need to set the following header field: `Authorization: Token token=ASDFASDFASDF12345`. Simply do this:

```swift
let endpoint = ApegroupEndpoint()
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).setAuthorizationHeader(headerValue: "Token token=ASDFASDFASDF12345")
```

### Setting custom http headers
There are two ways of setting your own http headers.

By setting all the headers (which will replace existing key-values):
```swift
let customHeaders: Http.RequestHeaders = ["CustomKey1": "CustomValue1", "CustomKey2" : "CustomValue2"]
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).setHeaders(customHeaders)
```

Or by adding a single header entry (if the header already exists it will be replaced by the new value):
```swift
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).addHeader(("CustomKey","CustomValue"))
```

### Setting the request body
#### JSON
```swift
let jsonBody: [String : Any] = ["key":"value"]
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).setBody(json: jsonBody)
```

#### Plain Text
```swift
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).setBody(text: "plain text body")
```

#### Custom content type
```swift
let image: UIImage = ...
let imageData = UIImagePNGRepresentation(image)!
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).setBody(data: imageData, contentType: Http.ContentType.imagePng)
```

### Sending a request

Requests are sent using the 'Network' API.

Using the default URLSessionConfiguration
```swift
let network = Network()
```

Using a custom URLSessionConfiguration
```swift
let customConfiguration = URLSessionConfiguration()
let customSession = URLSession(configuration: customConfiguration)
let network = Network(session: customSession)
```

To send a request, simply create a request operation (i.e. a SignalProducer), by calling the send method.
(Remember to import 'ReactiveSwift' and to start the signal producer)
```swift
import ReactiveSwift

let endpoint = ApegroupEndpoint()
let requestBuilder = ApeRequestBuilder(endpoint: endpoint)
let request = requestBuilder.build()
let network = Network()
let signalProducer: SignalProducer<Http.ResponseHeaders, Network.OperationError> = network.send(request)
signalProducer.start()
```

### Handling a response

Response handling is performed in a reactive manner by providing closures to the SignalProducer

```swift
import ReactiveSwift

let endpoint = ApegroupEndpoint()
let requestBuilder = ApeRequestBuilder(endpoint: endpoint)
let request = requestBuilder.build()
let network = Network()
```

#### Response without data
By default, only the response http headers are returned by the SignalProducer 

```swift
let signalProducer: SignalProducer<Http.ResponseHeaders, Network.OperationError> = network.send(request)
signalProducer.on(
  failed: { (error: Network.OperationError) in
    print("Network operation failed with error: \(error)")
  }, completed: {
    print("Successfully sent a request!")
}).start()
```

#### Response with data
If you expect response data to be returned, simply pass an additional parameter, `parseDataBlock`, to the method `Network.send()`. The parseDataBlock specifies how to convert the raw response data to your desired model type.

The SignalProducer will send a generic wrapper object parameterized with your model type 'T', `NetworkDataResponse<T>`, which contains:
- the raw response data
- your parsed data model
- the http response headers

```swift
struct MyModel {
  init(from: Data) {}
}

let signalProducer: SignalProducer<NetworkDataResponse<MyModel>, Network.OperationError> =
network.send(request, parseDataBlock: { (data: Data) -> MyModel? in 
  return MyModel(from: data) 
})
        
signalProducer.on(value: { (response: NetworkDataResponse<MyModel>) in
  let rawData: Data = response.rawData
  let model: Model = response.parsedData
  let responseHeaders: Http.ResponseHeaders = response.responseHeaders
  print("Received response data successfully")
}}).start()
```

#### Error handling
APEReactiveNetworking defines the following error type:

```swift
public enum OperationError : Error {
  case parseFailure
  case missingData
  case invalidResponseType
  case unexpectedResponseCode(httpCode: Http.StatusCode, data: Data?)
  case requestFailure(error: Error)
  case timedOut
}
```

Error handling is performed in the usual 'failed' closure of the SignalProducer:

```swift
signalProducer.on(failed: { (operationError: Network.OperationError) in
  switch operationError {
    case .requestFailure(let error):
      print("Request failed with error: \(error)")
    case let .unexpectedResponseCode(code, data):
      print("Received unexpected response code: \(code.rawValue)")
    case .timedOut:
      print("Operation timed out")
    case .missingData:
      print("Expected response data is missing")
    case .parseFailure:
      print("Failed to parse the response data to MyModel")
    case .invalidResponseType:
      print("Expected HTTPURLResponse")
  }
}).start()
```

### Configuring the request operation
It is possible configure the network operation in the following ways:
  - Setting a max number of retries before aborting the operation
  - Setting a timeout limit before aborting the operation
  - Specifying a Scheduler to which the returned SignalProducer will forward events to

##### Retries
The default max number of retries is 10. It is possible to override this value by providing the `maxRetries` parameter in the `Network.send()` method.

The retries are performed using an exponential backoff strategy between each retry, starting from 1 (it is currently not possible to start from custom values, which might be useful e.g. after reading the 'Retry-After' response header).

```swift
let maxNumberOfRetries = 3
Network().send(request, maxRetries: maxNumberOfRetries).start()
```

##### Timeout
The default timeout is 10 seconds. It is possible to override this value by providing the `abortAfter` parameter in the `Network.send()` method. If the operation times out a 'TimedOut' error is sent.

```swift
let maxSecondsAllowed: TimeInterval = 5
Network().send(request, abortAfter: maxSecondsAllowed).start()
```

##### Scheduler
The default scheduler to which the SignalProducer will forward events to is the UIScheduler. It is possible to override this value by providing the `scheduler` parameter in the `Network.send()` method.

```swift
let myScheduler: SchedulerProtocol = QueueScheduler()
Network().send(request, scheduler: myScheduler).start()
```

### Author
### Attribution
### Contribution

### License
APEReactiveNetworking is released under the MIT license. See LICENSE for details.


## Advanced Usage example


  1) Create an endpoint by implementing the endpoint protocol, which requires three methods to be implemented: 'absoluteUrl', 'httpMethod' and 'acceptedResponseCodes'
  ```swift
  public protocol Endpoint {
    var httpMethod: Http.Method { get }
    var absoluteUrl: String { get }
    var acceptedResponseCodes: [Http.StatusCode] { get }
  }
```

```swift
import APEReactiveNetworking
import ReactiveSwift
import enum Result.NoError


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
        case .Failed(let error):
          print("An error occurred: \(error)")
        default: break
      }
    }
}

```

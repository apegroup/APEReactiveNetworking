# APEReactiveNetworking
![Logotype](Banner.jpg)

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/apegroup/APEReactiveNetworking) 
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
- [x] Automatic retry mechanism (exponential back-off strategy)
- [x] Deterministic response time (successful, error or timeout), i.e. abort after 'X' seconds
- [x] Automatically updates the network activity indicator
- [x] Possibility to add custom request headers
- [x] Access to all HTTP response headers
- [x] Automatically adds device info, such as OS-version, as a few X-headers in all requests
- [x] PUT, POST, DELETE, GET, PATCH operations
- [x] Possibility to customize response code validation (default implementation accepts 200-299 codes)
- [x] Example project available
- [ ] Code coverage at X % 

## Future improvements
- [ ] Support for starting the retry mechanism from a custom value, e.g. reading the *Retry-After* header and starting from that value (retries are currently performed using an exponential backoff strategy between each retry, starting from 1)
- [ ] Support for background download/upload by the OS
- [ ] Async image downloads for cell updating (extension of UIImage?)
- [ ] Add cookie support 
- [ ] A custom URLSession with request timeout set to 10 s
- [ ] Add HTTPS  + SSL certificate validation support
- [ ] Consider response caching (using HTTP headers: ETag, If-Modified-Since, Last-Modified)
- [ ] Extend the Example project
- [ ] Add more test cases



## Table of Contents

  * [Requirements](#requirements)
  * [Installation](#installation)
    * [Carthage](#carthage)
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
        * [Timeout](#timeout)
        * [Scheduler](#scheduler)
    * [Caching](#caching) 
  * [Example](#example)  
  * [Author](#author)
  * [Constribution](#contribution)
  * [License](#license)

## Requirements

- iOS 9.0 or greater
- Xcode 8 (Swift 3.0) or later

- Dependencies:
  - [ReactiveSwift](https://github.com/ReactiveCocoa/ReactiveSwift)

## Installation

### Carthage

You can use [Carthage](https://github.com/Carthage/Carthage) to install `APEReactiveNetworking` by adding it to your `Cartfile`:

```
github "apegroup/APEReactiveNetworking"
```

## Usage

### Create your endpoints

An endpoint is a type that conforms to the `Endpoint` protocol and describes the endpoints that your client communicates with.

```swift
public protocol Endpoint {
    var httpMethod: Http.Method { get }
    var absoluteUrl: String { get }
    var acceptedResponseCodes: [Http.StatusCode] { get }
}
```

Example of conforming to the `Endpoint` protocol:
```swift
enum UserAPI: Endpoint {

  //MARK: - Endpoints

  case getUser(id: String)
  case getUsers
  case createUser
  case updateUser(id: String)
  case deleteUser(id: String)

  //MARK: - Endpoint protocol conformance

  var httpMethod : Http.Method {
  switch self {
    case .updateUser, .createUser:      return .post
    case .deleteUser:                   return .delete
    default:                            return .get
    }
  }

  var absoluteUrl: String {
    let baseUrl = "https://api.apegroup.com"
    let path: String

    switch self {
      case .getUser(let userId), .updateUser(let userId), .deleteUser(let userId):
        path = "/users/\(userId)"
      case .getUsers, .createUser:
        path = "/users/"
    }

    return baseUrl + path
  }

  var acceptedResponseCodes : [Http.StatusCode] {
    switch self {
      case .deleteUser:       return [.noContent]
      default:                return [.ok, .created]
    }
  }
}
```

### Create your request

Build your request by using a `HttpRequestBuilder`.

```swift
public protocol HttpRequestBuilder {
    init(endpoint: Endpoint)
    func setHeader(_ header: (key: String, value: String)) -> HttpRequestBuilder
    func setBody(data: Data, contentType: Http.ContentType) -> HttpRequestBuilder
    func build() -> ApeURLRequest
}
```

`ApeRequestBuilder`, a type conforming to the 'HttpRequestBuilder' protocol, is provided by the framework:

```swift
let endpoint = UserAPI.getUsers
let requestBuilder: HttpRequestBuilder = ApeRequestBuilder(endpoint: endpoint)
let request: ApeURLRequest = requestBuilder.build()
```

When using the built-in `ApeRequestBuilder` the following http headers will be included in each request:
```swift
- "X-Client-OS" // The name of the operating system running on the device represented by the receiver, e.g. "iOS"
- "X-Client-OS-Version" // The current version of the operating system, e.g. "10.0"
- "X-Client-Device-Type" // The device model name, e.g. "iPhone 6s Plus"
- "X-Client-Device-VendorId"  // An alphanumeric string that is the same for apps that come from the same vendor running on the same device, or "unknown" if unavailable, e.g. "9C32B72F-8532-4F73-BA76-18C9E522E539"
```

### Authentication
#### HTTP Basic

To authenticate using [basic authentication](http://www.w3.org/Protocols/HTTP/1.0/spec.html#BasicAA) with a username **"ape"** and password **"group"** you only need to do this:

```swift
let endpoint = UserAPI.getUsers
let requestBuilder = try ApeRequestBuilder(endpoint: endpoint).setAuthorizationHeader(username: "ape", password: "group")
```
#### Bearer token

To authenticate using a [bearer token](https://tools.ietf.org/html/rfc6750) **"ASDFASDFASDF12345"** you only need to do this:

```swift
let endpoint = UserAPI.getUsers
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).setAuthorizationHeader(token: "ASDFASDFASDF12345")
```

#### Custom authentication header
To authenticate using a custom authentication header, for example **"Token token=ASDFASDFASDF12345"** you would need to set the following header field: `Authorization: Token token=ASDFASDFASDF12345`. Simply do this:

```swift
let endpoint = UserAPI.getUsers
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
let requestBuilder = ApeRequestBuilder(endpoint: endpoint).setHeader(("CustomKey","CustomValue"))
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

Requests are sent using the `Network` API.

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
(Remember to import `ReactiveSwift` and to start the signal producer)
```swift
import ReactiveSwift

let endpoint = UserAPI.getUsers
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

let endpoint = UserAPI.getUsers
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

Error handling is performed in the usual *failed* closure of the SignalProducer:

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
  - Setting a timeout limit before aborting the operation
  - Specifying a Scheduler to which the returned SignalProducer will forward events to

##### Abort-after
The default abort-after time is 10 seconds, i.e. no mather how many retries or sleep between each retry, the signal will abort after the specified number of seconds and return a `TimeOut` error. It is possible to override this value by providing the `abortAfter` parameter in the `Network.send()` method. 

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

### Caching
What about caching?

This network layer, deliberately, does not concern itself with caching, it relies on the cache settings of the `URLSession` sent as a parameter in the `Network` constructor (defaults to using the default URLSession). So you if you want custom cache behaviour, you can either create your own `URLSession` with a custom `URLSessionConfiguration` and pass it into the Network constructor or you can configure the shared `URLCache` settings, eg in your AppDelegate.

#### Configuring the shared URL cache 
```swift
let URLCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 20 * 1024 * 1024, diskPath: nil)
URLCache.setSharedURLCache(URLCache)
```

#### Using a custom URLSession
```swift
  let cachesDirectory = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first
  let cachePath = cachesDirectory?.appending("MyCache")
  let cache = URLCache(memoryCapacity: 16384, diskCapacity: 268435456, diskPath: cachePath)

  let defaultSessionConfiguration = URLSessionConfiguration.default
  defaultSessionConfiguration.urlCache = cache
  defaultSessionConfiguration.requestCachePolicy = .useProtocolCachePolicy

  let urlSession = URLSession(configuration: defaultSessionConfiguration)

  let network = Network(session: urlSession)
```

## Example
Here is a trivial example, for more elaborate example take a look at the included example project.

```swift
func updateUserProfile(userId: String, firstname: String) -> SignalProducer<Http.ResponseHeaders, Network.OperationError> {
  let endpoint = UserAPI.updateUser(id: userId)

  let jsonBody: [String : Any] = ["firstname": firstname]

  let request = ApeRequestBuilder(endpoint: endpoint)
                 .setAuthorizationHeader(token: "<my secret auth token>")
                 .setBody(json: jsonBody)
                 .build()

  return Network().send(request)
}
```


### Author
[Apegroup AB](http://www.apegroup.com), Stockholm, Sweden

### Contribution
All people are welcome to contribute. See [CONTRIBUTING](https://github.com/apegroup/APEReactiveNetworking/blob/master/CONTRIBUTING.md) for details.

### License
APEReactiveNetworking is released under the MIT license. See [LICENSE](https://github.com/apegroup/APEReactiveNetworking/blob/master/LICENSE) for details.

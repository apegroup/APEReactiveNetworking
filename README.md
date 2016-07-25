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


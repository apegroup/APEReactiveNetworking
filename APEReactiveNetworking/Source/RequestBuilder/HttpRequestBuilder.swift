//
//  HttpRequestBuilder.swift
//  APEReactiveNetworking
//
//  Created by Dennis Korkchi on 07/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

public protocol HttpRequestBuilder {

    init(endpoint: Endpoint)
    
    /// Adds a header entry to the HttpHeaders. If an entry with the received key already exists it will be overwritten.
    func addHeader(_ header: (key: String, value: String)) -> HttpRequestBuilder
    
    /// Sets the HttpHeaders. Overwrites all existing headers
    func setHeaders(_ headers: Http.RequestHeaders) -> HttpRequestBuilder

    func setBody(data: Data, contentType: Http.ContentType) -> HttpRequestBuilder

    func build() -> ApeURLRequest
}

enum HttpRequestBuilderError: Error {
    case encodeError
}

public extension HttpRequestBuilder {
    
    //MARK: - Headers
    
    private var authorizationHeaderKey: String { return "Authorization" }
    
    /**
     Sets the authorization header according to the Basic authentcation scheme (i.e. "Basic <base64-encoded username:password>")
    
     - parameter username: The username
     - parameter password: The plain text password
     
     - throws: Throws a HttpRequestBuilderError.encodeError if unable to encode the received parameters
     */
    public func setAuthorizationHeader(username: String, password: String) throws -> HttpRequestBuilder {
        let credentialsString = "\(username):\(password)"
        guard let credentialsData = credentialsString.data(using: .utf8) else {
            throw HttpRequestBuilderError.encodeError
        }
        
        let base64Credentials = credentialsData.base64EncodedString(options: [])
        return addHeader((key: authorizationHeaderKey, value: "Basic \(base64Credentials)"))
    }
    
    /// Sets the authorization header to "Bearer \(token)"
    public func setAuthorizationHeader(token: String) -> HttpRequestBuilder {
        return addHeader((key: authorizationHeaderKey, value: "Bearer \(token)"))
    }
    
    /// Sets the authorization header to a custom value
    public func setAuthorizationHeader(headerValue: String) -> HttpRequestBuilder {
        return addHeader((key: authorizationHeaderKey, value: headerValue))
    }
    
    
    //MARK: - Body

    public func setBody(json: [String:Any]) -> HttpRequestBuilder {
        guard let rawData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            preconditionFailure("Json dictionary could not be converted to Data")
        }
        return setBody(data: rawData, contentType: .applicationJson)
    }

    public func setBody(text: String) -> HttpRequestBuilder {
        guard let rawData = text.data(using: String.Encoding.utf8) else {
            preconditionFailure("Plain text could not be encoded to Data")
        }
        return setBody(data: rawData, contentType: .textPlain)
    }
}

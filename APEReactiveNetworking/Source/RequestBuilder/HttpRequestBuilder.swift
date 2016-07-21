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

    func addAuthHandler(authHandler: AuthenticationHandler) -> HttpRequestBuilder

    func addHeaders(headers: HttpHeaders) -> HttpRequestBuilder

    func setBody(rawData rawData: NSData, contentType: HttpContentType) -> HttpRequestBuilder

    func build() -> NSURLRequest
}


//Work around in Swift 2.2 in order to use default arguments in Protocols
extension HttpRequestBuilder {

    // MARK: Regular

    public func setBody(json json: [String:AnyObject]) -> HttpRequestBuilder {
        guard let rawData = try? NSJSONSerialization.dataWithJSONObject(json, options: []) else {
            preconditionFailure("Json dictionary could not be converted to NSData")
        }
        return setBody(rawData: rawData, contentType: .ApplicationJson)
    }

    public func setBody(text text: String) -> HttpRequestBuilder {
        guard let rawData = text.dataUsingEncoding(NSUTF8StringEncoding) else {
            preconditionFailure("Plain text could not be encoded to NSData")
        }
        return setBody(rawData: rawData, contentType: .TextPlain)
    }
    
}
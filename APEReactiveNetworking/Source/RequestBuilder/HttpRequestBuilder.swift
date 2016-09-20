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

    func addHeaders(headers: HttpRequestHeaders) -> HttpRequestBuilder

    func setBody(rawData: Data, contentType: HttpContentType) -> HttpRequestBuilder

    func build() -> URLRequest
}


//Work around in Swift 2.2 in order to use default arguments in Protocols
extension HttpRequestBuilder {

    // MARK: Regular

    public func setBody(json: [String:AnyObject]) -> HttpRequestBuilder {
        guard let rawData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            preconditionFailure("Json dictionary could not be converted to Data")
        }
        return setBody(rawData: rawData, contentType: .applicationJson)
    }

    public func setBody(text: String) -> HttpRequestBuilder {
        guard let rawData = text.data(using: String.Encoding.utf8) else {
            preconditionFailure("Plain text could not be encoded to Data")
        }
        return setBody(rawData: rawData, contentType: .textPlain)
    }
    
}

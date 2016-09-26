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

    func add(authHandler: AuthenticationHandler) -> HttpRequestBuilder

    func add(headers: Http.RequestHeaders) -> HttpRequestBuilder

    func setBody(data: Data, contentType: Http.ContentType) -> HttpRequestBuilder

    func build() -> URLRequest
}

public extension HttpRequestBuilder {

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

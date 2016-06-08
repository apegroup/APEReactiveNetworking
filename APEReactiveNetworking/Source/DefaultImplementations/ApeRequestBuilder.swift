//
//  ApeRequestBuilder.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 11/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation


public class ApeRequestBuilder: HttpRequestBuilder {

    private let endpoint : Endpoint
    private var authHeader: String?
    private var contentTypeHeader = HttpContentType.ApplicationJson
    private var additionalHeaders: HttpHeaders?
    private var bodyData: NSData?

    // MARK: Public

    required public init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    public func addHeaders(headers: HttpHeaders) -> HttpRequestBuilder {
        self.additionalHeaders = headers
        return self
    }


    public func setBody(rawData rawData: NSData,
                         contentType: HttpContentType) -> HttpRequestBuilder {

        self.contentTypeHeader = contentType
        self.bodyData = rawData
        return self
    }


    public func addAuthHandler(authHandler: AuthenticationHandler) -> HttpRequestBuilder {
        self.authHeader = authHandler.authHeader
        return self
    }

    ///Builds a NSURLRequest with the provided components
    public  func build() -> NSURLRequest {
        let headers = generateHeaders()
        let request = generateRequest(headers, body: bodyData)
        return request
    }


    // MARK: Private

    private func generateHeaders() -> HttpHeaders {
        var headers: HttpHeaders = [:]

        if let authorizationHeaderValue = authHeader {
            headers["Authorization"] = authorizationHeaderValue
        }

        headers["Content-Type"] = contentTypeHeader.description

        //FIXME - remove hard coded values
        headers["X-Apegroup-Client-OS"] = "9.1"
        headers["X-Apegroup-Client-App-Version"] = "0.1"
        headers["X-Apegroup-Device-Type"] = "iPhone 6S"
        headers["Accept-Language"] = "sv-SE"

        return headers
    }


    private func generateRequest(headers: HttpHeaders, body: NSData?) -> NSURLRequest {
        guard let url = NSURL(string: endpoint.absoluteUrl) else {
            preconditionFailure("Endpoint contains invalid url")
        }

        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = endpoint.httpMethod.rawValue

        request.HTTPBody = body

        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }

        return request
    }


}


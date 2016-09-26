//
//  ApeRequestBuilder.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 11/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

public final class ApeRequestBuilder: HttpRequestBuilder {

    private let endpoint: Endpoint
    private var authHeader: String?
    private var contentTypeHeader = Http.ContentType.applicationJson
    private var additionalHeaders: Http.RequestHeaders?
    private var bodyData: Data?

    // MARK: Public

    public init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    public func add(authHandler: AuthenticationHandler) -> HttpRequestBuilder {
        self.authHeader = authHandler.authHeader
        return self
    }
    
    public func add(headers: Http.RequestHeaders) -> HttpRequestBuilder {
        self.additionalHeaders = headers
        return self
    }


    public func setBody(data: Data, contentType: Http.ContentType) -> HttpRequestBuilder {
        self.contentTypeHeader = contentType
        self.bodyData = data
        return self
    }

    ///Builds a URLRequest with the provided components
    public func build() -> URLRequest {
        let headers = makeHeaders()
        let request = makeRequest(with: headers, body: bodyData)
        return request
    }


    // MARK: Private

    private func makeHeaders() -> Http.RequestHeaders {
        var headers: Http.RequestHeaders = self.additionalHeaders ?? [:]

        if let authorizationHeaderValue = authHeader {
            headers["Authorization"] = authorizationHeaderValue
        }

        headers["Content-Type"] = contentTypeHeader.description
        
        let device = UIDevice.current
        headers["X-Apegroup-Client-OS"] = device.systemName
        headers["X-Apegroup-Client-OS-Version"] = device.systemVersion
        headers["X-Apegroup-Client-Device-Type"] = device.modelName
        headers["X-Apegroup-Client-Device-VendorId"] = device.identifierForVendor?.uuidString ?? "unknown"
        
        //FIXME: Fix headers below
        //headers["X-Apegroup-Client-App-Version"] = "0.1"
        //headers["Accept-Language"] = "sv-SE"

        return headers
    }


    private func makeRequest(with headers: Http.RequestHeaders, body: Data?) -> URLRequest {
        guard let url = URL(string: endpoint.absoluteUrl) else {
            preconditionFailure("Endpoint contains invalid url: '\(endpoint.absoluteUrl)'")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod.rawValue
        request.httpBody = body

        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }

        return request
    }
}

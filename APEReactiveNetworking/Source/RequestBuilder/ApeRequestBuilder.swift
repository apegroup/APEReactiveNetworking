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
    private var contentTypeHeader = Http.ContentType.applicationJson
    private var additionalHeaders: Http.RequestHeaders = [:]
    private var bodyData: Data?

    // MARK: Public

    public init(endpoint: Endpoint) {
        self.endpoint = endpoint
    }
    
    public func setHeader(_ header: (key: String, value: String)) -> HttpRequestBuilder {
        additionalHeaders[header.key] = header.value
        return self
    }

    public func setBody(data: Data, contentType: Http.ContentType) -> HttpRequestBuilder {
        self.contentTypeHeader = contentType
        self.bodyData = data
        return self
    }

    ///Builds a URLRequest with the provided components
    public func build() -> ApeURLRequest {
        let headers = makeHeaders()
        return makeRequest(with: headers, body: bodyData)
    }


    // MARK: Private

    private func makeHeaders() -> Http.RequestHeaders {
        var headers = self.additionalHeaders
        headers["Content-Type"] = contentTypeHeader.description
        
        let device = UIDevice.current
        headers["X-Client-OS"] = device.systemName
        headers["X-Client-OS-Version"] = device.systemVersion
        headers["X-Client-Device-Type"] = device.modelName
        headers["X-Client-Device-VendorId"] = device.identifierForVendor?.uuidString ?? "unknown"
        
        //FIXME: Fix headers below
        //headers["X-Apegroup-Client-App-Version"] = "0.1"
        //headers["Accept-Language"] = "sv-SE"

        return headers
    }


    private func makeRequest(with headers: Http.RequestHeaders, body: Data?) -> ApeURLRequest {
        guard let url = URL(string: endpoint.absoluteUrl) else {
            preconditionFailure("Endpoint contains invalid url: '\(endpoint.absoluteUrl)'")
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.httpMethod.rawValue
        request.httpBody = body

        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }
        
        return ApeURLRequest(urlRequest: request, acceptedResponseCodes: endpoint.acceptedResponseCodes)
    }
}

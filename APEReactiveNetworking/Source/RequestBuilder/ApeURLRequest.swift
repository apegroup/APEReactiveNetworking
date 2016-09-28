//
//  ApeURLRequest.swift
//  APEReactiveNetworking
//
//  Created by Magnus Eriksson on 2016-09-27.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

public struct ApeURLRequest {
    
    let urlRequest: URLRequest
    let acceptedResponseCodes: [Http.StatusCode]
    
    /**
     Creates an ApeURLRequest
     - parameter urlRequest: The underlying request to be sent
     - parameter acceptedResponseCodes: The accepted http response codes for this request
     */
    init(urlRequest: URLRequest, acceptedResponseCodes: [Http.StatusCode]) {
        self.urlRequest = urlRequest
        self.acceptedResponseCodes = acceptedResponseCodes
    }
}

//
//  APERequestBuilderTests.swift
//  APEReactiveNetworking
//
//  Created by Magnus Eriksson on 2016-10-25.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import XCTest
import ReactiveSwift
@testable import APEReactiveNetworking


class APERequestBuilderTests: XCTestCase {
    
    let authHeaderKey = "Authorization"
    
    func testImplicitHeaders() {
        let request = ApeRequestBuilder(endpoint: GoogleEndpoint()).build()
        guard let headers = request.urlRequest.allHTTPHeaderFields else {
            return XCTFail("No headers available")
        }
        
        XCTAssertNotNil(headers["X-Client-Device-VendorId"])
        XCTAssertNotNil(headers["X-Client-Device-Type"])
        XCTAssertNotNil(headers["X-Client-OS"])
        XCTAssertNotNil(headers["X-Client-OS-Version"])
    }
    
    func testAuthHeaderCustom() {
        let token = "CustomToken: This is my custom token"
        let request = ApeRequestBuilder(endpoint: GoogleEndpoint())
            .setAuthorizationHeader(headerValue: token)
            .build()
        
        guard let headers = request.urlRequest.allHTTPHeaderFields else {
            return XCTFail("No headers available")
        }
        
        XCTAssertTrue(headers[authHeaderKey] == token)
    }

    
    func testAuthHeaderBasic() {
        let username = "ape"
        let password = "group"
        
        guard let request = try? ApeRequestBuilder(endpoint: GoogleEndpoint())
            .setAuthorizationHeader(username: username, password: password)
            .build() else {
                return XCTFail("Unable to build request")
        }
        guard let headers = request.urlRequest.allHTTPHeaderFields else {
            return XCTFail("No headers available")
        }
        
        let credentialsString = "\(username):\(password)"
        guard let credentialsData = credentialsString.data(using: .utf8) else {
            return XCTFail("Unable to serialize credentials")
        }
        
        let base64Credentials = credentialsData.base64EncodedString(options: [])
        XCTAssertTrue(headers[authHeaderKey] == "Basic \(base64Credentials)")
    }
    
    
    func testAuthHeaderBearer() {
        let token = "This is my bearer token"
        let request = ApeRequestBuilder(endpoint: GoogleEndpoint())
            .setAuthorizationHeader(token: token)
            .build()
        
        guard let headers = request.urlRequest.allHTTPHeaderFields else {
            return XCTFail("No headers available")
        }
        
        XCTAssertTrue(headers[authHeaderKey] == "Bearer \(token)")
    }
    
    func testCustomHeaders() {
        let key1 = "h1", key2 = "h2", key3 = "h3", key4 = "h4", key5 = "h5"
        let value1 = "v1", value2 = "v2.1, v2.2, v2.3", value3 = "v3", value4 = "v4", value5 = "v5"
        let request = ApeRequestBuilder(endpoint: GoogleEndpoint())
            //Test single header entry
            .setHeader((key1, value1))
            //Test single header entry with multiple values
            .setHeader((key2, value2.components(separatedBy: ",")))
            //Test several header entries
            .setHeaders([key3:value3, key4:value4, key5:value5])
            .build()
        
        guard let headers = request.urlRequest.allHTTPHeaderFields else {
            return XCTFail("No headers available")
        }
        
        XCTAssertTrue(headers[key1] == value1)
        XCTAssertTrue(headers[key2] == value2)
        XCTAssertTrue(headers[key3] == value3)
        XCTAssertTrue(headers[key4] == value4)
        XCTAssertTrue(headers[key5] == value5)
    }

    func testContentTypeApplicationJson() {
        let applicationJson = Http.ContentType.applicationJson(vendor: nil)
        XCTAssert(applicationJson.description == "application/json; charset=utf-8", "Unexpceted Content-Type value")
    }

    func testContentTypeApplicationJsonWithVendor() {
        let applicationJsonWithVendor = Http.ContentType.applicationJson(vendor: "vnd.apegroup.com")
        XCTAssert(applicationJsonWithVendor.description == "application/vnd.apegroup.com+json; charset=utf-8", "Unexpceted Content-Type value")
    }
}

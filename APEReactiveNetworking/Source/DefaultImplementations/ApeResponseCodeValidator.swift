//
//  ResponseCodeValidator.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-05-18.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

public struct ApeResponseCodeValidator : HttpResponseCodeValidator {

    public init() {}

    public  func isResponseCodeValid(responseCode: HttpStatusCode, httpMethod: HttpMethod) -> Bool {
        switch httpMethod {
        case .GET:
            return responseCode == .OK
        case .PUT:
            return responseCode == .OK || responseCode == .Created
        case .POST:
            return responseCode == .Created
        case .DELETE:
            return responseCode == .NoContent
        case .PATCH:
            return responseCode == .OK
        }

    }
}
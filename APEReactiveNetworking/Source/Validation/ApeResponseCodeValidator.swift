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

    /**
     Determines if the received response code is acceptable given the received http method
     
     - parameter responseCode: The http response code to validate
     - parameter httpMethod:   The associated http method
     
     - returns: true if the response code is within the 200-range, else false
     */
    public func isValid(responseCode: Http.StatusCode, forHttpMethod httpMethod: Http.Method) -> Bool {
        return (Http.StatusCode.ok.rawValue..<Http.StatusCode.multipleChoices.rawValue).contains(responseCode.rawValue)
    }
}

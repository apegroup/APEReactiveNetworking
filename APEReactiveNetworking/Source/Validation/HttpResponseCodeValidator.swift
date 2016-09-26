//
//  HttpResponseCodeValidator.swift
//  APEReactiveNetworking
//
//  Created by Dennis Korkchi on 07/06/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

public protocol HttpResponseCodeValidator {
    func isValid(responseCode: Http.StatusCode, forHttpMethod: Http.Method) -> Bool
}

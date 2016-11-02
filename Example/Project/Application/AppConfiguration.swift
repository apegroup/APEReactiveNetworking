//
//  AppConfiguration.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 05/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

struct AppConfiguration {
    
    static let environment: Environment = {
        
        var environment = Environment.production
        
        #if DEBUG
            environment = .debug
        #elseif PREVIEW
            environment = .preview
        #endif
        
//        print("Application is built with configuration: '\(environment)'")
        return environment
    }()
    
    
    static func isProductionBuild() -> Bool {
        return environment == .production
    }
}

/* Enum that represents the different environments, e.g. "baseUrl" etc
 * Possible to extend with additional environments and properties.
 */
enum Environment: String {
    case debug
    case preview
    case production
    
    private var urlProtocol: String {
        switch self {
        case .debug:            return "http://"
        case .preview:          return "https://"
        case .production:       return "https://"
        }
    }
    
    private var apiVersion: String {
        switch self {
        case .debug:            return "/v1"
        case .preview:          return "/v1"
        case .production:       return "/v1"
        }
    }
    
    var baseUrl: String {
        let baseUrl: String
        switch self {
        case .debug:            baseUrl = "104.199.21.38:8080" //deployed on google container engine
        default:                baseUrl = "private-05732-apechat.apiary-mock.com"
        }
        return urlProtocol + baseUrl + apiVersion
    }
}

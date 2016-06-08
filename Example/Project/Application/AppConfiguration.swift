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
        
        var environment = Environment.Production
        
        #if DEBUG
            environment = .Debug
        #elseif PREVIEW
            environment = .Preview
        #endif
        
        print("Application is built with configuration: '\(environment)'")
        return environment
    }()
    
    
    static func isProductionBuild() -> Bool {
        return environment == Environment.Production
    }
}

/* Enum that represents the different environments, e.g. "baseUrl" etc
 * Possible to extend with additional environments and properties.
 */
enum Environment: String {
    case Debug
    case Preview
    case Production
    
    private var urlProtocol: String {
        switch self {
        case Debug:            return "https://"
        case Preview:          return "https://"
        case Production:       return "https://"
        }
    }
    
    var baseUrl: String {
        switch self {
        case Debug:            return urlProtocol + "private-ea0bb-apechat.apiary-mock.com"
        case Preview:          return urlProtocol + "private-05732-apechat.apiary-mock.com"
        case Production:       return urlProtocol + "private-05732-apechat.apiary-mock.com"
        }
    }
}
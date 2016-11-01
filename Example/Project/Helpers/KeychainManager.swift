//
//  KeychainManager.swift
//  WebWrapper
//
//  Created by Magnus Eriksson on 30/01/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import Locksmith

struct KeychainManager {
    
    //MARK: - Keychain keys
    
    //Account key
    private static let keyAccount = "APEReactiveNetworkingAccountKey"
    
    //Dictionary keys
    private static let keyJwtToken = "AccountKeyJwtToken"
    
    //MARK: Public
    
    static func jwtToken() -> String? {
        return dataForKey(keyJwtToken)
    }
    
    static func save(jwtToken: String) -> Bool {
        return save(data: [keyJwtToken : jwtToken])
    }
    
    //MARK: - Private
    
    /**
     Attempts to save the received data to the keychain. Existing data is overwritten.
     
     - parameter data: The data to be saved
     - returns: true if the data was succesfully saved. Else false
     */
    private static func save(data: [String: Any]) -> Bool {
        do {
            try Locksmith.updateData(data: data, forUserAccount: keyAccount)
            debugPrint("Saved '\(data)' to keychain")
            return true
        } catch {
            debugPrint("Error: \(error): Failed to save '\(data)' to keychain")
            return false
        }
    }
    
    private static func dataForKey<T>(_ key: String) -> T? {
        let accountData = Locksmith.loadDataForUserAccount(userAccount: keyAccount)
        return accountData?[key] as? T
    }
}

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
    
    //MARK: Keychain keys
    
    //Account key
    private static let AccountKey = "AppArchitectureAccountKey"
    
    //Dictionary keys
    private static let KeyJwtToken = "AccountKeyJwtToken"
    
    //MARK: Public
    
    static func jwtToken() -> String? {
        return dataForKey(KeyJwtToken) as? String
    }
    
    static func saveJwtToken(token: String) -> Bool {
        return saveData([KeyJwtToken : token])
    }
    
    //MARK: Private
    
    /**
    Attempts to save the received data to the keychain. Existing data is overwritten.

    - parameter data: The data to be saved
    - returns: true if the data was succesfully saved. Else false
    */
    private static func saveData(data: [String: AnyObject]) -> Bool {
        do {
            try Locksmith.updateData(data, forUserAccount: AccountKey)
            debugPrint("Saved '\(data)' to keychain")
            return true
        }
        catch {
            debugPrint("Failed to save \(data) to keychain")
            return false
        }
    }
    
    private static func dataForKey(key: String) -> AnyObject? {
        return Locksmith.loadDataForUserAccount(AccountKey)?[key]
    }
    
    
    
    
    
}
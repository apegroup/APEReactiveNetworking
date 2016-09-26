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
    private static let AccountKey = "APEReactiveNetworkingAccountKey"
    
    //Dictionary keys
    private static let KeyJwtToken = "AccountKeyJwtToken"
    
    //MARK: Public
    
    static func jwtToken() -> String? {
        return dataForKey(KeyJwtToken) as? String
    }
    
    static func save(jwtToken: String) -> Bool {
        return save(data: [KeyJwtToken : jwtToken as AnyObject])
    }
    
    //MARK: Private
    
    /**
    Attempts to save the received data to the keychain. Existing data is overwritten.

    - parameter data: The data to be saved
    - returns: true if the data was succesfully saved. Else false
    */
    private static func save(data: [String: AnyObject]) -> Bool {
        do {
            try Locksmith.updateData(data: data, forUserAccount: AccountKey)
            debugPrint("Saved '\(data)' to keychain")
            return true
        }
        catch {
            debugPrint("Failed to save \(data) to keychain")
            return false
        }
    }
    
    private static func dataForKey(_ key: String) -> AnyObject? {
        return Locksmith.loadDataForUserAccount(userAccount: AccountKey)?[key] as AnyObject?
    }
}

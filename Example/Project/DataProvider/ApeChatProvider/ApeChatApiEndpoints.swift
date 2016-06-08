//
//  ApeChatApiEndpoints.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-05-06.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import APEReactiveNetworking

// Uses the ApeChat API : http://docs.apechat.apiary.io/#


enum ApeChatApiEndpoints : Endpoint {

    enum MessageStatus : String {
        case Read
        case UnRead
    }

    private enum Paths : String {
        case users = "/users/"
        case devices = "/devices/"
        case friends = "/friends/"
        case messages = "/messages/"
    }

    //User Resources
    case AuthUser
    case GetAllUsers
    case GetUser (userId: String)
    case UpdateUserAvatar (userId: String)
    case UpdateUser (userId: String)
    case DeleteUser (userId: String)

    //Device Resources
    case GetDevices (userId: String)
    case AddDevice (userId: String)
    case RemoveDevice (userId: String, vendorId: String)
    
    //Friend Resources
    case GetFriends (userId: String)
    case AddFriend (userId: String, friendId: String)
    case RemoveFriend (userId: String, friendId: String)
    
    //Message Resources
    case GetMessages (since: NSDate?, status: MessageStatus?, senderId: String?, receiverId: String?)
    case DeleteMessage (messageId: String)
    case SendMessage


    private var path: String {
        switch self {
        case AuthUser, GetAllUsers:
            return Paths.users.rawValue

        case let UpdateUserAvatar(userId):
            return Paths.users.rawValue + userId + "/avatar/"

        case let GetUser(userId):
            return Paths.users.rawValue + userId

        case let UpdateUser(userId):
            return Paths.users.rawValue + userId

        case let DeleteUser(userId):
            return Paths.users.rawValue + userId

        case let GetDevices(userId):
            return Paths.users.rawValue + userId + Paths.devices.rawValue
        
        case let AddDevice(userId):
            return Paths.users.rawValue + userId + Paths.devices.rawValue
        
        case let RemoveDevice(userId, vendorId):
            return Paths.users.rawValue + userId + Paths.devices.rawValue + vendorId

        case let GetFriends(userId):
            return Paths.users.rawValue + userId + Paths.friends.rawValue
            
        case let AddFriend(userId, friendId):
            return Paths.users.rawValue + userId + Paths.friends.rawValue + friendId
            
        case let RemoveFriend(userId, friendId):
            return Paths.users.rawValue + userId + Paths.friends.rawValue + friendId
            
        case let GetMessages(since, status, senderId, receiverId):
            return buildGetMessagePath(since, status: status, senderId: senderId, receiverId: receiverId)

        case let DeleteMessage(messageId):
            return Paths.messages.rawValue + messageId

        case SendMessage:
            return Paths.messages.rawValue
        }
    }

    var absoluteUrl: String {
        return AppConfiguration.environment.baseUrl + self.path
    }

    var httpMethod : HttpMethod {
        switch self {
        case AuthUser, UpdateUserAvatar, AddDevice, AddFriend, .SendMessage:
            return .POST

        case UpdateUser:
            return .PATCH

        case DeleteUser, DeleteMessage, RemoveDevice, RemoveFriend:
            return .DELETE

        default:
            return .GET
        }
    }
    
    private func buildGetMessagePath(since: NSDate?, status: MessageStatus?, senderId: String?, receiverId: String?) -> String {
        let params = [(paramName: "since", paramValue: since?.iso8601string()),
                      (paramName: "status", paramValue: status?.rawValue),
                      (paramName: "senderId", paramValue: senderId),
                      (paramName: "receiverId", paramValue: receiverId)]

        return buildQueryString(of: params)
    }

    private func buildQueryString(of params: [(paramName: String, paramValue: String?)]) -> String {
        return params
            .filter{ return $0.paramValue != nil }
            .reduce("") { (accumulator, elem) -> String in
                return accumulator + (accumulator.isEmpty ? "?" : "&") + elem.paramName + "=" + elem.paramValue!
        }
    }
    
}

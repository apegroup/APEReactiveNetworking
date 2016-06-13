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
        case messages = "/messages/"
    }

    //User Resources
    case AuthUser
    case GetAllUsers
    case UpdateUserAvatar (userId: String)

    //Message Resources
    case GetMessages (since: NSDate?, status: MessageStatus?, senderId: String?, receiverId: String?)
    case DeleteMessage (messageId: String)


    private var path: String {
        switch self {
        case AuthUser, GetAllUsers:
            return Paths.users.rawValue

        case let UpdateUserAvatar(userId):
            return Paths.users.rawValue + userId + "/avatar/"

        case let GetMessages(since, status, senderId, receiverId):
            return buildGetMessagesPath(since, status: status, senderId: senderId, receiverId: receiverId)

        case let DeleteMessage(messageId):
            return Paths.messages.rawValue + messageId

        }
    }

    var absoluteUrl: String {
        return AppConfiguration.environment.baseUrl + self.path
    }

    var httpMethod : HttpMethod {
        switch self {
        case AuthUser, UpdateUserAvatar:
            return .POST

        case DeleteMessage:
            return .DELETE

        default:
            return .GET
        }
    }
    
    private func buildGetMessagesPath(since: NSDate?, status: MessageStatus?, senderId: String?, receiverId: String?) -> String {
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

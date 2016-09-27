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
        case read
        case unread
    }

    private enum Paths : String {
        case users = "/users/"
        case messages = "/messages/"
    }

    //User Resources
    case authUser
    case getAllUsers
    case updateUserAvatar (userId: String)

    //Message Resources
    case getMessages (since: Date?, status: MessageStatus?, senderId: String?, receiverId: String?)
    case deleteMessage (messageId: String)


    private var path: String {
        switch self {
        case .authUser, .getAllUsers:
            return Paths.users.rawValue

        case let .updateUserAvatar(userId):
            return Paths.users.rawValue + userId + "/avatar/"

        case let .getMessages(since, status, senderId, receiverId):
            return buildGetMessagesPath(since: since, status: status, senderId: senderId, receiverId: receiverId)

        case let .deleteMessage(messageId):
            return Paths.messages.rawValue + messageId
        }
    }
    
    //MARK: - Endpoint conformance
    
    public var acceptedResponseCodes: [Http.StatusCode] {
        switch self {
        case .authUser:
            return [.created]
        case .deleteMessage:
            return [.noContent]
        default:
            return [.ok]
        }
    }

    var absoluteUrl: String {
        return AppConfiguration.environment.baseUrl + self.path
    }

    var httpMethod : Http.Method {
        switch self {
        case .authUser, .updateUserAvatar:
            return .post

        case .deleteMessage:
            return .delete

        default:
            return .get
        }
    }
    
    private func buildGetMessagesPath(since: Date?, status: MessageStatus?, senderId: String?, receiverId: String?) -> String {
        let params = [(paramName: "since", paramValue: since?.iso8601string()),
                      (paramName: "status", paramValue: status?.rawValue),
                      (paramName: "senderId", paramValue: senderId),
                      (paramName: "receiverId", paramValue: receiverId)]

        return buildQueryString(of: params)
    }

    private func buildQueryString(of params: [(paramName: String, paramValue: String?)]) -> String {
        return params
            .filter { $0.paramValue != nil }
            .reduce("") { (accumulator, elem) -> String in
                accumulator + (accumulator.isEmpty ? "?" : "&") + elem.paramName + "=" + elem.paramValue!
        }
    }
}

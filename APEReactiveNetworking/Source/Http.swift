//
//  HttpStatusCodes.swift
//  app-architecture
//
//  Created by Magnus Eriksson on 25/05/16.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation

public typealias HttpHeaders = [String: String]


public enum HttpMethod: String {
    case GET
    case PUT
    case POST
    case PATCH
    case DELETE

    init?(value: String?) {
        guard let value = value,
            resolved = HttpMethod(rawValue: value) else {
                return nil
        }
        self = resolved
    }
}


public enum HttpContentType {
    case ApplicationJson
    case TextPlain
    case ImageJpeg
    case ImagePng
}

extension HttpContentType : CustomStringConvertible {
    public var description : String {
        switch self {
        case ApplicationJson:
            return "application/json; charset=utf-8"
        case TextPlain:
            return "text/plain; charset=utf-8"
        case ImageJpeg:
            return "image/jpeg"
        case ImagePng:
            return "image/png"
        }
    }
}


//Thanks https://github.com/rhodgkins/SwiftHTTPStatusCodes/blob/master/HTTPStatusCodes.swift
public enum HttpStatusCode: Int {

    // Informational
    case Continue = 100
    case SwitchingProtocols = 101
    case Processing = 102

    // Success
    case OK = 200
    case Created = 201
    case Accepted = 202
    case NonAuthoritativeInformation = 203
    case NoContent = 204
    case ResetContent = 205
    case PartialContent = 206
    case MultiStatus = 207
    case AlreadyReported = 208
    case IMUsed = 226

    // Redirections
    case MultipleChoices = 300
    case MovedPermanently = 301
    case Found = 302
    case SeeOther = 303
    case NotModified = 304
    case UseProxy = 305
    case SwitchProxy = 306
    case TemporaryRedirect = 307
    case PermanentRedirect = 308

    // Client Errors
    case BadRequest = 400
    case Unauthorized = 401
    case PaymentRequired = 402
    case Forbidden = 403
    case NotFound = 404
    case MethodNotAllowed = 405
    case NotAcceptable = 406
    case ProxyAuthenticationRequired = 407
    case RequestTimeout = 408
    case Conflict = 409
    case Gone = 410
    case LengthRequired = 411
    case PreconditionFailed = 412
    case RequestEntityTooLarge = 413
    case RequestURITooLong = 414
    case UnsupportedMediaType = 415
    case RequestedRangeNotSatisfiable = 416
    case ExpectationFailed = 417
    case ImATeapot = 418
    case AuthenticationTimeout = 419
    case UnprocessableEntity = 422
    case Locked = 423
    case FailedDependency = 424
    case UpgradeRequired = 426
    case PreconditionRequired = 428
    case TooManyRequests = 429
    case RequestHeaderFieldsTooLarge = 431
    case LoginTimeout = 440
    case NoResponse = 444
    case RetryWith = 449
    case UnavailableForLegalReasons = 451
    case RequestHeaderTooLarge = 494
    case CertError = 495
    case NoCert = 496
    case HTTPToHTTPS = 497
    case TokenExpired = 498
    case ClientClosedRequest = 499

    // Server Errors
    case InternalServerError = 500
    case NotImplemented = 501
    case BadGateway = 502
    case ServiceUnavailable = 503
    case GatewayTimeout = 504
    case HTTPVersionNotSupported = 505
    case VariantAlsoNegotiates = 506
    case InsufficientStorage = 507
    case LoopDetected = 508
    case BandwidthLimitExceeded = 509
    case NotExtended = 510
    case NetworkAuthenticationRequired = 511
    case NetworkTimeoutError = 599

    case UnknownHttpStatusCode = 1000

    init(value: Int) {
        if let resolved = HttpStatusCode(rawValue: value) {
            self = resolved
        } else {
            self = .UnknownHttpStatusCode
        }
    }

}

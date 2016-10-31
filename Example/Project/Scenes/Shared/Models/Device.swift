//
//  Device.swift
//  app-architecture
//
//  Created by Tommy Malmström on 2016-05-31.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation
import Unbox
import Wrap

struct Device: Unboxable {
    let vendorIdentifier: String
    let deviceModel: String
    let pushToken: String
    let createdAt: Date
    let deviceName: String

    init(unboxer: Unboxer) throws {
        vendorIdentifier = try unboxer.unbox(key: "vendorIdentifier")
        deviceModel = try unboxer.unbox(key: "deviceModel")
        pushToken = try unboxer.unbox(key: "pushToken")
        createdAt = try unboxer.unbox(key: "createdAt", formatter: Date.iso8601DateFormatter)
        deviceName = try unboxer.unbox(key: "deviceName")
    }
}

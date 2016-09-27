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
        self.vendorIdentifier = try unboxer.unbox(key: "vendorIdentifier")
        self.deviceModel = try unboxer.unbox(key: "deviceModel")
        self.pushToken = try unboxer.unbox(key: "pushToken")
        self.createdAt = try unboxer.unbox(key: "createdAt", formatter: Date.iso8601DateFormatter)
        self.deviceName = try unboxer.unbox(key: "deviceName")
    }
}

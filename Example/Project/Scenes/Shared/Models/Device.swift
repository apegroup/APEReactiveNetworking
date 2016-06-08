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
    let createdAt: NSDate
    let deviceName: String

    init(unboxer: Unboxer) {
        self.vendorIdentifier = unboxer.unbox("vendorIdentifier")
        self.deviceModel = unboxer.unbox("deviceModel")
        self.pushToken = unboxer.unbox("pushToken")
        self.createdAt = unboxer.unbox("createdAt", formatter: NSDate.iso8601DateFormatter())
        self.deviceName = unboxer.unbox("deviceName")
    }
}

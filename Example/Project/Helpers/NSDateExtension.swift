//
//  NSDateExtension.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-05-23.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation


extension NSDate  {

    static func iso8601DateFormatter () -> NSDateFormatter {
        let dateFormatter = NSDateFormatter()
        let enUSPosixLocale = NSLocale(localeIdentifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }
    
    func iso8601string() -> String {
        return NSDate.iso8601DateFormatter().stringFromDate(self)
    }
}
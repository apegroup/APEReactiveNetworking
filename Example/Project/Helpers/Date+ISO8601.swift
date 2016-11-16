//
//  DateExtension.swift
//  app-architecture
//
//  Created by Dennis Korkchi on 2016-05-23.
//  Copyright © 2016 Apegroup. All rights reserved.
//

import Foundation


extension Date  {

    static var iso8601DateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        let enUSPosixLocale = Locale(identifier: "en_US_POSIX")
        dateFormatter.locale = enUSPosixLocale
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        return dateFormatter
    }
    
    func iso8601string() -> String {
        return Date.iso8601DateFormatter.string(from: self)
    }
}

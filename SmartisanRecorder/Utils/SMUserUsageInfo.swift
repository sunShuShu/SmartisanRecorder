//
//  SMUserUsageInfo.swift
//  SmartisanRecorder
//
//  Created by sunda on 26/08/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import Crashlytics

/// Each strategy of level is different. Logs print to console in all strategies when debugging, no printting when released.
///
/// - high: Serious, upload to Crashlytics.
/// - medium: Important, upload to Crashlytics with high level log, won't upload alone.
/// - low: Narmal, won't upload, just print to console.
enum LogLevel {
    case high, medium, low
}

func SMLog(_ content:String ,level:LogLevel = .low, file:String = #file, function:String = #function, line:Int = #line) {
    #if !DEBUG
    if level == .low {
        return
    }
    #endif
    guard content.count > 0 else {
        assertionFailure("Log content is empty!")
        return
    }
    let time = Date(timeIntervalSinceNow: 0)
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd HH:mm:ss.SSS"
    let timeString = dateFormatter.string(from: time)
    let fileName = URL(fileURLWithPath: file).lastPathComponent.replacingOccurrences(of: ".swift", with: "")
    let location = "\(timeString) \(fileName):\(line) \(function):"
    var logInfo = location
    switch level {
    case .low:
        logInfo += content
    case .medium:
        logInfo += "⚠️\(content)"
        CLSLogv(logInfo,getVaList([]))
    case .high:
        logInfo += "⛔️\(content)"
        let error = NSError(domain: file, code: line, userInfo: ["content":logInfo])
        Crashlytics.sharedInstance().recordError(error)
    }
    #if DEBUG
    print(logInfo)
    #endif
}

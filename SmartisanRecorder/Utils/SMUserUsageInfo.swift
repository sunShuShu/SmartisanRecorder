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
/// - fatal: Serious, upload to Crashlytics.
/// - error: Important, upload to Crashlytics with high level log, won't upload alone.
/// - info: Narmal, won't upload, just print to console.
enum LogLevel {
    case fatal, error, info
}

func SMLog(_ content:String, error:NSError? = nil, level:LogLevel = .info, file:String = #file, line:Int = #line, function:String = #function) {
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
    let cSet = CharacterSet(charactersIn: "/")
    let fileName = file.components(separatedBy: cSet).last
    let location = "\(timeString) \(fileName ?? file):\(line) \(function): "
    var logInfo = location
    
    switch level {
    case .info:
        logInfo += "☕️\(content)"
    case .error:
        logInfo += "⚠️\(content)"
        CLSLogv(logInfo,getVaList([]))
    case .fatal:
        logInfo += "⛔️\(content)"
        let recordError: Error
        if error != nil {
            var userInfo = error!.userInfo
            userInfo.updateValue(logInfo, forKey: "content")
            recordError = NSError(domain: error!.domain, code: error!.code, userInfo: userInfo)
        } else {
            recordError = NSError(domain: fileName ?? file, code: line, userInfo: ["content":logInfo])
        }
        #if DEBUG
            assert(false, logInfo)
        #endif
        Crashlytics.sharedInstance().recordError(recordError)
    }
    #if DEBUG
    print(logInfo)
    #endif
}

//
//  SMUtils.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/4.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation

class SMMeasure {
    typealias TimeReport = (
        minTime: TimeInterval,
        maxTime: TimeInterval,
        averageTime: TimeInterval,
        standardDeviation: TimeInterval)
    
    private lazy var timeArray = [TimeInterval]()
    private lazy var startDate = Date()
    
    func start() {
        startDate = Date()
    }
    
    @discardableResult func end(printLog: Bool = false) -> TimeInterval {
        let time = -startDate.timeIntervalSinceNow
        timeArray.append(time)
        if printLog {
            let log = String(format: "Measure time: %.3f ms", time * 1000)
            SMLog(log)
        }
        return time
    }
    
    @discardableResult func getReport(from object: AnyObject) -> TimeReport {
        guard timeArray.count > 0 else {
            return (0,0,0,0)
        }
        
        var maxTime: TimeInterval = 0
        var minTime: TimeInterval = Date().timeIntervalSince1970
        let sum = timeArray.reduce(0.0) {
            maxTime = max(maxTime, $1)
            minTime = min(minTime, $1)
            return $0 + $1
        }
        let averageTime = sum / Double(timeArray.count)
        let deviation = timeArray.reduce(0) {
            $0 + pow($1 - averageTime, 2)
        }
        let standardDeviation = sqrt(deviation / Double(timeArray.count))
        let report = (minTime, maxTime, averageTime, standardDeviation)
        
        let log = String(format: "\n\(object):\n------------------------------- Measure Report -------------------------------\n min: %.3f ms, max: %.3f ms, average: %.3f ms, standard deviation: %.3f ms\n", minTime * 1000, maxTime * 1000, averageTime * 1000, standardDeviation * 1000)
        SMLog(log)
        return report
    }
}

class SMTimeTool {
    private var lastString: (second: Int, string: String) = (Int.max, "")
    
    /// format: (01:)23:45(.59) (hour:)minite:second(.millisecond)
    ///
    /// - Parameters:
    ///   - time: Number of seconds
    ///   - isNeedHour: include hour
    ///   - isNeedHour: include millisecond
    /// - Returns: formatted string
    @inline(__always) func secondToString(time: SMTime, isNeedHour: Bool, isNeedMs: Bool) -> String {
        var leftTime = Int(time)
        var string = ""
        if lastString.second != leftTime {
            if isNeedHour {
                var hour = 0
                if leftTime >= 3600 {
                    hour = leftTime / 3600
                    leftTime %= 3600
                }
                string += String(format: "%02d:", hour)
            }
            
            let minute = leftTime / 60
            let second = leftTime % 60
            string += String(format: "%02d:%02d", minute, second)
            lastString = (Int(time), string)
        }
        
        if isNeedMs {
            let ms = Int(time * 100) % 100
            string += String(format: ".%02d:", ms)
        }
        return string
    }
    
    /// It's like 23:45.59 when time is greater than 1 hour, otherwise like 01:23:45
    ///
    /// - Parameter time: second
    /// - Returns: formatted string
    func secondToShortString(time: SMTime) -> String {
        let shouldShowHour = time >= 3600
        return self.secondToString(time: time, isNeedHour: shouldShowHour, isNeedMs: !shouldShowHour)
    }
}

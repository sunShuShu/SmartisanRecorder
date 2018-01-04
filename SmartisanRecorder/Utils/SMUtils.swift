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
    
    @discardableResult func end() -> TimeInterval {
        let time = -startDate.timeIntervalSinceNow
        timeArray.append(time)
        let log = String(format: "Measure time: %.3f ms", time * 1000)
        SMLog(log)
        return time
    }
    
    @discardableResult func getReport() -> TimeReport {
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
        
        let log = String(format: "\n\n------------------------------- Measure Report -------------------------------\n min: %.3f ms, max: %.3f ms, average: %.3f ms, standard deviation: %.3f ms\n", minTime * 1000, maxTime * 1000, averageTime * 1000, standardDeviation * 1000)
        SMLog(log)
        return report
    }
}

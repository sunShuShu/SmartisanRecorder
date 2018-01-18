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

class SMCache<Key: Hashable, Element: Hashable> {
    private let minCount: Int
    private let maxCount: Int
    private lazy var cache = [Key: Element]()
    private lazy var cache2 = [Key: Element]()
    
    init(minCount: Int, maxCount: Int) {
        if minCount > maxCount {
            assert(false, "Fail! minCount > maxCount!")
        }
        self.minCount = minCount
        self.maxCount = maxCount
    }
    
    subscript(key: Key) -> Element? {
        set {
            if let value = newValue {
                add(value, key: key)
            }
        }
        get {
            return get(key)
        }
    }
    
    func add(_ value: Element, key: Key) {
        if cache.count >= maxCount {
            if cache2.count >= minCount {
                cache = cache2
                cache2 = [Key: Element]()
                cache.updateValue(value, forKey: key)
            } else {
                cache2.updateValue(value, forKey: key)
            }
        } else {
            cache.updateValue(value, forKey: key)
        }
    }
    
    func get(_ key: Key) -> Element? {
        if let value = cache2[key] {
            return value
        }
        if let value = cache[key] {
            return value
        }
        return nil
    }
}

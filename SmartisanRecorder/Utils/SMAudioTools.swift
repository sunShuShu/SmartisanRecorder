//
//  SMAudioTools.swift
//  SmartisanRecorder
//
//  Created by sunda on 07/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation

struct SMAudioMeter {
    static let minDB: Float = -60.0
    static let dbResulution: Float = -0.2
    
    private let scaleFactor: Float
    private var meterTable = [Float]()
    private let resultRange: Float
    
    /// init
    ///
    /// - Parameter resultRange: range of linearLevel()'s return value is 0 ~ resultRange
    init(resultRange: Float) {
        self.resultRange = resultRange
        let tableSize: Int = Int(SMAudioMeter.minDB / SMAudioMeter.dbResulution + 1)
        scaleFactor = 1.0 / SMAudioMeter.dbResulution
        
        let minAmp = dbToAmp(db: SMAudioMeter.minDB)
        let ampRange = 1.0 - minAmp
        let invAmpRange = 1.0 / ampRange
        
        for index in 0..<tableSize {
            let decibels = Float(index) * SMAudioMeter.dbResulution
            let amp = dbToAmp(db: decibels)
            let adjAmp = (amp - minAmp) * invAmpRange
            let zoomedAmp = adjAmp * resultRange
            meterTable.append(zoomedAmp)
        }
    }
    
    func linearLevel(with power: Float) -> Float {
        if power < SMAudioMeter.minDB {
            return 0
        } else if power > 0 {
            return resultRange
            
        } else {
            let index = Int(power * scaleFactor)
            let level = meterTable[index]
            return level
        }
    }
    
    private func dbToAmp(db: Float) -> Float {
        return powf(10.0, 0.05 * db)
    }
}

//
//  SMWaveformModel.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/3/26.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation

class SMWaveformModel {
    private var dataArray = NSMutableArray()
    
    var count: Int {
        objc_sync_enter(self)
        let c = dataArray.count
        objc_sync_exit(self)
        return c
    }
    
    func add(_ element: UInt8) {
        let e = element as NSValue
        objc_sync_enter(self)
        dataArray.add(e)
        objc_sync_exit(self)
    }
    
    func set(_ array: NSMutableArray) {
        objc_sync_enter(self)
        dataArray = array
        objc_sync_exit(self)
    }
    
    func get(_ index: Int) -> UInt8? {
        objc_sync_enter(self)
        guard index >= 0 && dataArray.count > index else {
            return nil
        }
        let result = dataArray[index]
        objc_sync_exit(self)
        return result as? NSValue as? UInt8
    }
    
    func getLast() -> UInt8? {
        objc_sync_enter(self)
        let result = dataArray.lastObject
        objc_sync_exit(self)
        return result as? NSValue as? UInt8
    }
}

//
//  SMWaveformModel.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/3/26.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation

class SMWaveformModel {
    private var data = NSMutableData()
    
    init?(from filePath: String) {
        objc_sync_enter(self)
        let url = URL(fileURLWithPath: filePath)
        var tempData: NSMutableData?
        do {
            tempData = try NSMutableData.init(contentsOf: url)
        } catch {}
        if let data = tempData {
            self.data = data
            objc_sync_exit(self)
        } else {
            objc_sync_exit(self)
            return nil
        }
    }
    
    var count: Int {
        objc_sync_enter(self)
        let c = data.length
        objc_sync_exit(self)
        return c
    }
    
    func add(_ element: UInt8) {
        var e = element
        objc_sync_enter(self)
        data.append(withUnsafePointer(to: &e, {$0}), length: 1)
        objc_sync_exit(self)
    }
    
    func get(_ index: Int) -> UInt8? {
        objc_sync_enter(self)
        guard index >= 0 && data.length > index else {
            objc_sync_exit(self)
            return nil
        }
        let result = unsafeBitCast(data.bytes, to: UnsafePointer<UInt8>.self)
        let number = result.advanced(by: index).pointee
        objc_sync_exit(self)
        return number
    }
    
    func getLast() -> UInt8? {
        objc_sync_enter(self)
        guard data.length > 0 else {
            objc_sync_exit(self)
            return nil
        }
        let result = unsafeBitCast(data.bytes, to: UnsafePointer<UInt8>.self)
        let number = result.advanced(by: data.length - 1).pointee
        objc_sync_exit(self)
        return number
    }

}

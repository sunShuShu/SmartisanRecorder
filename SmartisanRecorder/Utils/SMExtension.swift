//
//  SMExtension.swift
//  SmartisanRecorder
//
//  Created by sunda on 07/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

extension Data {
    func subData(_ start:Int, _ length:Int) -> Data {
        let range:Range<Data.Index> = self.startIndex.advanced(by: start)..<self.startIndex.advanced(by: start + length)
        let subData = self.subdata(in: range)
        return subData
    }
    
    func toString() -> String? {
        return String(data: self, encoding: .utf8)
    }
    
    func toInt16(isBigEndian: Bool) -> Int16 {
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: MemoryLayout<Int16>.size)
        let range:Range<Data.Index> = self.startIndex..<self.endIndex.advanced(by: -1)
        self.copyBytes(to: bytes, from: range)
        if isBigEndian {
            return Int16(bytes.advanced(by: 1).pointee) + Int16(bytes.pointee) * 0x1_00
        } else {
            return Int16(bytes.pointee) + Int16(bytes.advanced(by: 1).pointee) * 0x1_00
        }
    }
    
    func toInt64(isBigEndian: Bool) -> Int64 {
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: MemoryLayout<Int64>.size)
        let range:Range<Data.Index> = self.startIndex..<self.endIndex.advanced(by: -1)
        self.copyBytes(to: bytes, from: range)
        if isBigEndian {
            return Int64(bytes.pointee) * 0x1_00_00_00 + Int64(bytes.advanced(by: 1).pointee) * 0x1_00_00 + Int64(bytes.advanced(by: 2).pointee) * 0x1_00 + Int64(bytes.advanced(by: 3).pointee)
        } else {
            return Int64(bytes.pointee) + Int64(bytes.advanced(by: 1).pointee) * 0x1_00 + Int64(bytes.advanced(by: 2).pointee) * 0x1_00_00 + Int64(bytes.advanced(by: 3).pointee) * 0x1_00_00_00
        }
    }
}

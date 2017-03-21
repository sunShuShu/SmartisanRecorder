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
        let result = String(data: self, encoding: .utf8)
        return result
    }
    
    func toInt32(isLittleEndian: Bool) -> Int32 {
        let size = MemoryLayout<Int32>.size
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        let range:Range<Data.Index> = self.startIndex..<self.endIndex.advanced(by: -1)
        self.copyBytes(to: bytes, from: range)
        var result: Int32 = 0
        for var index in 0..<size {
            if isLittleEndian {
                index = size - 1 - index
            }
            result *= 0x100
            let num = Int32(bytes.advanced(by: index).pointee)
            result += num
        }
        return result
    }
}

extension UInt32 {
    func toData() -> Data {
        let bytes = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        bytes.pointee = self
        let result = Data(bytes: bytes, count: MemoryLayout<UInt32>.size)
        return result
    }
}

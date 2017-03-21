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
    
    func toInt(_ bytesCount:Int, isLittleEndian: Bool) -> Int {
        let bytes = UnsafeMutablePointer<UInt8>.allocate(capacity: bytesCount)
        let range:Range<Data.Index> = self.startIndex..<self.endIndex.advanced(by: -1)
        self.copyBytes(to: bytes, from: range)
        var result = 0
        for var index in 0..<bytesCount {
            if isLittleEndian {
                index = bytesCount - 1 - index
            }
            result *= 0x100
            let num = Int(bytes.advanced(by: index).pointee)
            result += num
        }
        return result
    }

}

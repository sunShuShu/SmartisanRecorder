//
//  SMResample.swift
//  SmartisanRecorder
//
//  Created by sunda on 22/05/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation

class SMResample {
    
    //Currently only 16-bit PCM data is supported
    static func interpolate(_ times: Int, buffer: UnsafeMutablePointer<UInt8>, length: Int) -> UnsafeMutablePointer<UInt8> {
        let output = UnsafeMutablePointer<UInt8>.allocate(capacity: length * times)
        for i in stride(from: 0, to: length - 1, by: 2) {
            let high8Bits = buffer.advanced(by: i).pointee
            let low8Bits = buffer.advanced(by: i+1).pointee
            for j in stride(from: i*times, to: (i+2)*times-1, by: 2) {
                output.advanced(by: j).pointee = high8Bits
                output.advanced(by: j + 1).pointee = low8Bits
            }
        }
        return output
    }
    
    //Currently only 16-bit PCM data is supported
    static func degrade(_ times: Int, buffer: UnsafeMutablePointer<UInt8>, length: Int) -> UnsafeMutablePointer<UInt8> {
        let output = UnsafeMutablePointer<UInt8>.allocate(capacity: length * times)
        for i in stride(from: 0, to: length - 1, by: 2 * times) {
            let high8Bits = buffer.advanced(by: i).pointee
            let low8Bits = buffer.advanced(by: i+1).pointee
            output.advanced(by: i/times).pointee = high8Bits;
            output.advanced(by: i/times + 1).pointee = low8Bits;
        }
        return output
    }
}

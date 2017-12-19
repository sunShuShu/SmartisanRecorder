//
//  SMAudioInfoStorage.swift
//  SmartisanRecorder
//
//  Created by sunda on 2017/12/19.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

import Foundation

class SMAudioInfoStorage {
    private static let filePath = SMFileInfoStorage.filePath
    private let fileName: String
    
    /// The integer number will be saved with 1bit.
    let waveform = [NSInteger]()
    /// The integer number will be saved with 1bit.
    let point = [NSInteger]()
    
    init(audioFileName: String) {
        fileName = audioFileName
    }
    
    deinit {
        SMLog("\(type(of: self)) RELEASE! :\(self)")
    }
}

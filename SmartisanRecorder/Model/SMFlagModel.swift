//
//  SMFlagModel.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/4/8.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
class SMFlagModel {
    static let maxFlagCount = 99
    private static let fileDir = SMFileInfoStorage.filePath
    private static let flagSuffix = ".flag"
    
    private let filePath: String
    
    init?(fileName: String) {
        filePath = SMFlagModel.fileDir + "/\(fileName)" + SMFlagModel.flagSuffix
        let isFlagExists = FileManager.default.fileExists(atPath: filePath)
        if isFlagExists == false {
            try? FileManager.default.createDirectory(atPath: SMFlagModel.fileDir, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            self.locations = [SMTime]()
        } else {
            if let tempArray = NSArray(contentsOfFile: filePath) {
                self.locations = tempArray as! [SMTime]
            } else {
                SMLog("Flag modle read fail!", error: nil, level: .fatal)
                return nil
            }
        }
    }
    
    var locations: [SMTime] {
        didSet {
            guard locations.count > 0 && locations.count <= SMFlagModel.maxFlagCount else {
                locations = oldValue
                return
            }

            let result = (locations as NSArray).write(toFile: filePath, atomically: false)
            if result == false {
                locations = oldValue
                SMLog("Write flag failed!", level: .fatal)
            }
        }
    }
    
    func subRange(startTime: SMTime, endTime: SMTime) -> [(index: Int, time: SMTime)] {
        var subRange = [(Int, SMTime)]()
        for (index, time) in locations.enumerated() {
            if startTime < time && time < endTime {
                subRange.append((index, time))
            }
        }
        return subRange
    }
}

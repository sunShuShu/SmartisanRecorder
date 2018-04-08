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
            self.flagLocation = [TimeInterval]()
        } else {
            if let tempArray = NSArray(contentsOfFile: filePath) {
                self.flagLocation = tempArray as! [TimeInterval]
            } else {
                SMLog("Flag modle read fail!", error: nil, level: .high)
                return nil
            }
        }
    }
    
    var flagLocation: [TimeInterval] {
        didSet {
            guard flagLocation.count > 0 && flagLocation.count <= SMFlagModel.maxFlagCount else {
                flagLocation = oldValue
                return
            }

            let result = (flagLocation as NSArray).write(toFile: filePath, atomically: false)
            if result == false {
                flagLocation = oldValue
                SMLog("Write flag failed!", level: .high)
            }
        }
    }
}

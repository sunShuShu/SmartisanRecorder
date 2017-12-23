//
//  SMAudioInfoStorage.swift
//  SmartisanRecorder
//
//  Created by sunda on 2017/12/19.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

import Foundation

class SMAudioInfoStorage {
    private static let fileDir = SMFileInfoStorage.filePath
    private static let recordSuffix = SMRecorder.fileSuffix
    private static let waveformSuffix = ".waveform"
    private static let pointSuffix = ".point"
    /// When the waveform data is modified to a certain amount, save it to file
    private static let unsaveWaveformCount = SMRecorder.levelsPerSecond
    
    private let filePath: String //without suffix
    private let waveformWriteHandle: FileHandle?
    private var unsaveWaveform = 0
    
    /// After a certain number of added, the additional data will be saved automatically. (see SMAudioInfoStorage.unsaveWaveformCount).
    var waveform = [UInt8]() {
        didSet {
            unsaveWaveform += 1
            if unsaveWaveform >= SMAudioInfoStorage.unsaveWaveformCount {
                saveRestWaveform()
                unsaveWaveform = 0
            }
        }
    }
    
    var pointLocation = [UInt32]() {
        didSet {
            let pointFilePath = filePath + SMAudioInfoStorage.pointSuffix
            if (pointLocation as NSArray).write(toFile: pointFilePath, atomically: false) == false {
                pointLocation = oldValue
                SMLog("Write point failed!", level: .high)
            }
        }
    }
    
    init(audioFileName: String) {
        var audioFileName = audioFileName
        guard audioFileName.isEmpty == false else {
            assert(false)
            SMLog("File name is empty!", level: .high)
        }
        audioFileName.removeLast(SMAudioInfoStorage.recordSuffix.characters.count)
        filePath = SMAudioInfoStorage.fileDir + "/\(audioFileName)"
        
        //wareform
        let waveformFilePath = filePath + SMAudioInfoStorage.waveformSuffix
        let isWaveformExists = FileManager.default.fileExists(atPath: waveformFilePath)
        if isWaveformExists == false {
            //Going to start recording
            try? FileManager.default.createDirectory(atPath: SMAudioInfoStorage.fileDir, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: waveformFilePath, contents: nil, attributes: nil)
            waveformWriteHandle = FileHandle(forWritingAtPath: waveformFilePath)
            if waveformWriteHandle == nil {
                SMLog("Waveform file create faile!", level: .high)
            }
        } else {
            //Going to read wareform data
            waveformWriteHandle = nil
            if let readHandle = FileHandle(forReadingAtPath: waveformFilePath) {
                let tempData = readHandle.readDataToEndOfFile()
                self.waveform = [UInt8](tempData)
                readHandle.closeFile()
            } else {
                SMLog("Read waveform failed!", level: .high)
            }
        }
        
        //point
        let pointFilePath = filePath + SMAudioInfoStorage.pointSuffix
        let isPointExists = FileManager.default.fileExists(atPath: pointFilePath)
        if isPointExists == false {
            try? FileManager.default.createDirectory(atPath: SMAudioInfoStorage.fileDir, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: pointFilePath, contents: nil, attributes: nil)
        } else {
            if let tempArray = NSArray(contentsOfFile: pointFilePath) {
                if let pointsArray = tempArray as? [UInt32] {
                    pointLocation = pointsArray
                }
            }
        }
    }
    
    deinit {
        self.saveRestWaveform()
        if let writeHandle = waveformWriteHandle {
            writeHandle.closeFile()
        }
        SMLog("\(type(of: self)) RELEASE!")
    }
    
    /// Usually, no manual invocation is required, and the rest data is automatically saved before the object is released.
    func saveRestWaveform() {
        if waveformWriteHandle != nil && unsaveWaveform > 0 {
            let subArray = waveform[(waveform.count - unsaveWaveform)..<waveform.count]
            let tempData = Data(bytes: subArray)
            waveformWriteHandle!.write(tempData)
        }
    }
    
    //Save the entire file manually after editing the audio file.
    func saveEneireWaveform() {
        if let writeHandle = FileHandle(forWritingAtPath: filePath + SMAudioInfoStorage.waveformSuffix) {
            let tempData = Data(bytes: waveform)
            writeHandle.seekToEndOfFile()
            writeHandle.truncateFile(atOffset: 0)
            writeHandle.write(tempData)
            writeHandle.closeFile()
        } else {
            SMLog("Write eneire waveform failed!", level: .high)
        }
    }
    
    func deleteFile() {
        try? FileManager.default.removeItem(atPath: filePath + SMAudioInfoStorage.waveformSuffix)
        try? FileManager.default.removeItem(atPath: filePath + SMAudioInfoStorage.pointSuffix)
    }
}

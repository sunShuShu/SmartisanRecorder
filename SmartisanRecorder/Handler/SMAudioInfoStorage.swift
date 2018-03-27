//
//  SMAudioInfoStorage.swift
//  SmartisanRecorder
//
//  Created by sunda on 2017/12/19.
//  Copyright © 2017年 sunShuShu. All rights reserved.
//

import Foundation

class SMAudioInfoStorage {
    static let maxFlagCount = 99
    private static let fileDir = SMFileInfoStorage.filePath
    private static let recordSuffix = SMRecorder.fileSuffix
    private static let waveformSuffix = ".waveform"
    private static let flagSuffix = ".flag"
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
    
    var flagLocation = [UInt32]() {
        didSet {
            var isAllowModify = true
            defer {
                if isAllowModify == false {
                    flagLocation = oldValue
                    SMLog("Write flag failed!", level: .high)
                }
            }
            guard flagLocation.count <= SMAudioInfoStorage.maxFlagCount else {
                isAllowModify = false
                return
            }
            let flagFilePath = filePath + SMAudioInfoStorage.flagSuffix
            isAllowModify = (flagLocation as NSArray).write(toFile: flagFilePath, atomically: false)
        }
    }
    
    init?(audioFileName: String) {
        var audioFileName = audioFileName
        guard audioFileName.isEmpty == false else {
            assert(false)
            SMLog("File name is empty!", level: .high)
            return nil
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
        
        //flag
        let flagFilePath = filePath + SMAudioInfoStorage.flagSuffix
        let isFlagExists = FileManager.default.fileExists(atPath: flagFilePath)
        if isFlagExists == false {
            try? FileManager.default.createDirectory(atPath: SMAudioInfoStorage.fileDir, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: flagFilePath, contents: nil, attributes: nil)
        } else {
            if let tempArray = NSArray(contentsOfFile: flagFilePath) {
                if let flagsArray = tempArray as? [UInt32] {
                    flagLocation = flagsArray
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
        try? FileManager.default.removeItem(atPath: filePath + SMAudioInfoStorage.flagSuffix)
    }
}

//
//  SMWaveformModel.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/3/26.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation

class SMWaveformModel {
    private static let fileDir = SMFileInfoStorage.filePath
    private static let waveformSuffix = ".waveform"
    /// When the waveform data is added to a certain amount, save it to file
    private static let unsaveWaveformCount = SMRecorder.levelsPerSecond
    
    private let filePath: String
    private var waveformWriteHandle: FileHandle?
    private var unsaveWaveform = 0
    private var data = NSMutableData()
    
    init?(fileName: String) {
        filePath = SMWaveformModel.fileDir + "/\(fileName)" + SMWaveformModel.waveformSuffix
        let isWaveformExists = FileManager.default.fileExists(atPath: filePath)
        if isWaveformExists == false {
            //Going to start recording
            try? FileManager.default.createDirectory(atPath: SMWaveformModel.fileDir, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
            waveformWriteHandle = FileHandle(forWritingAtPath: filePath)
            if waveformWriteHandle == nil {
                SMLog("Waveform file create faile!", level: .high)
                return nil
            }
        } else {
            //Going to read wareform data
            waveformWriteHandle = nil
            if let data = NSMutableData(contentsOfFile: filePath) {
                self.data = data
            } else {
                SMLog("Read waveform failed!", level: .high)
                return nil
            }
        }
    }
    
    var count: Int {
        objc_sync_enter(self)
        let c = data.length
        objc_sync_exit(self)
        return c
    }
    
    /// After a certain number of added, the additional data will be saved automatically. (see SMAudioInfoStorage.unsaveWaveformCount).
    func add(_ element: UInt8) {
        var e = element
        objc_sync_enter(self)
        data.append(withUnsafePointer(to: &e, {$0}), length: 1)
        objc_sync_exit(self)
        unsaveWaveform += 1
        if unsaveWaveform >= SMWaveformModel.unsaveWaveformCount {
            saveRestWaveform()
            unsaveWaveform = 0
        }
    }
    
    func get(_ index: Int) -> UInt8? {
        objc_sync_enter(self)
        guard index >= 0 && data.length > index else {
            objc_sync_exit(self)
            return nil
        }
        let result = data.bytes.assumingMemoryBound(to: UInt8.self)
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
        let result = data.bytes.assumingMemoryBound(to: UInt8.self)
        let number = result.advanced(by: data.length - 1).pointee
        objc_sync_exit(self)
        return number
    }
    
    /// Usually, no manual invocation is required, and the rest data is automatically saved before the object is released.
    func saveRestWaveform() {
        if waveformWriteHandle != nil && unsaveWaveform > 0 {
            let subData = data.subdata(with: NSMakeRange(data.length - unsaveWaveform, unsaveWaveform))
            waveformWriteHandle!.write(subData)
        } else if waveformWriteHandle == nil {
            SMLog("waveformWriteHandle is nil!", error: nil, level: .high)
        }
    }
    
    /// Save the entire file manually after editing the audio file.
    func createPartialWaveformFile(name: String, range: NSRange) -> Bool {
        let filePath = SMWaveformModel.fileDir + "/\(name)" + SMWaveformModel.waveformSuffix
        try? FileManager.default.createDirectory(atPath: SMWaveformModel.fileDir, withIntermediateDirectories: true, attributes: nil)
        FileManager.default.createFile(atPath: filePath, contents: nil, attributes: nil)
        let subData = data.subdata(with: range)
        do {
            try subData.write(to: URL(fileURLWithPath: filePath))
        } catch {
            SMLog("Write eneire waveform failed!", level: .high)
            return false
        }
        return true
    }
    
    deinit {
        self.saveRestWaveform()
        if let writeHandle = waveformWriteHandle {
            writeHandle.closeFile()
            waveformWriteHandle = nil
        }
        SMLog("\(type(of: self)) RELEASE!")
    }

}

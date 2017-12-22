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
            //TODO: save points
        }
    }
    
    init(audioFileName: String) {
        var audioFileName = audioFileName
        guard audioFileName.isEmpty == false else {
            SMLog("File name is empty!", level: .high)
            assert(false)
        }
        audioFileName.removeLast(SMAudioInfoStorage.recordSuffix.characters.count)
        filePath = SMAudioInfoStorage.fileDir + "/\(audioFileName)"
        
        let waveformFilePath = filePath + SMAudioInfoStorage.waveformSuffix
        let isWaveformExists = FileManager.default.fileExists(atPath: waveformFilePath)
        if isWaveformExists == false {
            try? FileManager.default.createDirectory(atPath: SMAudioInfoStorage.fileDir, withIntermediateDirectories: true, attributes: nil)
            FileManager.default.createFile(atPath: waveformFilePath, contents: nil, attributes: nil)
            waveformWriteHandle = FileHandle(forWritingAtPath: waveformFilePath)
            if waveformWriteHandle == nil {
                SMLog("Waveform file create faile!", level: .high)
            }
        } else {
            waveformWriteHandle = nil
            if let readHandle = FileHandle(forReadingAtPath: waveformFilePath) {
                let tempData = readHandle.readDataToEndOfFile()
                self.waveform = [UInt8](tempData)
            }
        }
    }
    
    deinit {
        self.saveWaveform()
//        if let writeHandle = self.waveformWriteHandle { {
//            writeHandle.close()
//        }
        SMLog("\(type(of: self)) RELEASE!")
    }
    
    private func saveRestWaveform() {
        if let writeHandle = self.waveformWriteHandle {
            let subArray = waveform[(waveform.count - unsaveWaveform)..<waveform.count]
            let tempData = Data(bytes: subArray)
            writeHandle.write(tempData)
        }
    }
    
    //Save the entire file at once. usually, no manual invocation is required, and the entire file is automatically saved before the object is released.
    func saveWaveform() {
        if self.unsaveWaveform > 0 {
            self.saveRestWaveform()
        }
    }
    
    func deleteFile() {
        try? FileManager.default.removeItem(atPath: filePath + SMAudioInfoStorage.waveformSuffix)
        try? FileManager.default.removeItem(atPath: filePath + SMAudioInfoStorage.pointSuffix)
    }
}

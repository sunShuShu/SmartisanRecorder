//
//  SMAudioFileEditor.swift
//  SmartisanRecorder
//
//  Created by sunda on 13/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import AVFoundation

class SMAudioFileEditor:NSObject, StreamDelegate {
    //MARK:- Type define
    typealias CompletionBlock = (Bool, EditError?) -> ()
    
    enum EditError: Error {
        case storageFull, fileDamaged, fileSizeExceedLimit
    }
    
    private struct InputFile {
        static let fragmentLength = 1024 * 100
        static var maxSampleRate = 8_000
        let url: URL
        var sampleRate = 8_000
        var sampleRateTimes = 1 //times of interpolation data and the original data
        init(url: URL) {
            self.url = url
        }
    }
    
    private struct OutputFile {
        let url: URL
        let stream: OutputStream
        let sampleRate: Int? = nil
        init?(url: URL) {
            self.url = url
            if let oStream = OutputStream(url: url, append: false) {
                self.stream = oStream
            } else {
                return nil
            }
        }
    }
    
    //MARK:-
    private let readQueue  = DispatchQueue(label: "com.sunshushu.merge-read" ,
                                           qos: DispatchQoS.userInitiated)
    private let writeQueue = DispatchQueue(label: "com.sunshushu.merge-write",
                                           qos: DispatchQoS.userInitiated)
    private let readSemaphore = DispatchSemaphore(value: 1)
    private let writeSemaphore = DispatchSemaphore(value: 0)
    
//    private let maxBufferSize = 10
//    private let minBufferSize = 5
    private var fragmentData = Data()
    private var inputFiles = [InputFile]()
    private let outputFile: OutputFile
    private var processingStream: InputStream?
    private let completion: CompletionBlock
    
    //MARK:- Mothod
    init?(inputURLs: [URL], outputURL: URL, completion: @escaping CompletionBlock) {
        guard inputURLs.isEmpty == false else {
            return nil
        }
        guard let oFile = OutputFile(url: outputURL) else {
            return nil
        }
        self.outputFile = oFile
        for url in inputURLs {
            self.inputFiles.append(InputFile(url: url))
        }
        self.completion = completion
        super.init()
    }
    
    
    /// Check wave header, record max sample rate in all files, check storage space.
    private func checkAllFiles() {
        for index in 0..<inputFiles.count {
            let result = SMWaveHeaderTool.check(file: inputFiles[index].url)
            if result.isValid == false {
                encounterError()
                return
            }
            inputFiles[index].sampleRate = result.sampleRate
            InputFile.maxSampleRate = max(InputFile.maxSampleRate, result.sampleRate)
        }
        
        var outputFileSize = 0
        for index in 0..<inputFiles.count {
            let info: [FileAttributeKey:Any]
            inputFiles[index].sampleRateTimes = InputFile.maxSampleRate / inputFiles[index].sampleRate
            do {
                try info = FileManager.default.attributesOfItem(atPath: inputFiles[index].url.path)
            } catch {
                encounterError()
                return
            }
            if let size = (info[FileAttributeKey.size] as? Int) {
                outputFileSize += size * inputFiles[index].sampleRateTimes
            }
        }
        //The size of WAVE file can NOT greate than 4G
        if outputFileSize >= 4 * 1024 * 1024 * 1024 {
            encounterError(SMAudioFileEditor.EditError.fileSizeExceedLimit)
            return
        }
        
        let info: [FileAttributeKey:Any]
        do {
            try info = FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        } catch {
            encounterError()
            return
        }
        let freeSize = info[FileAttributeKey.systemFreeSize] as! Int
        //If device free space less than 50M after merge all files
        if outputFileSize > freeSize - 50 * 1024 * 1024 {
            encounterError(SMAudioFileEditor.EditError.storageFull)
            return
        }
    }
    
    func merge() {
        //TODO: Cheak memory leaks
        self.checkAllFiles()
        
        writeQueue.async {

            //write wave header placeholder
            self.outputFile.stream.open()
            let headerLength = SMWaveHeaderTool.waveHeader.count
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerLength)
            SMWaveHeaderTool.waveHeader.copyBytes(to: buffer, count: headerLength)
            while self.outputFile.stream.hasSpaceAvailable == false {
                if self.outputFile.stream.streamStatus == .error {
                    self.encounterError()
                    return
                }
            }
            let writeLength = self.outputFile.stream.write(buffer, maxLength: headerLength)
            buffer.deallocate(capacity: headerLength)
            if writeLength != headerLength {
                self.encounterError()
                return
            }
            
            //setup output
            self.outputFile.stream.delegate = self
            self.outputFile.stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
            RunLoop.current.run()
        }
        
        readQueue.async {
            self.readNextInput()
            RunLoop.current.run()
        }
    }
    
    private func readNextInput() {
        //TODO: move to method of release resource
        if processingStream != nil {
            processingStream!.close()
            processingStream!.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
            processingStream = nil
            if inputFiles.isEmpty == false {
                inputFiles.removeFirst()
            }
        }
        
        if let iFile = self.inputFiles.first {
            processingStream = InputStream(url: iFile.url)
            if processingStream != nil {
                processingStream!.delegate = self
                processingStream!.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
                processingStream!.open()
                //skip wave header
                let headerLength = SMWaveHeaderTool.waveHeader.count
                let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerLength)
                let readLength = processingStream!.read(tempBuffer, maxLength: headerLength)
                tempBuffer.deallocate(capacity: headerLength)
                if readLength != headerLength {
                    self.encounterError()
                    return
                }
            } else {
                self.encounterError()
                return
            }
        } else {
            //All input files is done, write a empty data to end output stream.
            writeSemaphore.signal()
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            read()
        case Stream.Event.hasSpaceAvailable:
            write()
        case Stream.Event.errorOccurred:
            self.encounterError()
        case Stream.Event.endEncountered:
            if aStream is OutputStream {
                let result = SMWaveHeaderTool.setHeaderInfo(file: outputFile.url, sampleRate: InputFile.maxSampleRate)
                if result {
                    //TODO: release resource
                    completion(true, nil)
                } else {
                    encounterError()
                }
            } else {
                readNextInput()
            }
        default: break
        }
    }
    
    func read() {
        if self.processingStream != nil {
            var tempBufferLength = InputFile.fragmentLength
            var tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: tempBufferLength)
            var readLength = self.processingStream!.read(tempBuffer, maxLength: tempBufferLength)
            if readLength <= 0 {
                tempBuffer.deallocate(capacity: tempBufferLength)
                return
            }
            
            let times = inputFiles.first!.sampleRateTimes
            if times > 1 {
                let resultBuffer = SMResample.interpolate(times, buffer: tempBuffer, length: readLength)
                tempBuffer.deallocate(capacity: tempBufferLength)
                readLength *= times
                tempBuffer = resultBuffer
                tempBufferLength = readLength
            }
            
            readSemaphore.wait()
            fragmentData.append(tempBuffer, count: readLength)
            writeSemaphore.signal()
            tempBuffer.deallocate(capacity: tempBufferLength)
        }
    }
    
    func write() {
        var tempBuffer: UnsafeMutablePointer<UInt8>?
        var size = 0
        
        writeSemaphore.wait()
        size = fragmentData.count
        tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
        fragmentData.copyBytes(to: tempBuffer!, count: size)
        fragmentData.removeAll()
        readSemaphore.signal()
        
        self.outputFile.stream.write(tempBuffer!, maxLength: size)
        tempBuffer?.deallocate(capacity: size)
    }
    
    private func encounterError(_ error: EditError = .fileDamaged) {
        //TODO: Delete temp output file on disk. read/write thread etc.
        
        completion(false, error)
    }
    
}

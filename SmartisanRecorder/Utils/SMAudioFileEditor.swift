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
        static let fragmentLength = 6 * 1024 * 100
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
    private var startTrimLocation = 0 //start offset location, bytes
    private var endTrimLocation = Int.max //end offset location, bytes
    private var processingStream: InputStream?
    private let completion: CompletionBlock
    
    //MARK:- Public
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
    
    deinit {
        print("\(self) release")
    }
    
    /// Merge some input wave file in one
    func merge() {
        guard checkAllFiles() else {
            encounterError()
            return
        }
        let outputFileSize = setSampleRateTimesAndGetFileSize(sampleRate: InputFile.maxSampleRate)?.outputSize
        guard outputFileSize != nil else {
            encounterError()
            return
        }
        SMLog("Merged file size: \(outputFileSize!)")
        guard checkStorage(fileSize: outputFileSize!) else {
            encounterError()
            return
        }

        writeQueue.async {
            self.setupOutput()
            RunLoop.current.run()
        }
        readQueue.async {
            self.readNextInput()
            RunLoop.current.run()
        }
    }
    
    /// Trim ONE input wave file
    ///
    /// - Parameters:
    ///   - start: start position
    ///   - end: end position
    ///   - sampleRate: smaple rate of output file
    func trim(start:TimeInterval, end:TimeInterval, sampleRate:Int) {
        guard checkAllFiles() else {
            encounterError()
            return
        }
        guard inputFiles.count == 1 else {
            SMLog("Trimmed inputFiles array count is NOT 1!", level: .high)
            encounterError()
            return
        }
        let headerData = SMWaveHeaderTool.getHeaderData(inputFiles[0].url)
        let audioDataSize = headerData?.getAudioDataSize2FromWaveHeader()
        let audioBps = headerData?.getBPSFromWaveHeader()
        let fileTotleTime = TimeInterval(audioDataSize!) / TimeInterval(audioBps!)
        guard start < end && end <= fileTotleTime else {
            encounterError()
            return
        }
        let fileSize = setSampleRateTimesAndGetFileSize(sampleRate: sampleRate)
        guard fileSize != nil else {
            encounterError()
            return
        }
        var outputFileSize = fileSize!.outputSize
        outputFileSize = Int(Double(outputFileSize) * ((end - start) / fileTotleTime))
        SMLog("Trimmed file size: \(outputFileSize)")
        guard checkStorage(fileSize: outputFileSize) else {
            encounterError()
            return
        }
        
        self.startTrimLocation = Int(start * Double(fileSize!.inputSize) / fileTotleTime)
        self.endTrimLocation = Int(end * Double(fileSize!.inputSize) / fileTotleTime)
        writeQueue.async {
            self.setupOutput()
            RunLoop.current.run()
        }
        readQueue.async {
            self.readNextInput()
            RunLoop.current.run()
        }
    }
    
    //MARK:- Private
    /// Check wave header, record max sample rate in all files.
    private func checkAllFiles() -> Bool {
        for index in 0..<inputFiles.count {
            let result = SMWaveHeaderTool.check(file: inputFiles[index].url)
            if result.isValid == false {
                encounterError()
                return false
            }
            inputFiles[index].sampleRate = result.sampleRate
            InputFile.maxSampleRate = max(InputFile.maxSampleRate, result.sampleRate)
        }
        return true
    }
    
    /// check file size and available storage
    ///
    /// - Parameter fileSize: output file size
    /// - Returns: check result
    private func checkStorage(fileSize: Int) -> Bool {
        //The size of WAVE file can NOT greate than 4G
        if fileSize >= 0xFFFF_F000 {
            encounterError(SMAudioFileEditor.EditError.fileSizeExceedLimit)
            return false
        }
        
        let info: [FileAttributeKey:Any]
        do {
            try info = FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        } catch {
            encounterError()
            return false
        }
        let freeSize = info[FileAttributeKey.systemFreeSize] as! Int
        //If device free space less than 10M after merge all files
        if fileSize > freeSize - 10 * 1024 * 1024 {
            encounterError(SMAudioFileEditor.EditError.storageFull)
            return false
        }
        return true
    }
    
    private func setSampleRateTimesAndGetFileSize(sampleRate: Int) -> (inputSize:Int, outputSize:Int)? {
        var inputFileSize = 0
        var outputFileSize = 0
        for index in 0..<inputFiles.count {
            var info: [FileAttributeKey:Any]
            if sampleRate < inputFiles[index].sampleRate {
                inputFiles[index].sampleRateTimes = -(inputFiles[index].sampleRate / sampleRate)
            } else {
                inputFiles[index].sampleRateTimes = sampleRate / inputFiles[index].sampleRate
            }
            do {
                try info = FileManager.default.attributesOfItem(atPath: inputFiles[index].url.path)
            } catch {
                encounterError()
                return nil
            }
            if let size = (info[FileAttributeKey.size] as? Int) {
                inputFileSize = size
                if inputFiles[index].sampleRateTimes < 0 {
                    outputFileSize += size / inputFiles[index].sampleRateTimes
                } else {
                    outputFileSize += size * inputFiles[index].sampleRateTimes
                }
            } else {
                SMLog("File size attribute can NOT be read", level: .high)
                return nil
            }
        }
        return (inputFileSize, outputFileSize)
    }
    
    private func setupOutput() {
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
        
        //setup output stream
        self.outputFile.stream.delegate = self
        self.outputFile.stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
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
                //skip wave header and trimmed data
                let headerLength = SMWaveHeaderTool.waveHeader.count
                let result = processingStream?.setProperty(headerLength + startTrimLocation, forKey: Stream.PropertyKey.fileCurrentOffsetKey)
                if result == false {
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
                    self.outputFile.stream.close()
                    self.outputFile.stream.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
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
            var readyToReadLength = InputFile.fragmentLength
            let currentOffset = self.processingStream!.property(forKey: Stream.PropertyKey.fileCurrentOffsetKey) as! Int
            if currentOffset + readyToReadLength > endTrimLocation {
                readyToReadLength = endTrimLocation - currentOffset
            }
            let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: readyToReadLength)
            let readLength = self.processingStream!.read(tempBuffer, maxLength: readyToReadLength)
            if readLength <= 0 {
                tempBuffer.deallocate(capacity: readyToReadLength)
                return
            }
            
            //resample
            let resultBuffer: (buffer:UnsafeMutablePointer<UInt8>, length:Int)
            let times = inputFiles.first!.sampleRateTimes
            if times != 1 {
                resultBuffer = SMResample.resample(times, buffer: tempBuffer, length: readLength)
                tempBuffer.deallocate(capacity: readyToReadLength)
            } else {
                resultBuffer = (tempBuffer, readLength)
            }
            
            readSemaphore.wait()
            fragmentData.append(resultBuffer.buffer, count: resultBuffer.length)
            writeSemaphore.signal()
            resultBuffer.buffer.deallocate(capacity: resultBuffer.length)
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

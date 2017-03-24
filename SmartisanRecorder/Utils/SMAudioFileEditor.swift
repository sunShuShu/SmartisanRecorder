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
        case storageFull, fileDamaged
    }
    
    private struct InputFile {
        static let fragmentLength = 1024
        static let supportedBitWidth = 16
        static var maxSampleRate: Int?
        let url: URL
        var sampleRate: Int?
        init(url: URL) {
            self.url = url
        }
    }
    
    private struct OutputFile {
        let url: URL
        let stream: OutputStream
        let bitWidth = InputFile.supportedBitWidth
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
    
    //MARK:- Property
    private static let waveHeader = Data(bytes: [0x52,0x49,0x46,0x46, //RIFF
                                                 0x00,0x00,0x00,0x00, //size(placeholder)
                                                 0x57,0x41,0x56,0x45, //WAVE
                                                 0x66,0x6D,0x74,0x20, //fmt
                                                 0x10,0x00,0x00,0x00, //
                                                 0x01,0x00,           //1(pcm)
                                                 0x01,0x00,           //1(mono)
                                                 0x00,0x00,0x00,0x00, //sample rate(placeholder)
                                                 0x00,0x00,0x00,0x00, //bytes per second(placeholder)
                                                 0x02,0x00,           //2(block align)
                                                 0x10,0x00,           //16(bits per sample)
                                                 0x64,0x61,0x74,0x61, //data
                                                 0x00,0x00,0x00,0x00  //size(placeholder)
                                                 ])
    private static let waveSize1Range = 0x04...0x07
    private static let waveSampleRateRange = 0x18...0x1B
    private static let waveBPSRange = 0x1C...0x1F
    private static let waveSize2Range = 0x28...0x2B
    
//    private let queue = DispatchQueue(label: "com.sunshushu.wave-merge",
//                                      qos: .userInitiated,
//                                      attributes: DispatchQueue.Attributes.concurrent)
    private let readQueue  = DispatchQueue(label: "com.sunshushu.merge-read")
    private let writeQueue = DispatchQueue(label: "com.sunshushu.merge-write")
    private let readSemaphore = DispatchSemaphore(value: 1)
    private let writeSemaphore = DispatchSemaphore(value: 0)
    
    private let maxBufferSize = 10
    private let minBufferSize = 5
    //private var reading = false
    //private var writing = false
    //private var buffer = [Data]()
    private var fragmentData = Data()
    private var inputFiles: [InputFile]
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
        self.inputFiles = [InputFile]()
        for url in inputURLs {
            self.inputFiles.append(InputFile(url: url))
        }
        self.completion = completion
        super.init()
    }
    
    func merge() {
        //TODO: check storage
        //TODO: Cheak memory leaks
        self.checkAllFiles()
        
        //setup output
        writeQueue.async {
            self.outputFile.stream.open()
            let headerLength = SMAudioFileEditor.waveHeader.count
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerLength)
            SMAudioFileEditor.waveHeader.copyBytes(to: buffer, count: headerLength)
            while self.outputFile.stream.hasSpaceAvailable == false {
                if self.outputFile.stream.streamStatus == .error {
                    self.releaseResurce()
                }
            }
            let writeLength = self.outputFile.stream.write(buffer, maxLength: headerLength)
            if writeLength != headerLength {
                self.releaseResurce()
            }
            self.outputFile.stream.delegate = self
            self.outputFile.stream.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
            RunLoop.current.run()
        }
        
        readQueue.async {
            self.readNextInput()
        }

//        queue.async {
//            
//            self.checkAllFiles()
//            
//            //setup output
//            self.outputFile.stream.open()
//            let headerLength = SMAudioFileEditor.waveHeader.count
//            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerLength)
//            SMAudioFileEditor.waveHeader.copyBytes(to: buffer, count: headerLength)
//            let writeLength = self.outputFile.stream.write(buffer, maxLength: headerLength)
//            if writeLength != headerLength {
//                self.completion(false, nil)
//            }
//            
//            for iFile in self.inputFiles {
//                
//                //process next input
//                self.processingStream = InputStream(url: iFile.url)
//                if self.processingStream != nil {
//                    self.processingStream!.open()
//                    self.dumpInput(interpolate: SMAudioFileEditor.InputFile.maxSampleRate! / iFile.sampleRate!)
//                } else {
//                    self.completion(false, .fileDamaged)
//                }
//                
//                //close the last input stream
//                if self.processingStream != nil {
//                    self.processingStream!.close()
//                    self.processingStream = nil
//                }
//            }
//        
//            //edit completed
//            self.outputFile.stream.close()
//            self.setWAVEFileHeader()
//            self.completion(true, nil)
//        }
    }
    
    private func readNextInput() {
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
                RunLoop.current.run()
//                self.dumpInput(interpolate: SMAudioFileEditor.InputFile.maxSampleRate! / iFile.sampleRate!)
            } else {
                self.releaseResurce()
                self.completion(false, .fileDamaged)
            }
        } else {
            self.releaseResurce()
            completion(true, nil)
        }
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case Stream.Event.hasBytesAvailable:
            read()
        case Stream.Event.hasSpaceAvailable:
            write()
        case Stream.Event.errorOccurred:
            releaseResurce()
        case Stream.Event.endEncountered:
            readNextInput()
        default: break
        }
        
    }
    
    func read() {
        if self.processingStream != nil {
            let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputFile.fragmentLength)
            let readLength = self.processingStream!.read(tempBuffer, maxLength: InputFile.fragmentLength)
            
            readSemaphore.wait()
            fragmentData.append(tempBuffer, count: readLength)
            writeSemaphore.signal()
            
            //            if needRemoveWAVEHeader {
            //                fragmentData.removeSubrange(0..<SMAudioFileEditor.waveHeader.count)
            //                needRemoveWAVEHeader = false
            //            }
            //            if times > 1 {
            //                fragmentData = interpolate(times, into: fragmentData)
            //            }
            

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
        
    }
    
    private func dumpInput(interpolate times: Int) {
        var fragmentData = Data()
        var needRemoveWAVEHeader = true
        readLoop: while true {
            if fragmentData.isEmpty && processingStream!.hasBytesAvailable == true {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputFile.fragmentLength)
                let readLength = processingStream!.read(buffer, maxLength: InputFile.fragmentLength)
                if readLength <= 0 {
                    break readLoop
                } else if readLength == -1 {
                    completion(false, .fileDamaged)
                }
                fragmentData.append(buffer, count: readLength)
                if needRemoveWAVEHeader {
                    fragmentData.removeSubrange(0..<SMAudioFileEditor.waveHeader.count)
                    needRemoveWAVEHeader = false
                }
                if times > 1 {
                    fragmentData = interpolate(times, into: fragmentData)
                }
                
                writeLoop: while true {
                    if outputFile.stream.hasSpaceAvailable == true {
                        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: fragmentData.count)
                        fragmentData.copyBytes(to: buffer, count: fragmentData.count)
                        let writeLength = outputFile.stream.write(buffer, maxLength: fragmentData.count)
                        fragmentData.removeAll()
                        if writeLength < 0 {
                            completion(false, .fileDamaged)
                        }
                        break writeLoop
                    }
                }
            }
        }
    }
    
    private func checkAllFiles() {
        for index in 0..<inputFiles.count {
            var handle: FileHandle?
            do {
                try handle = FileHandle(forReadingFrom: inputFiles[index].url)
            } catch  {
                return
            }
            let iData = handle!.readData(ofLength: SMAudioFileEditor.waveHeader.count)
            guard iData.count == SMAudioFileEditor.waveHeader.count else {
                return
            }
            let range = SMAudioFileEditor.waveSampleRateRange
            let sampleRate = Int(iData.subData(range.first!, range.count).toInt32(isLittleEndian: true))
            guard SMRecorder.QualitySettings.low.sampleRate <= sampleRate
                && sampleRate <= SMRecorder.QualitySettings.high.sampleRate
                && sampleRate % SMRecorder.QualitySettings.low.sampleRate == 0 else {
                    return
            }
            inputFiles[index].sampleRate = sampleRate
            InputFile.maxSampleRate = max(InputFile.maxSampleRate ?? 0, sampleRate)
            
            var headerData = iData.subData(0, SMAudioFileEditor.waveHeader.count)
            headerData.replaceSubrange(SMAudioFileEditor.waveSize1Range,
                                       with: Data(repeatElement(0, count: SMAudioFileEditor.waveSize1Range.count)))
            headerData.replaceSubrange(SMAudioFileEditor.waveSampleRateRange,
                                       with: Data(repeatElement(0, count: SMAudioFileEditor.waveSampleRateRange.count)))
            headerData.replaceSubrange(SMAudioFileEditor.waveBPSRange,
                                       with: Data(repeatElement(0, count: SMAudioFileEditor.waveBPSRange.count)))
            headerData.replaceSubrange(SMAudioFileEditor.waveSize2Range,
                                       with: Data(repeatElement(0, count: SMAudioFileEditor.waveSize2Range.count)))
            if headerData != SMAudioFileEditor.waveHeader {
                return
            }
        }
    }
    
    private func setWAVEFileHeader() {
        var finalFileSize = 0
        var handle: FileHandle?
        do {
            let info = try FileManager.default.attributesOfItem(atPath: outputFile.url.path)
            finalFileSize = Int(info[FileAttributeKey.size] as! UInt64)
            try handle = FileHandle(forWritingTo: outputFile.url)
        } catch  {
            return
        }
        let size1 = finalFileSize - (SMAudioFileEditor.waveSize1Range.last! + 1)
        let sampleRate = SMAudioFileEditor.InputFile.maxSampleRate!
        let bps = sampleRate * (SMAudioFileEditor.InputFile.supportedBitWidth / 8)
        let size2 = finalFileSize - (SMAudioFileEditor.waveSize2Range.last! + 1)
        handle?.seek(toFileOffset: UInt64(SMAudioFileEditor.waveSize1Range.first!))
        handle?.write(UInt32(size1).toData())
        handle?.seek(toFileOffset: UInt64(SMAudioFileEditor.waveSampleRateRange.first!))
        handle?.write(UInt32(sampleRate).toData())
        handle?.seek(toFileOffset: UInt64(SMAudioFileEditor.waveBPSRange.first!))
        handle?.write(UInt32(bps).toData())
        handle?.seek(toFileOffset: UInt64(SMAudioFileEditor.waveSize2Range.first!))
        handle?.write(UInt32(size2).toData())
    }
    
    private func releaseResurce() {
        
    }
    
    //Currently only 16-bit PCM data is supported
    private func interpolate(_ times: Int, into fragmentData: Data) -> Data {
        var output = Data()
        fragmentData.withUnsafeBytes { (pointer: UnsafePointer<UInt8>) in
            for i in stride(from: fragmentData.startIndex, to: fragmentData.endIndex - 1, by: 2) {
                for _ in 0..<times {
                    output.append(pointer.advanced(by: i), count: 1)
                    output.append(pointer.advanced(by: i+1), count: 1)
                }
            }
        }
        return output
    }
    
}

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
    private let queue = DispatchQueue(label: "com.sunshushu.wave-merge")
    private var inputFiles: [InputFile]
    private let outputFile: OutputFile
    private var processingStream: InputStream?
    private let completion: CompletionBlock
    
    var temp = 0
    
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
        queue.async {
            
            self.checkAllFiles()
            
            //TODO: Cheak memory leaks
            
            //setup output
            self.outputFile.stream.open()
            let headerLength = SMAudioFileEditor.waveHeader.count
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: headerLength)
            SMAudioFileEditor.waveHeader.copyBytes(to: buffer, count: headerLength)
            let writeLength = self.outputFile.stream.write(buffer, maxLength: headerLength)
            if writeLength != headerLength {
                self.completion(false, nil)
            }
            
            for iFile in self.inputFiles {
                
                //process next input
                self.processingStream = InputStream(url: iFile.url)
                if self.processingStream != nil {
                    self.processingStream!.open()
                    self.dumpInput()
                } else {
                    self.completion(false, .fileDamaged)
                }
                
                //close the last input stream
                if self.processingStream != nil {
                    self.processingStream!.close()
                    self.processingStream = nil
                }
            }
            
            //edit completed
            self.outputFile.stream.close()
            self.setWAVEFileHeader()
            self.completion(true, nil)
        }
    }
    
    private func dumpInput() {
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
                interpolate()
                
                writeLoop: while true {
                    if outputFile.stream.hasSpaceAvailable == true {
                        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: fragmentData.count)
                        fragmentData.copyBytes(to: buffer, count: fragmentData.count)
                        let writeLength = outputFile.stream.write(buffer, maxLength: fragmentData.count)
                        temp += writeLength
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
        for var iFile in inputFiles {
            var handle: FileHandle?
            do {
                try handle = FileHandle(forReadingFrom: iFile.url)
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
            iFile.sampleRate = sampleRate
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
    private func interpolate() {
//        if inputFile!.sampleRate == nil {
//            if checkWAVEFile() == false {
//                completion(false, .fileDamaged)
//            }
//        }
//        
//        var output = Data()
//        for index in 0..<input.count / 2 {
//            let indexFor16 = index * 2
//            let lowByte = input[indexFor16]
//            let hightByte = input[indexFor16 + 1]
//            for _ in 0...times {
//                output.append(lowByte)
//                output.append(hightByte)
//            }
//        }
//        return output
    }
    
}

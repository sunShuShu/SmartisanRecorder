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
        static let supportedBitWidth: Int16 = 16
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
    private let queue = DispatchQueue(label: "com.sunshushu.wave-merge")
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
        queue.async {
            
            self.checkAllFiles()
            
            //TODO: Cheak memory leaks
            self.outputFile.stream.open()
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
            self.completion(true, nil)
        }
    }
    
    private func dumpInput() {
        var fragmentData = Data()
        readLoop: while true {
            if fragmentData.isEmpty && processingStream!.hasBytesAvailable == true {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputFile.fragmentLength)
                let readLength = processingStream!.read(buffer, maxLength: InputFile.fragmentLength)
                if readLength == 0 {
                    break readLoop
                } else if readLength == -1 {
                    completion(false, .fileDamaged)
                }
                fragmentData.append(buffer, count: readLength)
                interpolate()
                
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
        for var iFile in inputFiles {
            var handle: FileHandle?
            do {
                try handle = FileHandle(forReadingFrom: iFile.url)
            } catch  {
                return
            }
            let iData = handle!.readData(ofLength: 0x28)
            guard iData.count == 0x28 else {
                return
            }
            let riffData = iData.subData(0x00, 4)
            guard riffData.toString() == "RIFF" else {
                return
            }
            let fileAndFormat = iData.subData(0x08, 8)
            guard fileAndFormat.toString() == "WAVEfmt " else {
                return
            }
            let compression = iData.subData(0x14, 2)
            guard compression.toInt16(isBigEndian: false) == 1 else { //1 for PCM, WAVE data is little end
                return
            }
            let channel = iData.subData(0x16, 2)
            guard channel.toInt16(isBigEndian: false) == 1 else { //only supports mono
                return
            }
            let bitWidth = iData.subData(0x22, 2)
            guard bitWidth.toInt16(isBigEndian: false) == InputFile.supportedBitWidth else {
                return
            }
            let dataFlag = iData.subData(0x24, 4)
            guard dataFlag.toString() == "data" else {
                return
            }
            let sampleRate = Int(iData.subData(0x18, 4).toInt64(isBigEndian: false))
            guard SMRecorder.QualitySettings.low.sampleRate <= sampleRate
                && sampleRate <= SMRecorder.QualitySettings.high.sampleRate
                && sampleRate % SMRecorder.QualitySettings.low.sampleRate == 0 else {
                    return
            }
            iFile.sampleRate = sampleRate
            InputFile.maxSampleRate = max(InputFile.maxSampleRate ?? 0, sampleRate)
        }
    }
    
    private func setWAVEFileHeader() {
        
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

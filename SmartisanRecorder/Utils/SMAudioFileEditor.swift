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
        static let fragmentLength = 1024 * 1024
        static let supportedBitWidth: Int16 = 16
        let url: URL
        var sampleRate: Int?
        var fragmentData = Data()
        let stream : InputStream
        init?(url: URL) {
            self.url = url
            if let iStream = InputStream(url: url) {
                self.stream = iStream
            } else {
                return nil
            }
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
    private var inputURLs: [URL]
    private let outputFile: OutputFile
    private var inputFile: InputFile?
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
        self.inputURLs = inputURLs
        self.completion = completion
        super.init()
    }
    
    func merge() {
        //TODO: check storage
        queue.async {
            //TODO: Cheak memory leaks
            self.outputFile.stream.open()
            for iURL in self.inputURLs {
                //close the last input stream
                if self.inputFile != nil {
                    self.inputFile!.stream.close()
                    self.inputFile = nil
                }
                
                //process next input
                if let iFile = InputFile(url: iURL) {
                    self.inputFile = iFile
                    iFile.stream.open()
                    self.dumpInput()
                } else {
                    self.completion(false, .fileDamaged)
                }
            }
            
            //edit completed
            self.outputFile.stream.close()
            self.completion(true, nil)
        }
    }
    
    private func dumpInput() {
        readLoop: while true {
            if inputFile!.fragmentData.isEmpty && inputFile!.stream.hasBytesAvailable == true {
                let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputFile.fragmentLength)
                let readLength = inputFile!.stream.read(buffer, maxLength: InputFile.fragmentLength)
                if readLength == 0 {
                    break readLoop
                } else if readLength == -1 {
                    completion(false, .fileDamaged)
                }
                inputFile!.fragmentData.append(buffer, count: readLength)
                interpolate()
                
                writeLoop: while true {
                    if outputFile.stream.hasSpaceAvailable == true {
                        var oData = inputFile!.fragmentData
                        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: oData.count)
                        oData.copyBytes(to: buffer, count: oData.count)
                        let writeLength = outputFile.stream.write(buffer, maxLength: oData.count)
                        inputFile!.fragmentData.removeAll()
                        if writeLength < 0 {
                            completion(false, .fileDamaged)
                        }
                        break writeLoop
                    }
                }
            }
        }
    }
    
    private func checkWAVEFile() -> Bool {
        let iData = inputFile!.fragmentData
        let riffData = iData.subData(0x00, 4)
        guard riffData.toString() == "RIFF" else {
            return false
        }
        let fileAndFormat = iData.subData(0x08, 8)
        guard fileAndFormat.toString() == "WAVEfmt " else {
            return false
        }
        let compression = iData.subData(0x14, 2)
        guard compression.toInt16(isBigEndian: false) == 1 else { //1 for PCM, WAVE data is little end
            return false
        }
        let channel = iData.subData(0x16, 2)
        guard channel.toInt16(isBigEndian: false) == 1 else { //only supports mono
            return false
        }
        let bitWidth = iData.subData(0x22, 2)
        guard bitWidth.toInt16(isBigEndian: false) == InputFile.supportedBitWidth else {
            return false
        }
        let dataFlag = iData.subData(0x24, 4)
        guard dataFlag.toString() == "data" else {
            return false
        }
        let sampleRate = Int(iData.subData(0x18, 4).toInt64(isBigEndian: false))
        guard SMRecorder.QualitySettings.low.sampleRate <= sampleRate
            && sampleRate <= SMRecorder.QualitySettings.high.sampleRate
            && sampleRate % SMRecorder.QualitySettings.low.sampleRate == 0 else {
            return false
        }
        
        inputFile!.sampleRate = sampleRate

        return true
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

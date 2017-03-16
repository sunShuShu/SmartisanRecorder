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
//    static let trackskeys = "tracks"
//    static let durationKey = "duration"
//    
//    static func mergeWAVE(inputURLs: [URL], outputURL: URL) -> Bool {
//        guard inputURLs.count >= 2 else {
//            return false
//        }
//        
//        //Load values of asserts
//        var loadedAssert = [AVURLAsset]()
//        for url in inputURLs {
//            let assert = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
//            let semaphore = DispatchSemaphore(value: 0)
//            var loadSuccess = false
//            assert.loadValuesAsynchronously(forKeys: [trackskeys, durationKey], completionHandler: {
//                let trackStatus = assert.statusOfValue(forKey: trackskeys, error: nil)
//                let durationStatus = assert.statusOfValue(forKey: durationKey, error: nil)
//                if trackStatus == .loaded && durationStatus == .loaded {
//                    loadSuccess = true
//                }
//                semaphore.signal()
//            })
//            
//            semaphore.wait()
//
//            if loadSuccess {
//                loadedAssert.append(assert)
//            } else {
//                break
//            }
//        }
//        if loadedAssert.count != inputURLs.count {
//            print("Load values is failed")
//            return false
//        }
//        
//        //Insert tracks
//        let composition = AVMutableComposition()
//        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio,
//                                                     preferredTrackID: kCMPersistentTrackID_Invalid)
//        for assert in loadedAssert {
//            let range = CMTimeRangeMake(kCMTimeZero, assert.duration)
//            #if DEBUG
//            CMTimeRangeShow(range)
//            #endif
//            if let track = assert.tracks(withMediaType: AVMediaTypeAudio).first {
//                do {
//                    try audioTrack.insertTimeRange(range, of: track, at: composition.duration)
//                } catch {
//                    print("Insert time ranges is failed," + "\(error)")
//                    return false
//                }
//            } else {
//                print("There is not track in assert")
//                return false
//            }
//        }
//        
//        //Export
//        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) {
//            let semaphore = DispatchSemaphore(value: 0)
//            var exportSuccess = false
//            exportSession.outputURL = outputURL
//            exportSession.outputFileType = AVFileTypeWAVE
//            exportSession.exportAsynchronously(completionHandler: {
//                if exportSession.status == .completed {
//                    exportSuccess = true
//                    semaphore.signal()
//                } else {
//                    print(exportSession.error!)
//                }
//            })
//            semaphore.wait()
//            return exportSuccess
//        } else {
//            return false
//        }
//    }
    
//    private static let readLength = 1024
//    private static let supportedBitWidth: Int16 = 16
    private let queue = DispatchQueue(label: "com.sunshushu.wave-merge")
    private var inputURLs: [URL]
//    private let outputURL: URL
//    private var inputStream : InputStream?
//    private var outputStream : OutputStream?
    private let outputFile: OutputFile
//    private var tempData = Data()
//    private var tempDataSampleRate: Int64?
    private var inputFile: InputFile?
    private let completion: CompletionBlock
    
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
            self.setupStream(self.outputFile.stream)
            self.setupNextStream()
        }
    }
    
    private func setupNextStream() {
        //close the last input stream
        if inputFile != nil {
            closeStream(inputFile!.stream)
            inputFile = nil
        }
        //cheak if edit completed
        if inputURLs.isEmpty {
            closeStream(outputFile.stream)
            completion(true, nil)
        }
        //process next input
        if let iFile = InputFile(url: inputURLs.first!) {
            self.inputFile = iFile
            setupStream(iFile.stream)
            readLoop: while true {
                if inputFile!.fragmentData.isEmpty && inputFile!.stream.hasBytesAvailable == true {
                    let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputFile.fragmentLength)
                    let readLength = inputFile!.stream.read(buffer, maxLength: InputFile.fragmentLength)
                    if readLength == 0 {
                        break readLoop
                    }
                    inputFile!.fragmentData.append(buffer, count: readLength)
                    if inputFile!.sampleRate == nil {
                        if checkWAVEFile() == false {
                            completion(false, .fileDamaged)
                        }
                    }
                }
                writeLoop: while true {
                    var oData = inputFile!.fragmentData
                    if oData.isEmpty == false && outputFile.stream.hasSpaceAvailable == true {
                        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: oData.count)
                        oData.copyBytes(to: buffer, count: oData.count)
                        outputFile.stream.write(buffer, maxLength: oData.count)
                        inputFile!.fragmentData.removeAll()
                        break writeLoop
                    }
                }
            }
        } else {
            completion(false, EditError.fileDamaged)
        }
        inputURLs.removeFirst()
    }
    
    private func closeStream(_ stream: Stream) {
        stream.close()
//        stream.remove(from: RunLoop.main, forMode: .defaultRunLoopMode)
    }
    
    private func setupStream(_ stream: Stream) {
        stream.delegate = self
//        stream.schedule(in: RunLoop.main, forMode: .defaultRunLoopMode)
        stream.open()
    }
    
//    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
//        queue.async {
//            switch eventCode {
//            case Stream.Event.hasBytesAvailable:
//                self.read()
//                
////            case Stream.Event.hasSpaceAvailable:
////                self.write()
//                
//            case Stream.Event.endEncountered:
//                self.setupNextStream()
//                
//            case Stream.Event.errorOccurred:
//                print(aStream.streamError!)
//                
//            default: break
//            }
//        }
//    }
    
    private func read() {
        if inputFile!.fragmentData.isEmpty && inputFile!.stream.hasBytesAvailable == true {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: InputFile.fragmentLength)
            let readLength = inputFile!.stream.read(buffer, maxLength: InputFile.fragmentLength)
            inputFile!.fragmentData.append(buffer, count: readLength)
            if inputFile!.sampleRate == nil {
                if checkWAVEFile() == false {
                    completion(false, .fileDamaged)
                }
            }
            //TODO: times!
            if 2 > 1 {
//                inputFile!.fragmentData = SMAudioFileEditor.interpolate(input: inputFile!.fragmentData, times: 2)
            }
//            self.write()
//            if outputFile.stream.hasSpaceAvailable == true {
//                queue.async {
//                    self.write()
//                }
//            }
        }
    }
    
    private func write() {
        var oData = inputFile!.fragmentData
        if oData.isEmpty == false && outputFile.stream.hasSpaceAvailable == true {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: oData.count)
            oData.copyBytes(to: buffer, count: oData.count)
            outputFile.stream.write(buffer, maxLength: oData.count)
            inputFile!.fragmentData.removeAll()
//            if inputFile!.stream.hasBytesAvailable == true {
//                queue.async {
//                    self.read()
//
//                }
//            }
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
    
    //Currently only 16-bit PCM data is supported
    private static func interpolate(input:Data, times:Int) -> Data {
        var output = Data()
        for index in 0..<input.count / 2 {
            let indexFor16 = index * 2
            let lowByte = input[indexFor16]
            let hightByte = input[indexFor16 + 1]
            for _ in 0...times {
                output.append(lowByte)
                output.append(hightByte)
            }
        }
        return output
    }
    
}

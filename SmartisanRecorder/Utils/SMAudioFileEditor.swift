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
    
    private static let readLength = 1024
    private static let supportedBitWidth: Int16 = 16
    private var inputURLs: [URL]
    private let outputURL: URL
    private let queue = DispatchQueue(label: "com.sunshushu.wave-merge")
    private var inputStream : InputStream?
    private var outputStream : OutputStream?
    private var tempData = Data()
    private var tempDataSampleRate: Int64?
    
    init(inputURLs: [URL], outputURL: URL) {
        self.inputURLs = inputURLs
        self.outputURL = outputURL
    }
    
    private func setupStream(with url:URL) {
        queue.async {
            //TODO: Cheak memory leaks
            self.inputStream = InputStream(url: url)
            self.inputStream?.delegate = self
            self.inputStream?.schedule(in: RunLoop.current, forMode: .defaultRunLoopMode)
            self.inputStream?.open()
            RunLoop.current.run()
        }
    }
    
    func merge() {
        setupStream(with: inputURLs.first!)
    }
    
    func mergeNext() {
        guard inputURLs.isEmpty == false else {
            print("Complete!")
            return
        }
        setupStream(with: inputURLs.first!)
        inputURLs.removeFirst()
    }
    
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        print("#######################################")
        switch eventCode {
            
        case Stream.Event.hasBytesAvailable:
            read()
            
        case Stream.Event.hasSpaceAvailable:
            write()
            
        case Stream.Event.endEncountered:
            aStream.close()
            aStream.remove(from: RunLoop.current, forMode: .defaultRunLoopMode)
            
        case Stream.Event.errorOccurred:
            print(inputStream!.streamError!)
            
        default: break
        }
    }
    
    private func read() {
        if tempData.isEmpty && inputStream?.hasBytesAvailable == true {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: SMAudioFileEditor.readLength)
            let readLength = inputStream?.read(buffer, maxLength: SMAudioFileEditor.readLength)
            tempData.append(buffer, count: readLength!)
            if tempDataSampleRate == nil {
                checkWAVEFile()
            }
            tempData = SMAudioFileEditor.interpolate(input: tempData, times: 1) //TODO: times!
            if outputStream?.hasSpaceAvailable == true {
                write()
            }
        }
    }
    
    private func write() {
        if tempData.isEmpty == false && outputStream?.hasSpaceAvailable == true {
            let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: tempData.count)
            tempData.copyBytes(to: buffer, count: tempData.count)
            outputStream?.write(buffer, maxLength: tempData.count)
            tempData.removeAll()
            if inputStream?.hasBytesAvailable == true {
                read()
            }
        }
    }
    
    private func checkWAVEFile() -> Bool {
        let riffData = tempData.subData(0x00, 4)
        guard riffData.toString() == "RIFF" else {
            return false
        }
        let fileAndFormat = tempData.subData(0x08, 8)
        guard fileAndFormat.toString() == "WAVEfmt " else {
            return false
        }
        let compression = tempData.subData(0x14, 2)
        guard compression.toInt16(isBigEndian: false) == 1 else { //1 for PCM, WAVE data is little end
            return false
        }
        let channel = tempData.subData(0x16, 2)
        guard channel.toInt16(isBigEndian: false) == 1 else { //only supports mono
            return false
        }
        let bitWidth = tempData.subData(0x22, 2)
        guard bitWidth.toInt16(isBigEndian: false) == SMAudioFileEditor.supportedBitWidth else {
            return false
        }
        let dataFlag = tempData.subData(0x24, 4)
        guard dataFlag.toString() == "data" else {
            return false
        }
        
        self.tempDataSampleRate = tempData.subData(0x18, 4).toInt64(isBigEndian: false)
        print("\(self.tempDataSampleRate)")
        return true
    }
    
    private func setWAVEFileHeader() {
        
    }
    
    //Currently only 16-bit PCM data is supported
    private static func interpolate(input:Data, times:Int) -> Data {
        guard times <= 0 else {
            return input
        }
        
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

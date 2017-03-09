//
//  SMAudioFileSample.swift
//  SmartisanRecorder
//
//  Created by sunda on 09/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import AVFoundation

class SMAudioFileSampler {
    
    private static let minSampleRate = 8_000 //use allowable min value to ensure the filter speed
    private static let tracksKey = "tracks"
    
    static func sample(url: URL, countPerSecond:Int, completion:@escaping ([Int8]?) -> ()) {

        //load track async
        let asset = AVAsset(url: url)
        asset.loadValuesAsynchronously(forKeys: [SMAudioFileSampler.tracksKey]) {
            var error: NSError?
            let status = asset.statusOfValue(forKey: SMAudioFileSampler.tracksKey, error: &error)
            guard status == .loaded else {
                completion(nil)
                print("audio file sample status error")
                return
            }
            
            //start reading track data
            var assetReader: AVAssetReader?
            do {
                try assetReader = AVAssetReader(asset: asset)
            } catch {
                completion(nil)
                print("audio file sampler creat asset reader failed." + error.localizedDescription)
                return
            }
            guard let track = asset.tracks(withMediaType: AVMediaTypeAudio).first else {
                completion(nil)
                print("audio file track is nil")
                return
            }
            let outputSettings: [String:Any] = [AVFormatIDKey : kAudioFormatLinearPCM,
                                                AVSampleRateKey : minSampleRate,
                                                AVNumberOfChannelsKey : 1,
                                                AVLinearPCMIsFloatKey : false,
                                                AVLinearPCMBitDepthKey : 8] //8 bit is enough,the waveform view don't require a higher resolution
            let output = AVAssetReaderTrackOutput(track: track, outputSettings: outputSettings)
            assetReader?.add(output)
            assetReader?.startReading()
            
            //read track data
            let sampleData = NSMutableData()
            while assetReader?.status == .reading {
                if let sampleBuffer = output.copyNextSampleBuffer() {
                    if let blockBufferRef = CMSampleBufferGetDataBuffer(sampleBuffer) {
                        let dataLength = CMBlockBufferGetDataLength(blockBufferRef)
                        let sampleBytes = UnsafeMutablePointer<Int8>.allocate(capacity: dataLength)
                        CMBlockBufferCopyDataBytes(blockBufferRef,
                                                   0,
                                                   dataLength,
                                                   sampleBytes)
                        sampleData.append(sampleBytes, length: dataLength) //TODO: optimize memory,reading data while filtering
                        CMSampleBufferInvalidate(sampleBuffer)
                    }
                }
            }
            var sampleArray = [Int8](repeating:0 ,count:(sampleData as Data).count)
            sampleData.getBytes(&sampleArray, length: (sampleData as Data).count)
            
            //filter data
            if assetReader?.status == .completed {
                sampleArray = filter(sampleArray, countPerSecond: countPerSecond)
                completion(sampleArray)
            } else {
                print("asset reader status error")
                completion(nil)
            }
        }
    }
    
    static func filter(_ sampleData: [Int8], countPerSecond:Int) -> [Int8] {
        var filteredData = [Int8]()
        let sampleBinSize = minSampleRate / countPerSecond
        var byteIndex:Int = 0
        for _ in 0..<sampleData.count / sampleBinSize {
            var maxInBin:Int8 = 0
            for i in byteIndex..<(byteIndex + sampleBinSize) {
                var sample = sampleData[i]
                sample = sample == -128 ? -127 : sample
                maxInBin = max(abs(sample), maxInBin)
            }
            byteIndex += sampleBinSize
            filteredData.append(maxInBin)
        }
        return filteredData
    }
    
}

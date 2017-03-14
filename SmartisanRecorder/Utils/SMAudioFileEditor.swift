//
//  SMAudioFileEditor.swift
//  SmartisanRecorder
//
//  Created by sunda on 13/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import AVFoundation

class SMAudioFileEditor {
    static let trackskeys = "tracks"
    static let durationKey = "duration"
    
    static func mergeWAVE(inputURLs: [URL], outputURL: URL) -> Bool {
        guard inputURLs.count >= 2 else {
            return false
        }
        
        //Load values of asserts
        var loadedAssert = [AVURLAsset]()
        for url in inputURLs {
            let assert = AVURLAsset(url: url, options: [AVURLAssetPreferPreciseDurationAndTimingKey : true])
            let semaphore = DispatchSemaphore(value: 0)
            var loadSuccess = false
            assert.loadValuesAsynchronously(forKeys: [trackskeys, durationKey], completionHandler: {
                let trackStatus = assert.statusOfValue(forKey: trackskeys, error: nil)
                let durationStatus = assert.statusOfValue(forKey: durationKey, error: nil)
                if trackStatus == .loaded && durationStatus == .loaded {
                    loadSuccess = true
                }
                semaphore.signal()
            })
            
            semaphore.wait()

            if loadSuccess {
                loadedAssert.append(assert)
            } else {
                break
            }
        }
        if loadedAssert.count != inputURLs.count {
            print("Load values is failed")
            return false
        }
        
        //Insert tracks
        let composition = AVMutableComposition()
        let audioTrack = composition.addMutableTrack(withMediaType: AVMediaTypeAudio,
                                                     preferredTrackID: kCMPersistentTrackID_Invalid)
        for assert in loadedAssert {
            let range = CMTimeRangeMake(kCMTimeZero, assert.duration)
            #if DEBUG
            CMTimeRangeShow(range)
            #endif
            if let track = assert.tracks(withMediaType: AVMediaTypeAudio).first {
                do {
                    try audioTrack.insertTimeRange(range, of: track, at: composition.duration)
                } catch {
                    print("Insert time ranges is failed," + "\(error)")
                    return false
                }
            } else {
                print("There is not track in assert")
                return false
            }
        }
        
        //Export
        if let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) {
            let semaphore = DispatchSemaphore(value: 0)
            var exportSuccess = false
            exportSession.outputURL = outputURL
            exportSession.outputFileType = AVFileTypeWAVE
            exportSession.exportAsynchronously(completionHandler: {
                if exportSession.status == .completed {
                    exportSuccess = true
                    semaphore.signal()
                } else {
                    print(exportSession.error!)
                }
            })
            semaphore.wait()
            return exportSuccess
        } else {
            return false
        }
        
    }
}

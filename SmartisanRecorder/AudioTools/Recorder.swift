//
//  Recorder.swift
//  SmartisanRecorder
//
//  Created by sunda on 06/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import AVFoundation

class Recorder {
    
    static let qualityHighSampleRate = 48_000 //Hz
    static let qualityMediumSampleRate = 24_000
    static let qualityLowSampleRate = 8_000
    static let qualityDefault = QualitySettings.medium
    private static let fileNameDefaultPrefix = "Rec_"
    
    private static let kQuality = "kSoundQuality"
    private static let kDocDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/"
    
    enum QualitySettings: Int {
        case high, medium, low
        var sampleRate: Int {
            switch self {
            case .high:
                return Recorder.qualityHighSampleRate
            case .medium:
                return Recorder.qualityMediumSampleRate
            case .low:
                return Recorder.qualityLowSampleRate
            }
        }
    }
    
    static var soundQuality: QualitySettings {
        get {
            if let rawQualityData = UserDefaults.standard.value(forKey: Recorder.kQuality) {
                if rawQualityData is Int {
                    if let quality = QualitySettings(rawValue: rawQualityData as! Int) {
                        return quality
                    }
                }
            }
            let quality = Recorder.qualityDefault
            self.soundQuality = quality
            return quality
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Recorder.kQuality)
        }
    }
    
    var defaultFileName: String = {
        var finalFileName: String?
        let filePathWithoutNumber = Recorder.kDocDirectory + Recorder.fileNameDefaultPrefix
        var fileNameNumber = 0
        repeat {
            fileNameNumber += 1
            finalFileName = String(format: "%@%03d", filePathWithoutNumber, fileNameNumber)
        } while (FileManager.default.fileExists(atPath: finalFileName!))
        return String(format: "%@%03d", Recorder.fileNameDefaultPrefix, fileNameNumber)
    }()
    
    private var audioRecorder: AVAudioRecorder?
    
    init() {
        let urlPath = NSTemporaryDirectory() + defaultFileName
        let settings: [String : Any] = [AVFormatIDKey : kAudioFormatLinearPCM,
                                        AVSampleRateKey : Recorder.soundQuality.sampleRate,
                                        AVNumberOfChannelsKey : 1,
                                        AVLinearPCMBitDepthKey : 16,] //TODO:Set bit depth by quality
        do {
            try audioRecorder = AVAudioRecorder(url: URL(fileURLWithPath: urlPath), settings:settings)
        } catch {
            print("Creat AVAudioRecorder fail!") //TODO:Delete catch before release,It will never execute if URL and settings are rigth
        }
        if audioRecorder != nil {
            audioRecorder?.prepareToRecord()
        } else {
            audioRecorder = nil
        }
    }
    
    func start() {
        //TODO:Check the mic access
    }
    
    func pause() {
        
    }
    
    func stop() {
        
    }
    
    func save() {
        //TODO:Check the file name if exist
    }

}

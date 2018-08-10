//
//  Recorder.swift
//  SmartisanRecorder
//
//  Created by sunda on 06/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import AVFoundation

class SMRecorder: NSObject, AVAudioRecorderDelegate {
    static let filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    static let bitDepth = 2 * BYTE_SIZE
    /// Time of electrical level update per second.
    static let levelsPerSecond = 50
    static let qualityHighSampleRate = 48_000 //Hz
    static let qualityMediumSampleRate = 24_000
    static let qualityLowSampleRate = 8_000
    static let fileSuffix = ".wav"
    
    private static let qualityDefault = QualitySettings.medium
    private static let fileNameDefaultFormat = "Rec_%03d" + SMRecorder.fileSuffix //like Rec_012.wav
    private static let kQuality = "kSoundQuality"
    
    private var audioRecorder: AVAudioRecorder?
    override init() {
        super.init()
        let urlPath = SMRecorder.filePath + "/\(defaultFileName)"
        let settings: [String : Any] = [AVFormatIDKey : kAudioFormatLinearPCM,
                                        AVSampleRateKey : SMRecorder.soundQuality.sampleRate,
                                        AVNumberOfChannelsKey : 1,
                                        AVLinearPCMBitDepthKey : SMRecorder.bitDepth]
        do {
            try audioRecorder = AVAudioRecorder(url: URL(fileURLWithPath: urlPath), settings:settings)
        } catch {
            print(error) //TODO:Delete catch before release,It will never execute if URL and settings are rigth
            assert(false)
        }
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.prepareToRecord()
    }
    
    //MARK:- Settings and status
    enum QualitySettings: Int {
        case high, medium, low
        var sampleRate: Int {
            switch self {
            case .high:
                return SMRecorder.qualityHighSampleRate
            case .medium:
                return SMRecorder.qualityMediumSampleRate
            case .low:
                return SMRecorder.qualityLowSampleRate
            }
        }
    }
    
    static var soundQuality: QualitySettings {
        get {
            if let rawQualityData = UserDefaults.standard.value(forKey: SMRecorder.kQuality) {
                if rawQualityData is Int {
                    if let quality = QualitySettings(rawValue: rawQualityData as! Int) {
                        return quality
                    }
                }
            }
            let quality = SMRecorder.qualityDefault
            self.soundQuality = quality
            return quality
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: SMRecorder.kQuality)
        }
    }
    
    let defaultFileName: String = {
        var fileNameNumber = 0
        var tempPath: String?
        repeat {
            fileNameNumber += 1
            tempPath = SMRecorder.filePath + "/" + String(format: SMRecorder.fileNameDefaultFormat, fileNameNumber)
        } while (FileManager.default.fileExists(atPath: tempPath!))
        return String(format: SMRecorder.fileNameDefaultFormat, fileNameNumber)
    }()
    
    var currentTime: TimeInterval {
        guard audioRecorder != nil else {
            return 0
        }
        return audioRecorder!.currentTime
    }
    
    var powerLevel: Float {
        guard audioRecorder != nil else {
            return 0 //Device returning value of -160 dB indicates minimum power
        }
        audioRecorder!.updateMeters()
        let power = audioRecorder!.averagePower(forChannel: 0)
        let amp = powf(10.0, 0.05 * power)
        return amp
    }
    
    //MARK:- Record control
    
    /// Start record
    ///
    /// - Returns: return true if permission granted
    @discardableResult func record() -> Bool {
        guard AVAudioSession().recordPermission() == .granted else {
            return false
        }
        audioRecorder?.record()
        return true
    }
    
    func pause() {
        audioRecorder?.pause()
    }

    func save(with name:String, completion block: @escaping (Bool)->()) -> Bool {
        
        pause()
        
        guard name.isEmpty == false else {
            return false
        }
        let fileNameWithSuffix = name + SMRecorder.fileSuffix
        let fileExist = fileNameWithSuffix != defaultFileName && FileManager.default.fileExists(atPath: SMRecorder.filePath + "/" + fileNameWithSuffix)
        guard fileExist == false else {
            return false
        }
        
        finalFileName = fileNameWithSuffix
        saveCompletionBlock = block
        audioRecorder?.stop()
        return true
    }
    
    private var finalFileName = ""
    private var saveCompletionBlock: ((Bool)->())?
    
    //MARK:- Delegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag == true {
            let defaultFilePath = SMRecorder.filePath + "/" + defaultFileName
            let finalFilePath = SMRecorder.filePath + "/" + finalFileName
            if defaultFilePath == finalFilePath {
                saveCompletionBlock?(true)
            } else {
                do {
                    try FileManager.default.moveItem(atPath: defaultFilePath, toPath: finalFilePath)
                } catch {
                    SMLog("FileManager move item fail!", error: error as NSError, level: .fatal)
                    assert(false)
                    saveCompletionBlock?(false)
                }
                saveCompletionBlock?(true)
            }
        } else {
            assert(false)
            saveCompletionBlock?(false)
        }
    }
}

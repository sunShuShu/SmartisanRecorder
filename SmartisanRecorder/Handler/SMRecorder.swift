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
    
    static let qualityHighSampleRate = 48_000 //Hz
    static let qualityMediumSampleRate = 24_000
    static let qualityLowSampleRate = 8_000
    static let qualityDefault = QualitySettings.medium
    private static let fileNameDefaultPrefix = "Rec_"
    private static let fileNameDefaultFormat = "%@%03d" //like Rec_012
    private static let kQuality = "kSoundQuality"
    private static let docDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/"
    
    private var audioRecorder: AVAudioRecorder?
    override init() {
        super.init()
        let urlPath = NSTemporaryDirectory() + defaultFileName
        let settings: [String : Any] = [AVFormatIDKey : kAudioFormatLinearPCM,
                                        AVSampleRateKey : SMRecorder.soundQuality.sampleRate,
                                        AVNumberOfChannelsKey : 1,
                                        AVLinearPCMBitDepthKey : 16,] //TODO:Set bit depth by quality
        do {
            try audioRecorder = AVAudioRecorder(url: URL(fileURLWithPath: urlPath), settings:settings)
        } catch {
            print(error) //TODO:Delete catch before release,It will never execute if URL and settings are rigth
        }
        if audioRecorder != nil {
            audioRecorder?.delegate = self
            audioRecorder?.prepareToRecord()
        } else {
            audioRecorder = nil
        }
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
        var finalFileName: String?
        let filePathWithoutNumber = SMRecorder.docDirectory + SMRecorder.fileNameDefaultPrefix
        var fileNameNumber = 0
        repeat {
            fileNameNumber += 1
            finalFileName = String(format: SMRecorder.fileNameDefaultFormat, filePathWithoutNumber, fileNameNumber)
        } while (FileManager.default.fileExists(atPath: finalFileName!))
        return String(format: SMRecorder.fileNameDefaultFormat, SMRecorder.fileNameDefaultPrefix, fileNameNumber)
    }()
    
    var currentTime: TimeInterval {
        guard audioRecorder != nil else {
            return 0
        }
        return audioRecorder!.currentTime
    }
    
    var powerLevel: Double {
        guard audioRecorder != nil else {
            return 0
        }
        audioRecorder!.updateMeters()
        return Double(audioRecorder!.averagePower(forChannel: 0))
    }
    
    //MARK:- Record control
    func start() {
        guard AVAudioSession().recordPermission() == .granted else {
            return
        }
        audioRecorder?.record()
    }
    
    func pause() {
        audioRecorder?.pause()
    }

    func save(with name:String, complete block: @escaping (Bool)->()) -> Bool {
        guard name.isEmpty == false && FileManager.default.fileExists(atPath: SMRecorder.docDirectory + name) == false else {
            return false
        }
        audioRecorder?.stop()
        finalFileName = name
        saveCompleteBlock = block
        return true
    }
    
    private var finalFileName: String?
    private var saveCompleteBlock: ((Bool)->())?
    
    //MARK:- Delegate
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        guard finalFileName != nil else {
            return
        }
        if flag == true {
            let fromPath = SMRecorder.docDirectory + defaultFileName
            let toPath = NSTemporaryDirectory() + finalFileName!
            do {
                try FileManager.default.copyItem(atPath: fromPath, toPath: toPath)
            } catch {
                print(error)
                saveCompleteBlock?(false)
            }
            saveCompleteBlock?(true)
        } else {
            print("Record save faile!")
            saveCompleteBlock?(false)
        }
    }

}

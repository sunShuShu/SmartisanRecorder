////
////  SMWaveformViewTestVC.swift
////  SmartisanRecorder
////
////  Created by sunda on 2018/1/5.
////  Copyright © 2018年 sunShuShu. All rights reserved.
////
//
//import Foundation
//import UIKit
//
class SMAudioTimer {
    private var startDate: Date?
    private var lastPlayedTime: TimeInterval = 0

    var duration: TimeInterval {
        guard startDate != nil else {
            return 0
        }
        return -(startDate!.timeIntervalSinceNow)
    }

    func start() {
        if startDate == nil {
            startDate = Date()
        } else {
            startDate = Date(timeIntervalSinceNow: -lastPlayedTime)
        }
    }

    func pause() {
        if let startDate = self.startDate {
            lastPlayedTime = Date().timeIntervalSinceNow - startDate.timeIntervalSinceNow
        }
    }

    func stop() {
        startDate = nil
        lastPlayedTime = 0
    }
}
//
////MARK:-
//
class SMWaveformViewTestViewController: SMBaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var array = Array<UInt8>()
        for index in 0..<72 * 3600 * Int(50) {
            array.append(UInt8(index % Int(SMWaveformView.maxPowerLevel)))
            let docDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last
            let data = Data(bytes: array)
            FileManager.default.createFile(atPath: docDir! + "/maximum.waveform", contents: data, attributes: nil)
        }
    }
}
//    @IBOutlet weak var waveformView: SMWaveformView!
//    @IBOutlet weak var shortWaveformView: SMWaveformView!
//
//    private static let dataCountPerSecond: Int = 50
//
//    private var powerLevel: NSMutableArray = {
//        var array = NSMutableArray()
//        for index in 0..<72 * 3600 * Int(SMWaveformViewTestViewController.dataCountPerSecond) {
//            array.add(UInt8(index % Int(SMWaveformView.maxPowerLevel)) as NSValue)
//        }
//        return array
//    }()
//    private lazy var audioDuration: TimeInterval = {
//        let duration = CGFloat(self.powerLevel.count) / CGFloat(SMWaveformViewTestViewController.dataCountPerSecond)
//        return Double(duration)
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//    }
//
//    private var updatePowerLevelTimer: DispatchSourceTimer?
//    private lazy var timer = SMAudioTimer()
//
//    private var recorder = SMRecorder()
//    private var levelData = SMWaveformModel()
//    @IBAction func recordAction(_ sender: UIButton) {
//        sender.isSelected = !sender.isSelected
//        if sender.isSelected {
//            recorder.record()
//            waveformView.powerLevelData = levelData
//            if updatePowerLevelTimer == nil {
//                updatePowerLevelTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos: .userInteractive))
//                updatePowerLevelTimer?.setEventHandler {
//                    [weak self] in
//                    if let strongSelf = self {
//                        var level = UInt8(CGFloat(strongSelf.recorder.powerLevel) * (SMWaveformView.maxPowerLevel - 10))
//                        level += 10
//                        strongSelf.levelData.add(level)
//                    }
//                }
//                updatePowerLevelTimer?.resume()
//            }
//            waveformView.updatePlayedTime = {
//                [weak self] in
//                if self != nil {
//                    let currentTime = CGFloat(self!.timer.duration)
//                    return currentTime
//                } else {
//                    return 0
//                }
//            }
//            waveformView.dataCountPerSecond = SMWaveformViewTestViewController.dataCountPerSecond
//            updatePowerLevelTimer?.schedule(deadline: .now(), repeating: 1/Double(SMWaveformViewTestViewController.dataCountPerSecond))
//            timer.start()
//        } else {
//            updatePowerLevelTimer?.schedule(wallDeadline: .distantFuture)
//            timer.pause()
//        }
//        waveformView.scrollOptimizeSettings = (true, true)
//        waveformView?.isDynamic = sender.isSelected
//    }
//
//    @IBAction func stopAction(_ sender: UIButton) {
//        updatePowerLevelTimer?.cancel()
//        updatePowerLevelTimer = nil
//        isTestingPlay = false
//        timer.stop()
//        waveformView.updatePlayedTime = nil
//        waveformView.isDynamic = false
//        waveformView.refreshView()
//    }
//
//    private var isTestingPlay = false
//    @IBAction func playAction(_ sender: UIButton) {
//        sender.isSelected = !sender.isSelected
//        if sender.isSelected && isTestingPlay == false {
//            isTestingPlay = true
//            waveformView.powerLevelData = SMWaveformModel()
//            waveformView.powerLevelData.set(powerLevel)
//            timer.start()
//            waveformView.updatePlayedTime = {
//                [weak self] in
//                if let strongSelf = self {
//                    return CGFloat(strongSelf.timer.duration)
//                } else {
//                    return 0
//                }
//            }
//            waveformView.audioDuration = CGFloat(audioDuration)
//        } else {
////            self.timer.pause()
//        }
//        waveformView.scrollOptimizeSettings = (true, false)
//        waveformView.isDynamic = sender.isSelected
//    }
//
//    @IBOutlet weak var speedLabel: UILabel!
//    private var speedFactor: CGFloat = 1
//    @IBAction func speedAction(_ sender: Any) {
//        guard isTestingPlay else {
//            return
//        }
//
//        speedFactor = CGFloat(arc4random() % 20) / 10
//        speedLabel.text = "\(speedFactor)"
//        waveformView.updatePlayedTime = {
//            [weak self] in
//            if self != nil {
//                let currentTime = CGFloat(self!.timer.duration) * self!.speedFactor
//                return currentTime
//            } else {
//                return 0
//            }
//        }
//    }
//
//    @IBAction func zoomAction(_ sender: Any) {
//        if waveformView.displayTimeRange == nil {
//            waveformView.powerLevelData = SMWaveformModel()
//            waveformView.powerLevelData.set(powerLevel)
//            waveformView.audioDuration = CGFloat(self.audioDuration)
//        }
//        let start = CGFloat(arc4random() % 10000) / 100
//        let end = CGFloat(arc4random() % 10000) / 100
//        waveformView?.displayTimeRange = (min(start, end), max(start, end))
//
//    }
//
//    @IBAction func compressionAction(_ sender: Any) {
//        if shortWaveformView.displayTimeRange == nil {
//            shortWaveformView.powerLevelData = SMWaveformModel()
//            shortWaveformView.powerLevelData.set(self.powerLevel)
//            shortWaveformView.audioDuration = CGFloat(self.audioDuration)
//        }
//        shortWaveformView?.displayTimeRange = (0, CGFloat(audioDuration))
//    }
//
//    @IBAction func lineWidthAction(_ sender: Any) {
//        waveformView.lineWidth = CGFloat(arc4random() % 50) / 10
//    }
//
//}


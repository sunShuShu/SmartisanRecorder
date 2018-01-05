//
//  SMWaveformViewTestVC.swift
//  SmartisanRecorder
//
//  Created by sunda on 2018/1/5.
//  Copyright © 2018年 sunShuShu. All rights reserved.
//

import Foundation
import UIKit

class SMWaveformViewTestViewController: SMBaseViewController {
    @IBOutlet weak var waveformView: SMWaveformView!
    @IBOutlet weak var shortWaveformView: SMWaveformView!
    
    private lazy var powerLevel: [UInt8] = {
        var array = [UInt8]()
        for index in 0..<72 * 3600 * 50 {
            array.append(UInt8(index % Int(SMWaveformView.maxPowerLevel)))
        }
        return array
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        updatePowerLevelTimer?.cancel()
        SMLog("\(type(of: self)) RELEASE!")
    }
    
    @IBAction func action(_ sender: UIButton) {
        if true {
            //test dynamic
            
        } else {
            //test static
            let start = CGFloat(arc4random() % 10_000) / 100
            let end = CGFloat(arc4random() % 10_000) / 100
            waveformView?.displayTimeRange = (min(start, end), max(start, end))
        }
    }
    
    private var updatePowerLevelTimer: DispatchSourceTimer?
    private var dataCountPerSecond = 50
    private var startDate: Date?
    private var lastPlayedTime: TimeInterval = 0
    @IBAction func recordAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            if updatePowerLevelTimer == nil {
                updatePowerLevelTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos: .userInteractive))
                updatePowerLevelTimer?.setEventHandler {
                    [weak self] in
                    usleep(SDhawn710
                        000) //simulate update power level
                    self?.waveformView?.addPowerLevel(UInt8(arc4random() % UInt32(SMWaveformView.maxPowerLevel)))
                }
                updatePowerLevelTimer?.resume()
            }
            if startDate == nil {
                startDate = Date()
            } else {
                startDate = Date(timeIntervalSinceNow: -lastPlayedTime)
            }
            waveformView.updatePlayedTime = {
                [weak self] in
                if self != nil {
                    let currentTime = CGFloat(-(self!.startDate!.timeIntervalSinceNow))
                    return currentTime
                } else {
                    return 0
                }
            }
            waveformView.dataCountPerSecond = 50
            updatePowerLevelTimer?.schedule(deadline: .now(), repeating: 1/50.0)
        } else {
            updatePowerLevelTimer?.schedule(wallDeadline: .distantFuture)
            lastPlayedTime = Date().timeIntervalSinceNow - startDate!.timeIntervalSinceNow
        }
        
        waveformView?.isDynamic = sender.isSelected
    }
    
    
    @IBAction func speedAction(_ sender: Any) {
        waveformView.updatePlayedTime = {
            [weak self] in
            let factor = Double(arc4random() % 20) / 10
            if self != nil {
                let currentTime = CGFloat(-(self?.startDate?.timeIntervalSinceNow)! * factor)
                return currentTime
            } else {
                return 0
            }
        }
    }
    
    
    @IBAction func playAction(_ sender: Any) {
    }
    
    @IBAction func zoomAction(_ sender: Any) {
    }
    
    @IBAction func compressionAction(_ sender: Any) {
    }
    
    @IBAction func lineWidthAction(_ sender: Any) {
    }
    
    @IBAction func rateAction(_ sender: Any) {
    }
    
}

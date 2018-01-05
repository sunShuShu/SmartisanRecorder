//
//  SMMainPageViewController.swift
//  SmartisanRecorder
//
//  Created by sunda on 07/03/2017.
//  Copyright © 2017 sunShuShu. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class SMMainPageViewController: SMBaseViewController {
    private var recoder = SMRecorder()
    @IBOutlet weak var waveformView: SMWaveformView?
    let audioMeter = SMAudioMeter(resultRange: 200)
    private let updatePowerLevelTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos: .userInteractive))
    
    var fireTimes = 0
    var powerLevel = [UInt8]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        waveformView?.lineWidth = 1
        self.waveformView?.dataCountPerSecond = 50
        
        if waveformView != nil {
            updatePowerLevelTimer.setEventHandler {
                [weak self] in
                let startTime = NSDate()
                
                let level = self?.recoder.powerLevel
                self?.powerLevel.append(UInt8(level!*255))
                self?.waveformView?.addPowerLevel(UInt8(level!*255))
                
                let missFire = startTime.timeIntervalSinceNow / (1/50)
                if missFire >= 1 {
                    //Insert fake data
                    assert(false)
                }
            }
            updatePowerLevelTimer.resume()
        }
        
        var levelArray = [UInt8]()
        for index in 0..<12_000_000 {
            levelArray.append(UInt8(index % 200))
        }
        self.powerLevel = levelArray
//        waveformView?.audioDuration = 100
    }
    
    deinit {
        updatePowerLevelTimer.cancel()
        SMLog("\(type(of: self)) RELEASE!")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        measure.getReport()
    }
    
    @IBAction func action(_ sender: UIButton) {
        if true {
            //test dynamic
            self.recoder.record()
            waveformView?.audioDuration = 0.0000000000001
            waveformView?.updatePlayedTime = {
                //////////////
                [weak self] in
                if self != nil {
                    let currentTime = CGFloat(self!.recoder.currentTime)
                    return currentTime
                } else {
                    return 0
                }
                //////////////
            }
            waveformView?.isDynamic = !sender.isSelected
            (waveformView?.isDynamic)! ? updatePowerLevelTimer.schedule(deadline: .now(), repeating: 1/50.0) : updatePowerLevelTimer.schedule(wallDeadline: .distantFuture)
            sender.isSelected = !sender.isSelected
        } else {
            //test static
            let start = CGFloat(arc4random() % 10_000) / 100
            let end = CGFloat(arc4random() % 10_000) / 100
            waveformView?.displayTimeRange = (min(start, end), max(start, end))
        }
    }
    
    private func checkPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { (hasPermission) in
            if hasPermission == false {
                var canOpenSettings = false
                let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
                if settingsURL != nil {
                    canOpenSettings = UIApplication.shared.canOpenURL(settingsURL!)
                }
                
                let alert = UIAlertController(title: nil, message: SMLocalize.string(.micPermission), preferredStyle: .alert)
                if canOpenSettings {
                    let goToAction = UIAlertAction(title: SMLocalize.string(.goToSetPersion), style: .default, handler: { (action) in
                        //Go to Settrings
                        UIApplication.shared.openURL(settingsURL!)
                    })
                    let cancelAction = UIAlertAction(title: SMLocalize.string(.cancel), style: .cancel, handler: nil)
                    alert.addAction(goToAction)
                    alert.addAction(cancelAction)
                    
                } else {
                    let okAction = UIAlertAction(title: SMLocalize.string(.ok), style: .default, handler: nil)
                    alert.addAction(okAction)
                }
                
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}

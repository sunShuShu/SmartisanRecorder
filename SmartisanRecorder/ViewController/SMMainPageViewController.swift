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

class SMMainPageViewController: UIViewController {
    private var recoder = SMRecorder()
    @IBOutlet weak var waveformView: SMWaveformView?
    let audioMeter = SMAudioMeter(resultRange: 200)
    private let updatePowerLevelTimer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.global(qos: .userInitiated))
    
    var fireTimes = 0
    var nowTime = Date(timeIntervalSinceNow: 0)
    override func viewDidLoad() {
        super.viewDidLoad()

        waveformView?.lineWidth = 1
        
        if waveformView != nil {
            updatePowerLevelTimer.setEventHandler {
                [weak self] in
                let level = self?.recoder.powerLevel
                self?.waveformView?.powerLevelArray.append(UInt8(level!*255))
            }
            updatePowerLevelTimer.resume()
        }
        
        for index in 0..<5000 {
            waveformView?.powerLevelArray.append(UInt8(index % 200))
        }
//        waveformView?.audioDuration = 100
    }
    
    deinit {
        updatePowerLevelTimer.cancel()
        SMLog("\(type(of: self)) RELEASE!")
    }
    
    @IBAction func action(_ sender: UIButton) {
        if true {
            //test dynamic
            self.recoder.record()
            waveformView?.audioDuration = 0.0000000000001
            waveformView?.updatePlayedTime = {
                [weak self] in
                if self != nil {
                    let currentTime = CGFloat(self!.recoder.currentTime)
                    self?.waveformView?.audioDuration = CGFloat(self!.waveformView!.powerLevelArray.count) / 50.0
                    return currentTime
                } else {
                    return 0
                }
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

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
    @IBOutlet weak var waveformView: SMWaveformView!
    let audioMeter = SMAudioMeter(resultRange: 200)
    let timer = DispatchSource.makeTimerSource(flags: [], queue: DispatchQueue.main)
    var lastTime = NSDate().timeIntervalSince1970
    
    private var dispatchLink: CADisplayLink?
    
    @objc func wf() {
        var waveformArray = waveformView.powerLevel
        let firstValue = waveformArray.removeFirst()
        waveformArray.append(firstValue)
        self.waveformView.powerLevel = waveformArray
    }
    override func viewDidLoad() {
        super.viewDidLoad()
//        dispatchLink = CADisplayLink(target: self, selector: #selector(wf))
//        dispatchLink!.add(to: RunLoop.main, forMode: .commonModes)
//        dispatchLink?.isPaused = true
        
        var waveformArray = [UInt8]()
        for index in 0..<255 {
            waveformArray.append(UInt8(index))
        }
        timer.schedule(deadline: .now(), repeating: 1/60.0)
        timer.setEventHandler {
            self.wf()
        }
        timer.resume()
    }
    
    @IBAction func action(_ sender: UIButton) {
        var waveformArray = [UInt8]()
        for index in 0..<255 {
            waveformArray.append(UInt8(index))
        }
//        self.waveformView.powerLevel = waveformArray
//        dispatchLink!.isPaused = sender.isSelected
        sender.isSelected = !sender.isSelected
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

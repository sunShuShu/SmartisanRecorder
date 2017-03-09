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
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    private var recoder = SMRecorder()
    let waveformView = SMWaveformView()
    let audioMeter = SMAudioMeter(resultRange: 200)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        recoder.record()
//        Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(timerFire), userInfo: nil, repeats: true)
//        waveformView.backgroundColor = UIColor.gray
//        waveformView.frame = CGRect(x: 0, y: 0, width: 1000, height: 300)
//        scrollView.addSubview(waveformView)
//        scrollView.contentSize = waveformView.bounds.size
//        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 10) {
//            self.recoder.save(with: "Rec_006", completion: { (result) in
//                print(result)
//            })
//        }

    }
    
    @objc private func timerFire() {
//        let db = recoder.powerLevel
//        let amp = audioMeter.linearLevel(with: db)
//        waveformView.powerLevel.append(CGFloat(amp))
//        waveformView.powerLevel = waveformView.powerLevel
        
        waveformView.powerLevel.append(CGFloat(arc4random() % 200))
        waveformView.powerLevel = waveformView.powerLevel
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
